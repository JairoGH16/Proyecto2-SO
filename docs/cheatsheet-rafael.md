### Rafael

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| `Super + Y` | Abre una terminal con `memoria --top 15` | Ver en vivo memoria, swap, zram y fallos de página por proceso | Función de la Capa 2 · T2 |
| `Super + S` | Abre una terminal con `servicios-limites -a` | Ver los límites de CPU y memoria de cada servicio y si el kernel lo frena | Comando propio · T4 |
| `Super + K` | Abre una terminal con `riesgo-oom -n 15` | Saber qué procesos mataría primero el OOM killer | Comando propio · T2 |

Las terminales de `Super + S` y `Super + K` quedan abiertas (`--hold`) y se cierran con `Super + Q`; la de `Super + Y` se refresca sola y se detiene con `Ctrl + C`.
