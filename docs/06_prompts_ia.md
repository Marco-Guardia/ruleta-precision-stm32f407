# Prompts utilizados con IA (Claude)

Registro cronológico de las interacciones con la IA (Claude, de
Anthropic) usadas como apoyo durante el desarrollo del proyecto.

| # | Prompt (resumen de lo solicitado) | Propósito |
|---|---|---|
| 1 | "Haz este código sin cpu cortex m4" (adjuntando el código base) | Explorar si el firmware podía ensamblarse sin declarar el núcleo objetivo explícitamente en el `.s`. |
| 2 | Captura de errores de compilación del IDE ("relocation R_ARM_THM_CALL to non-function symbol _start...") | Diagnosticar por qué el build fallaba tras el cambio anterior. |
| 3 | Capturas del enunciado del reto + "¿Se cumple con lo que piden las imágenes?" | Verificar que el firmware cumpliera cada requisito funcional y técnico especificado por el profesor. |
| 4 | "Necesito que me expliques todo el código ya que necesito sustentarlo. Si quieres puedes ponerlo en un documento" | Generar material de estudio/sustentación: explicación línea por línea del firmware. |
| 5 | "Necesito hacer un GitHub ya que la entrega se hace ahí. ¿Cómo sería?" | Obtener guía para crear y estructurar el repositorio de entrega. |
| 6 | "Es el primer repositorio que creo" | Solicitar instrucciones detalladas desde cero (instalación de Git, configuración, comandos). |
| 7 | Capturas de terminal con errores (`git ini`, `remote gttps`, `remote origin already exists`, `repository not found`) | Depurar errores de configuración de Git/GitHub durante el primer `push`. |
| 8 | "Había borrado el repositorio porque quedó con un nombre diferente. Ya lo creé nuevamente" | Continuar la configuración del remoto tras recrear el repositorio. |
| 9 | "¿Qué pines se van a usar?" | Confirmar la asignación de pines (LEDs y pulsador) a partir del código fuente. |
| 10 | "¿Por qué no se usa PUSH o POP?" | Entender por qué `_start` no usa pila mientras que las subrutinas sí, y el rol de `LR` en llamadas anidadas. |
| 11 | Capturas de la rúbrica de documentación técnica + "Necesito montar todo en GitHub... diagrama de flujo, código bien comentado, prompts de IA, espacio para diagrama de conexiones" | Generar la documentación técnica completa (`/docs`) exigida por la rúbrica de entrega. |

## Nota metodológica

La IA se usó como herramienta de **apoyo, depuración y documentación**:
explicación de errores del linker, verificación de cumplimiento de
requisitos, generación de material de sustentación y estructuración de
la entrega en GitHub. El diseño original del firmware (estrategia de
máscara de bits para el barrido, lógica de acierto/fallo, uso de
SysTick por polling) fue desarrollado y luego revisado/documentado con
apoyo de la IA.
