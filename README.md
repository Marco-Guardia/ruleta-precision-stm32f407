# Ruleta de Precisión (Tiro al Blanco Visual)

Firmware **bare-metal** en ensamblador ARM Thumb-2 para el
microcontrolador **STM32F407** (núcleo ARM Cortex-M4), desarrollado
sobre la tarjeta **STM32F407VG Discovery**.

## Descripción funcional

El sistema opera como un probador de reflejos: un arreglo de 8 LEDs
(PD0–PD7) enciende un único LED a la vez, desplazando la iluminación en
un bucle continuo con temporización estricta por el periférico SysTick.
El usuario debe presionar un pulsador (PA0) en el instante en que el LED
**objetivo** (PD3) se encuentra encendido.

- **Acierto:** el barrido se detiene y el LED objetivo parpadea 3 veces.
- **Fallo:** el sistema se congela 2 segundos mostrando el LED erróneo y
  reinicia la secuencia automáticamente.

## Requisitos técnicos cumplidos

- ✅ Acceso bare-metal: sin HAL, SPL ni CMSIS-Driver; toda la interacción
  con el hardware es por manipulación directa de registros de memoria.
- ✅ Gestión manual de relojes (`RCC_AHB1ENR`) para GPIOA y GPIOD.
- ✅ Configuración de GPIO por registros (`MODER`, `PUPDR`, `IDR`, `ODR`).
- ✅ Temporización por hardware mediante SysTick en modo *polling*
  (bandera `COUNTFLAG`), sin retardos por decremento de ciclos tipo NOP.
- ✅ Antirrebote (debounce) por software en la lectura del pulsador.

## Hardware

| Elemento | Detalle |
|---|---|
| Microcontrolador | STM32F407 (Cortex-M4) |
| Placa | STM32F407VG Discovery |
| Salidas | 8 LEDs discretos en PD0–PD7 |
| Entrada | 1 pulsador N.O. en PA0 (pull-down interno) |

## Estructura del repositorio

```
.
├── README.md                          <- este archivo
├── src/
│   └── ruleta_precision.s             <- código fuente, comentado por bloques
└── docs/
    ├── 01_estrategias_desarrollo.md   <- debouncing, efecto de barrido
    ├── 02_calculos_temporizacion.md   <- cálculo del valor de recarga SysTick
    ├── 03_registro_configuraciones.md <- tabla de registros modificados
    ├── 04_diagrama_flujo.md           <- diagrama de flujo (Mermaid)
    ├── 05_diagrama_hardware.md        <- pines usados + espacio para el
    │                                     diagrama de conexiones
    ├── 06_prompts_ia.md               <- prompts usados con IA durante el desarrollo
    └── img/
        └── diagrama_conexiones.png    <- ⬅ PENDIENTE: sube aquí tu esquemático
```

## Documentación técnica

Toda la documentación exigida por la rúbrica está en la carpeta
[`/docs`](./docs):

1. [Estrategias de desarrollo](./docs/01_estrategias_desarrollo.md)
2. [Cálculos de temporización](./docs/02_calculos_temporizacion.md)
3. [Registro de configuraciones](./docs/03_registro_configuraciones.md)
4. [Diagrama de flujo](./docs/04_diagrama_flujo.md)
5. [Diagrama de bloques de hardware](./docs/05_diagrama_hardware.md)
6. [Prompts utilizados con IA](./docs/06_prompts_ia.md)

## Compilación

```bash
arm-none-eabi-as -mcpu=cortex-m4 -mthumb src/ruleta_precision.s -o ruleta_precision.o
arm-none-eabi-ld ruleta_precision.o -o ruleta_precision.elf
```

(O bien, importar `src/ruleta_precision.s` directamente en un proyecto
de STM32CubeIDE / Eclipse y compilar desde ahí.)

## Autor

_(agrega tu nombre y el de tu equipo aquí)_
