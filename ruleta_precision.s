.global _start
.syntax unified
.cpu cortex-m4
.thumb

/*=========================================================
    RULETA DE PRECISIÓN
    STM32F407 Discovery
=========================================================*/

/*================ RCC =================*/

.equ RCC_BASE,        0x40023800
.equ RCC_AHB1ENR,     (RCC_BASE + 0x30)

/*================ GPIOA =================*/

.equ GPIOA_BASE,      0x40020000
.equ GPIOA_MODER,     (GPIOA_BASE + 0x00)
.equ GPIOA_PUPDR,     (GPIOA_BASE + 0x0C)
.equ GPIOA_IDR,       (GPIOA_BASE + 0x10)

/*================ GPIOD =================*/

.equ GPIOD_BASE,      0x40020C00
.equ GPIOD_MODER,     (GPIOD_BASE + 0x00)
.equ GPIOD_ODR,       (GPIOD_BASE + 0x14)

/*================ SysTick =================*/

.equ SYST_CSR,        0xE000E010
.equ SYST_RVR,        0xE000E014
.equ SYST_CVR,        0xE000E018



.thumb_func
_start:

/*-------------------------------------------------------
    Habilitar GPIOA y GPIOD
-------------------------------------------------------*/

    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]

    ORR R1,R1,#(1<<0)
    ORR R1,R1,#(1<<3)

    STR R1,[R0]

/*-------------------------------------------------------
    Configurar PD0-PD7 como salidas
-------------------------------------------------------*/

    LDR R0, =GPIOD_MODER
    LDR R1, =0x00005555
    STR R1,[R0]

/*-------------------------------------------------------
    Configurar PA0 como entrada con Pull-Down
-------------------------------------------------------*/

    LDR R0, =GPIOA_MODER
    MOVS R1,#0
    STR R1,[R0]

    LDR R0, =GPIOA_PUPDR
    MOVS R1,#2
    STR R1,[R0]

/*-------------------------------------------------------
    Apagar LEDs
-------------------------------------------------------*/

    LDR R0, =GPIOD_ODR
    MOVS R1,#0
    STR R1,[R0]

/*-------------------------------------------------------
    Primer LED
-------------------------------------------------------*/

    MOVS R4,#1

/*=======================================================
                    BUCLE PRINCIPAL
=======================================================*/

loop:

/* Mostrar LED */

    LDR R0, =GPIOD_ODR
    STR R4,[R0]

/* Mantener LED durante 100 ms
   revisando el botón cada 10 ms */

    MOVS R5,#10

check_button:

    MOVS R0,#10
    BL delay_ms

    BL button_pressed

    CMP R0,#1
    BEQ button_event

    SUBS R5,R5,#1
    BNE check_button

/* Siguiente LED */

next_led:

    LSLS R4,R4,#1

    CMP R4,#0x100
    BNE loop

    MOVS R4,#1
    B loop

/*-------------------------------------------------------
    Se presionó el botón
-------------------------------------------------------*/

button_event:

    MOVS R1,#0x08

    CMP R4,R1
    BEQ success

    B failure

/*=======================================================
                    ACIERTO
=======================================================*/

success:

    MOVS R6,#3

blink:

    LDR R0,=GPIOD_ODR
    MOVS R1,#0x08
    STR R1,[R0]

    MOVW R0,#200
    BL delay_ms

    LDR R0,=GPIOD_ODR
    MOVS R1,#0
    STR R1,[R0]

    MOVW R0,#200
    BL delay_ms

    SUBS R6,R6,#1
    BNE blink

    MOVS R4,#1
    B loop

/*=======================================================
                    FALLO
=======================================================*/

failure:

    MOVW R0,#2000
    BL delay_ms

    MOVS R4,#1

    B loop

    /************************************************/
/* button_pressed                               */
/* Devuelve:                                    */
/*   R0 = 1 -> botón presionado                 */
/*   R0 = 0 -> botón no presionado              */
/************************************************/

button_pressed:

    PUSH {R1,R2,LR}

    LDR R1, =GPIOA_IDR
    LDR R2, [R1]

    ANDS R2,R2,#1

    CMP R2,#0
    BEQ not_pressed

/*----------------------------------------------*/
/* Debounce 20 ms                               */
/*----------------------------------------------*/

    MOVS R0,#20
    BL delay_ms

    LDR R2,[R1]
    ANDS R2,R2,#1

    CMP R2,#0
    BEQ not_pressed

/* Esperar a que el botón sea liberado */

wait_release:

    LDR R2,[R1]
    ANDS R2,R2,#1

    CMP R2,#0
    BNE wait_release

    MOVS R0,#1
    POP {R1,R2,PC}

not_pressed:

    MOVS R0,#0
    POP {R1,R2,PC}


/************************************************/
/* delay_ms                                     */
/* Entrada: R0 = milisegundos                   */
/************************************************/

delay_ms:

    PUSH {R1-R4,LR}

delay_loop:

/* 16000 ciclos = 1 ms @16 MHz */

    LDR R1, =SYST_RVR
    LDR R2, =15999
    STR R2,[R1]

    LDR R1, =SYST_CVR
    MOVS R2,#0
    STR R2,[R1]

    LDR R1, =SYST_CSR
    MOVS R2,#5          /* ENABLE=1 CLKSOURCE=1 */
    STR R2,[R1]

wait_flag:

    LDR R2,[R1]
    TST R2,#(1<<16)
    BEQ wait_flag

/* Apagar SysTick */

    MOVS R2,#0
    STR R2,[R1]

    SUBS R0,R0,#1
    BNE delay_loop

    POP {R1-R4,PC}
