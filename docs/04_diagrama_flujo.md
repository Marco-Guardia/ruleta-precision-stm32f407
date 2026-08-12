# Diagrama de Flujo

Este diagrama está en formato [Mermaid](https://mermaid.js.org/), que
GitHub renderiza automáticamente al ver este archivo en el navegador
(no requiere descargar nada ni abrir un programa externo).

```mermaid
flowchart TD
    A([Reset / Power-on]) --> B[Habilitar reloj de\nGPIOA y GPIOD\nRCC_AHB1ENR]
    B --> C[Configurar PD0-PD7\ncomo salida]
    C --> D[Configurar PA0 como\nentrada + pull-down]
    D --> E[Apagar todos los LEDs\nGPIOD_ODR = 0]
    E --> F[R4 = 1\nLED inicial = PD0]

    F --> G[[loop: mostrar LED actual\nGPIOD_ODR = R4]]
    G --> H[R5 = 10]
    H --> I[check_button:\nesperar 10 ms SysTick]
    I --> J{{button_pressed}}
    J --> K{"¿Pulsación\nválida?"}
    K -- No --> L{"¿R5 == 0?\n(100 ms cumplidos)"}
    L -- No --> M[R5 = R5 - 1] --> I
    L -- Sí --> N[Desplazar R4\nLSLS R4,#1]
    N --> O{"¿R4 == 0x100?"}
    O -- Sí --> P[R4 = 1\nreinicia en PD0] --> G
    O -- No --> G

    K -- Sí --> Q{"¿R4 == 0x08?\n(LED objetivo)"}
    Q -- Sí --> R[[success]]
    Q -- No --> S[[failure]]

    R --> R1[Parpadear LED objetivo\n3 veces 200ms/200ms]
    R1 --> R2[R4 = 1] --> G

    S --> S1[Esperar 2000 ms\nmostrando LED erróneo\nno se toca ODR]
    S1 --> S2[R4 = 1] --> G

    J --> J1["Subrutina button_pressed:\nleer PA0 -> esperar 20ms\n-> releer -> esperar suelte"]
```

## Detalle de la subrutina `button_pressed` (antirrebote)

```mermaid
flowchart TD
    A([Entrada: leer GPIOA_IDR]) --> B{"¿bit0 == 1?"}
    B -- No --> Z[Retorna R0 = 0]
    B -- Sí --> C[Esperar 20 ms\nSysTick]
    C --> D[Releer GPIOA_IDR]
    D --> E{"¿bit0\nsigue en 1?"}
    E -- No --> Z2[Fue ruido/rebote\nRetorna R0 = 0]
    E -- Sí --> F[wait_release:\nesperar a que\nel usuario suelte]
    F --> G[Retorna R0 = 1]
```

## Correspondencia con las etiquetas del código fuente

| Bloque del diagrama | Etiqueta en `src/ruleta_precision.s` |
|---|---|
| Inicialización | `_start` (antes de `loop:`) |
| Barrido / mostrar LED | `loop`, `check_button`, `next_led` |
| Antirrebote | `button_pressed`, `wait_release`, `not_pressed` |
| Evaluación acierto/fallo | `button_event` |
| Acierto | `success`, `blink` |
| Fallo | `failure` |
| Temporización | `delay_ms`, `delay_loop`, `wait_flag` |
