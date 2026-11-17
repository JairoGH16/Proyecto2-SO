CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c11
LDFLAGS = -pthread -lrt
TARGET = ipc_collector

all: $(TARGET)

$(TARGET): ipc_collector.c
	$(CC) $(CFLAGS) -o $(TARGET) ipc_collector.c $(LDFLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean