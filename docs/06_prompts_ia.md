# Prompts utilizados con IA (Claude)

Registro cronológico de las interacciones con la IA (Claude, de
Anthropic) usadas como apoyo para depurar errores de compilación/enlace
y para configurar la entrega en GitHub.

| # | Prompt (resumen de lo solicitado) | Propósito |
|---|---|---|
| 1 | Captura de errores de compilación del IDE ("relocation R_ARM_THM_CALL to non-function symbol _start...") | Diagnosticar por qué el build fallaba (faltaba `.cpu cortex-m4` y marcar `_start` como función Thumb con `.thumb_func`). |
| 2 | Capturas de terminal con errores (`git ini`, `remote gttps`, `remote origin already exists`, `repository not found`) | Depurar errores de configuración de Git/GitHub durante el primer `push`. |
| 3 | Captura de error en terminal (`bash: syntax error near unexpected token '('`) | Depurar error de sintaxis en `git commit -m` causado por comillas mal cerradas/curvas. |
| 4 | Captura de terminal con `>` colgado tras un `git commit` con comilla sin cerrar | Resolver el bloqueo de la terminal (Ctrl+C) y reescribir correctamente el comando `git commit`. |
| 5 | "¿Qué es PUSH y POP?" | Entender el uso de la pila (stack) en las subrutinas `button_pressed` y `delay_ms`, y por qué `_start` no las utiliza. |

## Nota metodológica

La IA se usó específicamente como herramienta de **depuración de errores
de compilación/enlace**, **soporte para resolver errores de sintaxis en
terminal** durante la configuración de Git/GitHub, y para **aclarar
conceptos puntuales de la arquitectura ARM** (manejo de pila). El diseño
y la lógica del firmware fueron desarrollados de forma independiente.
