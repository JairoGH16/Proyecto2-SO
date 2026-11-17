#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <semaphore.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <time.h>

#define SHM_NAME "/arenalos_ipc_telemetry"
#define RING_CAPACITY 16

typedef struct {
    int event_id;
    double load_1m;
    long mem_avail_kb;
} TelemetryPacket;

typedef struct {
    sem_t mutex;
    int head;
    int total_processed;
    double load_accumulator;
    TelemetryPacket ring[RING_CAPACITY];
} SharedTelemetry;

static volatile sig_atomic_t g_stop_requested = 0;
static volatile sig_atomic_t g_reaped_children = 0;

static void handle_sigterm(int sig) {
    (void)sig;
    g_stop_requested = 1;
}

static void handle_sigchld(int sig) {
    (void)sig;
    int saved_errno = errno;
    while (waitpid(-1, NULL, WNOHANG) > 0) {
        g_reaped_children++;
    }
    errno = saved_errno;
}

static void setup_signals(void) {
    struct sigaction sa_term;
    memset(&sa_term, 0, sizeof(sa_term));
    sa_term.sa_handler = handle_sigterm;
    sigemptyset(&sa_term.sa_mask);
    sa_term.sa_flags = 0;
    if (sigaction(SIGTERM, &sa_term, NULL) == -1 ||
        sigaction(SIGINT, &sa_term, NULL) == -1) {
        perror("sigaction SIGTERM/SIGINT");
        exit(EXIT_FAILURE);
    }

    struct sigaction sa_chld;
    memset(&sa_chld, 0, sizeof(sa_chld));
    sa_chld.sa_handler = handle_sigchld;
    sigemptyset(&sa_chld.sa_mask);
    sa_chld.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    if (sigaction(SIGCHLD, &sa_chld, NULL) == -1) {
        perror("sigaction SIGCHLD");
        exit(EXIT_FAILURE);
    }
}

static void read_system_sample(double *load_1m, long *mem_avail_kb) {
    *load_1m = 0.0;
    *mem_avail_kb = 0;

    FILE *fload = fopen("/proc/loadavg", "r");
    if (fload) {
        if (fscanf(fload, "%lf", load_1m) != 1) {
            *load_1m = 0.0;
        }
        fclose(fload);
    }

    FILE *fmem = fopen("/proc/meminfo", "r");
    if (fmem) {
        char key[64];
        long val = 0;
        char unit[16];
        while (fscanf(fmem, "%63s %ld %15s", key, &val, unit) == 3) {
            if (strcmp(key, "MemAvailable:") == 0) {
                *mem_avail_kb = val;
                break;
            }
        }
        fclose(fmem);
    }
}

static ssize_t read_packet(int fd, TelemetryPacket *pkt) {
    size_t total = 0;
    char *buf = (char *)pkt;
    while (total < sizeof(TelemetryPacket)) {
        ssize_t n = read(fd, buf + total, sizeof(TelemetryPacket) - total);
        if (n == 0) {
            return 0;
        }
        if (n < 0) {
            if (errno == EINTR) {
                if (g_stop_requested) return 0;
                continue;
            }
            return -1;
        }
        total += (size_t)n;
    }
    return (ssize_t)total;
}

static void consumer_loop(int worker_id, int read_fd, SharedTelemetry *shm, int use_sync) {
    (void)worker_id;
    TelemetryPacket pkt;

    while (!g_stop_requested) {
        ssize_t r = read_packet(read_fd, &pkt);
        if (r <= 0) {
            break;
        }

        if (use_sync) {
            while (sem_wait(&shm->mutex) == -1) {
                if (errno != EINTR) {
                    perror("sem_wait");
                    exit(EXIT_FAILURE);
                }
            }
        }

        /* Seccion critica: escritura en buffer circular y actualizacion de contadores */
        int current_count = shm->total_processed;
        int idx = shm->head;
        shm->ring[idx] = pkt;
        if (!use_sync) {
            sched_yield(); /* Fuerza intercalacion para evidenciar condicion de carrera */
        }
        shm->head = (idx + 1) % RING_CAPACITY;
        shm->total_processed = current_count + 1;
        shm->load_accumulator += pkt.load_1m;

        if (use_sync) {
            if (sem_post(&shm->mutex) == -1) {
                perror("sem_post");
                exit(EXIT_FAILURE);
            }
        }
    }

    close(read_fd);
    munmap(shm, sizeof(SharedTelemetry));
    _exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[]) {
    int num_workers = 4;
    int num_events = 2000;
    int use_sync = 1;
    int delay_us = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--no-sync") == 0) {
            use_sync = 0;
        } else if (strcmp(argv[i], "--events") == 0 && i + 1 < argc) {
            num_events = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--workers") == 0 && i + 1 < argc) {
            num_workers = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--delay-us") == 0 && i + 1 < argc) {
            delay_us = atoi(argv[++i]);
        } else {
            fprintf(stderr, "Uso: %s [--no-sync] [--events N] [--workers W] [--delay-us US]\n", argv[0]);
            return EXIT_FAILURE;
        }
    }

    setup_signals();
    shm_unlink(SHM_NAME);

    int shm_fd = shm_open(SHM_NAME, O_CREAT | O_EXCL | O_RDWR, 0600);
    if (shm_fd == -1) {
        perror("shm_open");
        return EXIT_FAILURE;
    }
    if (ftruncate(shm_fd, sizeof(SharedTelemetry)) == -1) {
        perror("ftruncate");
        shm_unlink(SHM_NAME);
        return EXIT_FAILURE;
    }

    SharedTelemetry *shm = mmap(NULL, sizeof(SharedTelemetry),
                                PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    close(shm_fd);
    if (shm == MAP_FAILED) {
        perror("mmap");
        shm_unlink(SHM_NAME);
        return EXIT_FAILURE;
    }
    memset(shm, 0, sizeof(SharedTelemetry));

    if (sem_init(&shm->mutex, 1, 1) == -1) {
        perror("sem_init");
        munmap(shm, sizeof(SharedTelemetry));
        shm_unlink(SHM_NAME);
        return EXIT_FAILURE;
    }

    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe");
        sem_destroy(&shm->mutex);
        munmap(shm, sizeof(SharedTelemetry));
        shm_unlink(SHM_NAME);
        return EXIT_FAILURE;
    }

    printf("[Productor PID=%d] Iniciando %d consumidores | Eventos=%d | Sincronizacion=%s\n",
           getpid(), num_workers, num_events, use_sync ? "ACTIVA (sem_t)" : "DESACTIVADA (--no-sync)");

    for (int w = 0; w < num_workers; w++) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            break;
        }
        if (pid == 0) {
            close(pipefd[1]);
            consumer_loop(w, pipefd[0], shm, use_sync);
        }
    }

    close(pipefd[0]);

    double sample_load = 0.0;
    long sample_mem = 0;
    read_system_sample(&sample_load, &sample_mem);

    int sent = 0;
    for (int e = 1; e <= num_events && !g_stop_requested; e++) {
        if (e % 250 == 0) {
            read_system_sample(&sample_load, &sample_mem);
        }
        TelemetryPacket pkt = {
            .event_id = e,
            .load_1m = sample_load,
            .mem_avail_kb = sample_mem
        };
        ssize_t w = write(pipefd[1], &pkt, sizeof(pkt));
        if (w == -1) {
            if (errno == EINTR) continue;
            perror("write pipe");
            break;
        }
        sent++;
        if (delay_us > 0) {
            struct timespec ts = {
            .tv_sec = delay_us / 1000000,
            .tv_nsec = (delay_us % 1000000) * 1000L
            };
            nanosleep(&ts, NULL);
        }
    }

    close(pipefd[1]);

    /* Esperar a que SIGCHLD o waitpid recolecte a todos los hijos */
    while (waitpid(-1, NULL, 0) > 0) {
        g_reaped_children++;
    }

    printf("[Resultado] Enviados=%d | Registrados en SHM=%d | Perdidos=%d | Hijos recolectados=%d\n",
           sent, shm->total_processed, sent - shm->total_processed, (int)g_reaped_children);
    if (shm->total_processed > 0) {
        printf("[Telemetria] Carga promedio 1m=%.2f | Ultima MemAvailable=%ld kB\n",
               shm->load_accumulator / shm->total_processed,
               shm->ring[(shm->head + RING_CAPACITY - 1) % RING_CAPACITY].mem_avail_kb);
    }

    sem_destroy(&shm->mutex);
    munmap(shm, sizeof(SharedTelemetry));
    shm_unlink(SHM_NAME);
    return EXIT_SUCCESS;
}