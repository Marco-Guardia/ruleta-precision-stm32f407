# Cálculos de Temporización (SysTick)

## Frecuencia de reloj utilizada

El programa **no reconfigura el reloj del sistema** (no toca el RCC para
activar el PLL), por lo tanto el STM32F407 sigue usando su reloj interno
de arranque por defecto:

```
Fuente de reloj: HSI (High-Speed Internal oscillator)
Frecuencia:      f_CLK = 16 MHz
```

En `SYST_CSR` se configura `CLKSOURCE = 1`, que selecciona el reloj de
CPU **sin dividir entre 8**, por lo que SysTick cuenta directamente a
16 MHz (16 000 000 ciclos por segundo).

## Fórmula general

El registro `SYST_RVR` (Reload Value Register) define cuántos ciclos de
reloj cuenta SysTick, desde `RVR` hasta `0`, antes de levantar la bandera
`COUNTFLAG`. Como cuenta un ciclo extra en el valor `0`, la cantidad de
ciclos real es `RVR + 1`. Para lograr un tiempo objetivo `t` (en
segundos):

```
Numero de ciclos necesarios = f_CLK * t

RVR = (f_CLK * t) - 1
```

## Cálculo para 1 milisegundo (bloque base de `delay_ms`)

```
f_CLK = 16 000 000 Hz
t     = 1 ms = 0.001 s

Ciclos necesarios = 16 000 000 * 0.001 = 16 000 ciclos

RVR = 16 000 - 1 = 15 999
```

Esto coincide exactamente con el valor cargado en el código:

```asm
LDR R2, =15999
STR R2,[R1]        ; SYST_RVR = 15999
```

## Cómo se generan los demás tiempos del programa

`delay_ms` recibe en `R0` la cantidad de milisegundos deseada y repite el
bloque de 1 ms (recarga → cuenta → bandera) tantas veces como indique
`R0`. Todos los tiempos usados en el programa son múltiplos exactos de
este bloque base:

| Tiempo requerido | Se logra con | Verificación |
|---|---|---|
| 10 ms (revisión del botón) | `MOVS R0,#10` → `BL delay_ms` | 10 × 1 ms = 10 ms |
| 20 ms (ventana de antirrebote) | `MOVS R0,#20` → `BL delay_ms` | 20 × 1 ms = 20 ms |
| 200 ms (parpadeo de acierto) | `MOVW R0,#200` → `BL delay_ms` | 200 × 1 ms = 200 ms |
| 2000 ms (congelamiento de fallo) | `MOVW R0,#2000` → `BL delay_ms` | 2000 × 1 ms = 2 s |
| 100 ms (permanencia de cada LED) | 10 × llamada de 10 ms (`check_button`) | 10 × 10 ms = 100 ms |

## Precisión y limitaciones

- El tiempo de conteo en sí (16 000 ciclos) es exacto porque lo mide el
  hardware de SysTick, no el software.
- Existe un pequeño overhead de instrucciones entre el apagado de
  SysTick y su reconfiguración para el siguiente milisegundo (unas
  pocas instrucciones `LDR`/`STR`/`MOVS`), del orden de decenas de
  ciclos (~microsegundos). Es despreciable frente a los tiempos usados
  en el programa (10 ms–2000 ms), pero se documenta aquí por
  transparencia técnica: el tiempo real es levemente mayor al nominal,
  no menor.

## Si se usara otra frecuencia de reloj

Para dejar registrado el procedimiento general (por si se activara el
PLL a, por ejemplo, 168 MHz — la frecuencia máxima del STM32F407):

```
f_CLK = 168 000 000 Hz
t     = 0.001 s

RVR = (168 000 000 * 0.001) - 1 = 167 999
```

Cualquier cambio de frecuencia de reloj implicaría recalcular y
reemplazar el valor `15999` en el código por el resultado de esta misma
fórmula.
