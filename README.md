# Ruleta de Precisión (Tiro al Blanco Visual)

Firmware bare-metal en ensamblador ARM Thumb-2 para el microcontrolador
**STM32F407** (núcleo ARM Cortex-M4), desarrollado sobre la tarjeta
**STM32F407VG Discovery**.

## Descripción

El sistema opera como un probador de reflejos: un arreglo de 8 LEDs
(PD0–PD7) enciende un único LED a la vez, desplazando la iluminación en
un bucle continuo con temporización estricta por el periférico SysTick.
El usuario debe presionar un pulsador (PA0) en el instante en que el LED
"objetivo" (PD3) se encuentra encendido.

- **Acierto:** el barrido se detiene y el LED objetivo parpadea 3 veces.
- **Fallo:** el sistema se congela 2 segundos mostrando el LED erróneo y
  reinicia la secuencia automáticamente.

## Requisitos técnicos cumplidos

- Acceso bare-metal: sin HAL, SPL ni CMSIS-Driver; toda la interacción
  con el hardware es por manipulación directa de registros de memoria.
- Gestión manual de relojes (RCC_AHB1ENR) para GPIOA y GPIOD.
- Configuración de GPIO por registros (MODER, PUPDR, IDR, ODR).
- Temporización por hardware mediante SysTick en modo *polling*
  (bandera COUNTFLAG), sin retardos por decremento de ciclos.
- Antirrebote (debounce) por software en la lectura del pulsador.

## Hardware

| Elemento | Detalle |
|---|---|
| Microcontrolador | STM32F407 (Cortex-M4) |
| Placa | STM32F407VG Discovery |
| Salidas | 8 LEDs discretos en PD0–PD7 |
| Entrada | 1 pulsador N.O. en PA0 (pull-down interno) |

## Archivos

- `ruleta_precision.s` — código fuente en ensamblador ARM Thumb-2.

## Compilación

```bash
arm-none-eabi-as -mcpu=cortex-m4 -mthumb ruleta_precision.s -o ruleta_precision.o
arm-none-eabi-ld ruleta_precision.o -o ruleta_precision.elf
```

(O bien, importar el archivo `.s` directamente en el proyecto de
STM32CubeIDE / Eclipse y compilar desde ahí.)

## Autor

_(agrega tu nombre y el de tu equipo aquí)_
