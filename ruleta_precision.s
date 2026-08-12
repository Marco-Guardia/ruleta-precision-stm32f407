/*=========================================================
    RULETA DE PRECISION (Tiro al Blanco Visual)
    STM32F407 - Nucleo ARM Cortex-M4
    STM32F407VG Discovery

    Firmware bare-metal: acceso directo a registros de
    memoria, sin HAL/SPL/CMSIS-Driver.

    Funcionamiento resumido:
      1. Un LED recorre PD0..PD7 encendiendose uno a la vez.
      2. El usuario presiona el boton (PA0) intentando
         acertar el instante en que el LED objetivo (PD3)
         esta encendido.
      3. Acierto  -> el LED objetivo parpadea 3 veces.
      4. Fallo    -> el sistema se congela 2 s mostrando el
         LED erroneo y reinicia el barrido.
=========================================================*/

.global _start
.syntax unified
.cpu cortex-m4
.thumb

// ================ RCC =================
// Reset and Clock Control: hay que habilitar el reloj de
// cada periferico antes de poder usarlo.

.equ RCC_BASE,        0x40023800
.equ RCC_AHB1ENR,     (RCC_BASE + 0x30)   // Clock enable de GPIOA..GPIOI

// ================ GPIOA =================
// Puerto A: se usa unicamente PA0 como entrada (boton).

.equ GPIOA_BASE,      0x40020000
.equ GPIOA_MODER,     (GPIOA_BASE + 0x00) // Modo de cada pin (2 bits/pin)
.equ GPIOA_PUPDR,     (GPIOA_BASE + 0x0C) // Pull-up/Pull-down interno
.equ GPIOA_IDR,       (GPIOA_BASE + 0x10) // Input Data Register (lectura)

//GPIOD
// Puerto D: PD0-PD7 se usan como salida para los 8 LEDs.

.equ GPIOD_BASE,      0x40020C00
.equ GPIOD_MODER,     (GPIOD_BASE + 0x00)
.equ GPIOD_ODR,       (GPIOD_BASE + 0x14) // Output Data Register (escritura)

//SysTick
// Temporizador de 24 bits interno al nucleo Cortex-M. Se
// usa en modo "polling" (sondeo de bandera) para toda la
// temporizacion del programa: nada de retardos por NOP.

.equ SYST_CSR,        0xE000E010  // Control and Status Register
.equ SYST_RVR,        0xE000E014  // Reload Value Register
.equ SYST_CVR,         0xE000E018  // Current Value Register

.thumb_func
_start:
//GPIOA y GPIOD
// Patron read-modify-write: se lee AHB1ENR, se activan
// solo los bits necesarios con ORR (sin apagar otros
// perifericos que pudieran estar habilitados) y se
// escribe de vuelta.
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1,R1,#(1<<0)  //El reloj de GPIOA está en el bit 0
    ORR R1,R1,#(1<<3) //El reloj de GPIOD está en el bit 3
    STR R1,[R0]

//PD0-PD7 se configuran como salidas
// MODER usa 2 bits por pin: 01 = salida de proposito
// general. 0x5555 = "01" repetido 8 veces -> PD0..PD7
// como salida; PD8..PD15 quedan sin usar.
    LDR R0, =GPIOD_MODER
    LDR R1, =0x00005555 
    STR R1,[R0]

//PA0 lo configuramos como pull down debido a su naturaleza de esquematicos 
// MODER=0 -> 00b = entrada. PUPDR=2 -> 10b en el pin 0 =
// pull-down interno. En reposo PA0 se lee en 0; al
// presionar el boton (que conecta a 3.3V) se lee en 1.
    LDR R0, =GPIOA_MODER
    MOVS R1,#0
    STR R1,[R0]
    LDR R0, =GPIOA_PUPDR
    MOVS R1,#2
    STR R1,[R0]

//Se apagan los leds
// Requisito: al energizar/resetear, todos los LEDs deben
// iniciar apagados.
    LDR R0, =GPIOD_ODR
    MOVS R1,#0
    STR R1,[R0]

//El primer led
// R4 = mascara de un solo bit que indica cual LED esta
// encendido: 1=PD0, 2=PD1, 4=PD2, 8=PD3(objetivo)...
    MOVS R4,#1

/*=======================================================
    BUCLE PRINCIPAL
    Recorre PD0..PD7 encendiendo un LED a la vez. Cada LED
    permanece 100 ms encendido, revisando el boton cada
    10 ms para no perder capacidad de respuesta.
=======================================================*/
loop:
//Se muestra el led
    LDR R0, =GPIOD_ODR
    STR R4,[R0]

//El led se mantiene encendido 100ms y se revisa el boton cada 10ms
// 10 iteraciones x 10 ms = 100 ms totales por LED.
    MOVS R5,#10
check_button:
    MOVS R0,#10
    BL delay_ms
    BL button_pressed          // R0 = 1 si hubo pulsacion valida
    CMP R0,#1
    BEQ button_event
    SUBS R5,R5,#1
    BNE check_button

// Se agoto el tiempo de este LED sin pulsacion -> avanza
// al siguiente LED desplazando la mascara un bit.
next_led:
    LSLS R4,R4,#1
    CMP R4,#0x100               // se paso del ultimo LED (PD7)?
    BNE loop
    MOVS R4,#1                  // reinicia el barrido en PD0
    B loop

// Se detecto una pulsacion valida: se compara el LED
// actualmente encendido (R4) contra el LED objetivo.
button_event:
    MOVS R1,#0x08                // 0x08 = PD3, LED objetivo (central)
    CMP R4,R1
    BEQ success
    B failure

/*=======================================================
    ACIERTO: el LED objetivo parpadea 3 veces (200 ms
    encendido / 200 ms apagado) como confirmacion visual,
    y luego se reinicia el barrido.
=======================================================*/
success:
    MOVS R6,#3                   // contador de parpadeos
blink:
    LDR R0,=GPIOD_ODR
    MOVS R1,#0x08
    STR R1,[R0]                  // enciende LED objetivo
    MOVW R0,#200
    BL delay_ms
    LDR R0,=GPIOD_ODR
    MOVS R1,#0
    STR R1,[R0]                  // apaga LED objetivo
    MOVW R0,#200
    BL delay_ms
    SUBS R6,R6,#1
    BNE blink
    MOVS R4,#1                   // reinicia barrido en PD0
    B loop

/*=======================================================
    FALLO: no se toca GPIOD_ODR, por lo que el LED
    erroneo que ya estaba encendido (R4) queda visible
    durante el retardo de 2 s. Luego reinicia el barrido.
=======================================================*/
failure:
    MOVW R0,#2000
    BL delay_ms
    MOVS R4,#1
    B loop

/************************************************/
/* button_pressed                                */
/* Lee PA0 y aplica antirrebote (debouncing) por  */
/* software.                                      */
/* Salida: R0=1 pulsacion valida, R0=0 no hubo    */
/************************************************/
button_pressed:
    // PUSH necesario: esta subrutina llama a delay_ms
    // (BL anidado), que sobrescribe LR y usa R1..R4.
    // Se guardan R1, R2 y LR para restaurarlos al salir.
    PUSH {R1,R2,LR}
    LDR R1, =GPIOA_IDR
    LDR R2, [R1]
    ANDS R2,R2,#1                // aisla el bit 0 (PA0)
    CMP R2,#0
    BEQ not_pressed

    // Filtro antirrebote: se espera 20 ms y se vuelve a
    // leer el pin. Si ya no esta en alto, fue ruido, no
    // una pulsacion real.
    MOVS R0,#20
    BL delay_ms
    LDR R2,[R1]                  // R1 sigue apuntando a GPIOA_IDR
    ANDS R2,R2,#1                // porque delay_ms preserva R1..R4
    CMP R2,#0
    BEQ not_pressed

// Pulsacion confirmada: espera a que el usuario suelte
// el boton antes de retornar, para evitar que una sola
// pulsacion larga cuente como varias.
wait_release:
    LDR R2,[R1]
    ANDS R2,R2,#1
    CMP R2,#0
    BNE wait_release
    MOVS R0,#1
    POP {R1,R2,PC}                // POP ...,PC = return
not_pressed:
    MOVS R0,#0
    POP {R1,R2,PC}

/************************************************/
/* delay_ms                                       */
/* Temporizacion precisa por hardware (SysTick),  */
/* en modo polling sobre la bandera COUNTFLAG.    */
/* Entrada: R0 = cantidad de milisegundos          */
/************************************************/
delay_ms:
    // PUSH necesario: el llamador (loop, button_pressed,
    // etc.) sigue usando R1..R4 despues del BL; deben
    // quedar exactamente como estaban al entrar.
    PUSH {R1-R4,LR}
delay_loop:
/* 16000 ciclos = 1 ms @16 MHz */
/* RVR = (f_CLK[Hz] * t[s]) - 1 = (16 000 000*0.001)-1 = 15999 */
    LDR R1, =SYST_RVR
    LDR R2, =15999
    STR R2,[R1]
    LDR R1, =SYST_CVR
    MOVS R2,#0
    STR R2,[R1]                  // reinicia el contador a 0
    LDR R1, =SYST_CSR
    MOVS R2,#5          /* ENABLE=1 CLKSOURCE=1 */
    STR R2,[R1]
wait_flag:
    LDR R2,[R1]
    TST R2,#(1<<16)              // bit COUNTFLAG: 1 solo cuando llega a 0
    BEQ wait_flag
//Apagamos el SysTick
    MOVS R2,#0
    STR R2,[R1]
    SUBS R0,R0,#1                 // decrementa contador de ms (no mide tiempo,
    BNE delay_loop                 // solo repite el bloque de hardware de 1ms)
    POP {R1-R4,PC}
