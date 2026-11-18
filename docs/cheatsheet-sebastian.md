### Sebastián

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| `Super + B` | Abre una terminal con `arranque-info` | Ver cómo arrancó la máquina: UEFI, gestor, parámetros y tiempos | Comando propio T7 |
| `Super + I` | Abre una terminal con `ipc-activo` | Ver qué sockets Unix, pipes y memoria compartida hay abiertos | Comando propio T5 |
| `Super + A` | Abre una terminal con `systemd-analyze critical-chain` | Ver la cadena crítica del arranque | Función de la Capa 2 T7 |

Las tres terminales permanecen abiertas (`--hold`) para inspeccionar la salida y se cierran con `Super + Q`.