# Estrategias de Desarrollo

## 1. Efecto visual de desplazamiento (barrido de LEDs)

**Problema:** encender un único LED a la vez entre 8 disponibles (PD0–PD7)
y desplazar esa iluminación de forma continua, sin usar más de un pin de
datos por LED.

**Estrategia adoptada — máscara de un solo bit:**
En lugar de usar un contador (0,1,2,3…) y convertirlo cada vez a un patrón
de bits, se usa directamente el registro `R4` como **máscara binaria**:

```
R4 = 0000 0001  ->  enciende PD0
R4 = 0000 0010  ->  enciende PD1
R4 = 0000 0100  ->  enciende PD2
...
R4 = 1000 0000  ->  enciende PD7
```

Avanzar al siguiente LED es entonces una sola instrucción:

```asm
LSLS R4, R4, #1      ; desplaza el bit un lugar a la izquierda
```

Cuando `R4` se desplaza más allá de PD7 (`R4 == 0x100`), se detecta con un
`CMP` y se reinicia en `0x01`. Esta estrategia se eligió porque:
- Escribir `R4` directo en `GPIOD_ODR` enciende el LED correcto sin
  cálculos adicionales (no hace falta tabla de conversión ni loop).
- `LSLS` actualiza automáticamente las flags (Z, C), lo que permite
  además usar `BEQ`/`BNE` de forma económica en otras partes del código.

## 2. Antirrebote (debouncing) del pulsador

**Problema:** un pulsador mecánico, al presionarse o soltarse, no cambia
de estado de forma limpia: genera varias transiciones eléctricas rápidas
("rebotes") en microsegundos/milisegundos, que un programa que lea el pin
demasiado rápido puede interpretar como varias pulsaciones distintas.

**Estrategia adoptada — doble lectura con espera fija (software
debouncing):**

1. Se lee `GPIOA_IDR` y se aísla el bit 0 (`ANDS R2,R2,#1`).
2. Si está en alto, se espera **20 ms** usando `delay_ms` (temporizado por
   SysTick, no por ciclos de instrucción).
3. Se vuelve a leer el pin. Si sigue en alto, se confirma como pulsación
   real; si ya no lo está, se descarta como ruido/rebote.
4. Adicionalmente, se implementa un `wait_release`: el programa no
   retorna hasta que el usuario **suelte** el botón, evitando que una
   sola pulsación sostenida se cuente varias veces en iteraciones
   posteriores del bucle principal.

**¿Por qué 20 ms?** Es un valor típico y conservador para pulsadores
táctiles/mecánicos: el rebote real normalmente dura entre 1 y 10 ms, así
que 20 ms da margen sin introducir un retraso perceptible para el
usuario.

**Alternativas consideradas y descartadas:**
- *Debounce por hardware (capacitor + resistencia):* se descartó porque
  el reto exige resolver el problema por software.
- *Interrupciones externas (EXTI) con conteo de flancos:* se descartó
  por simplicidad, ya que el enunciado permite temporización por
  sondeo (polling) y el barrido principal ya revisa el botón cada 10 ms,
  lo cual es suficiente resolución para el juego de reflejos.

## 3. Separación de la espera de 100 ms en tramos de 10 ms

En vez de bloquear el programa 100 ms de corrido mientras un LED está
encendido, el bucle principal parte esa espera en 10 tramos de 10 ms,
revisando el botón entre cada uno (`check_button`). Esto evita que una
pulsación del usuario "se pierda" mientras el programa está atrapado en
un único retardo largo, mejorando la sensación de respuesta del sistema
sin necesidad de interrupciones.
