# Registro de Configuraciones

Tabla de todos los registros de la arquitectura STM32F407 modificados
por el firmware, con su dirección base, offset, dirección final, valor
asignado y la justificación técnica de dicho valor.

| Periférico | Registro | Dirección base | Offset | Dirección final | Valor asignado (hex / bin) | Justificación técnica |
|---|---|---|---|---|---|---|
| RCC | AHB1ENR | 0x40023800 | 0x30 | 0x40023830 | `bit0=1, bit3=1` (resto sin modificar, read-modify-write) | Habilita el reloj de GPIOA (bit 0) y GPIOD (bit 3). Sin esto, los registros de esos puertos no responden a escrituras/lecturas. |
| GPIOA | MODER | 0x40020000 | 0x00 | 0x40020000 | `0x00000000` = `00` en todos los pines | PA0 configurado como **entrada digital** (00b) para leer el estado del pulsador. |
| GPIOA | PUPDR | 0x40020000 | 0x0C | 0x4002000C | `0x00000002` = `10` en bits[1:0] (pin 0) | Activa **pull-down interno** en PA0. En reposo el pin queda en 0V; al presionar el botón (cableado a 3.3V) se lee 1 lógico. |
| GPIOD | MODER | 0x40020C00 | 0x00 | 0x40020C00 | `0x00005555` = `01` repetido en bits[15:0] | Configura **PD0–PD7 como salida** de propósito general (01b cada uno) para manejar los 8 LEDs. PD8–PD15 quedan sin usar (00b, valor de reset). |
| GPIOD | ODR | 0x40020C00 | 0x14 | 0x40020C14 | Variable: `0x00` (apagado), `1<<n` (LED n encendido), `0x08` (LED objetivo) | Registro de escritura que enciende/apaga los LEDs. Se actualiza en cada iteración del barrido y en la lógica de acierto/fallo. |
| GPIOA | IDR | 0x40020000 | 0x10 | 0x40020010 | Solo lectura; se enmascara con `AND #1` | Se lee para determinar el estado del pulsador (bit 0 = PA0). |
| SysTick | CSR | 0xE000E010 | — | 0xE000E010 | `0x5` = `ENABLE=1, CLKSOURCE=1` (bits 0 y 2) | Habilita el conteo del temporizador y selecciona el reloj de CPU (16 MHz, sin dividir entre 8) como fuente. |
| SysTick | RVR | 0xE000E014 | — | 0xE000E014 | `0x3E7F` = `15999` decimal | Valor de recarga calculado para que el contador tarde exactamente 1 ms en llegar a 0, a 16 MHz (ver `02_calculos_temporizacion.md`). |
| SysTick | CVR | 0xE000E018 | — | 0xE000E018 | `0x0` | Se fuerza a 0 antes de cada conteo para reiniciar el temporizador desde un estado conocido (escribir cualquier valor en CVR lo limpia a 0 por hardware). |

## Notas sobre bits específicos

- **`RCC_AHB1ENR` bit 0 / bit 3:** corresponden a `GPIOAEN` y `GPIODEN`
  respectivamente, según el mapa de memoria del STM32F407 (bus AHB1).
- **`GPIOx_MODER`:** usa 2 bits por pin (`00`=entrada, `01`=salida,
  `10`=función alternativa, `11`=analógico). Solo se usan los modos
  entrada y salida en este proyecto.
- **`GPIOx_PUPDR`:** usa 2 bits por pin (`00`=sin resistencia,
  `01`=pull-up, `10`=pull-down).
- **`SYST_CSR` bit 16 (`COUNTFLAG`):** se lee (no se escribe) para saber
  cuándo el contador llegó a 0; se limpia automáticamente al leer el
  registro.
