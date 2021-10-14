#include <regdef.h>
#include <mipsregs.h>
#include <exception.h>
#include <game.h>

    .set noreorder
    .set noat


    .section .rodata
    .p2align 2

pingpong:
    .asciz "Ping Pong.\n"


    .section .data
    .p2align 2

    .global TCBT
TCBT:

    .global SUPV_TCB
SUPV_TCB:
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word SUPV_SHELL
    .word KB_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    // gp
    .word 0
    // sp
    .word SPVR_STACK_INIT
    // fp
    .word SPVR_STACK_INIT
    // ra
    .word 0
    // Count
    .word 0
    // Compare
    .word -1
    // STATUS
    .word IE_IRQ3 | IE_IRQ2 | ST0_IE
    // EPC
    .word SUPV_START

    .global GAME_TCB
GAME_TCB:
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word DEFAULT_INT_HANDLER
    .word KB_HANDLER
    .word DEFAULT_INT_HANDLER
    .word GAME_TIMER
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    // random
    .word 0xBFC00380
    // player1_y
    .word center_y
    // player1_y
    .word center_y
    // ball_x
    .word center_x
    // ball_y
    .word center_y
    // ball_cntx
    .word 0
    // ball_cnty
    .word 0
    // ball_spx
    .word x_sp3
    // ball_spy
    .word y_sp0
    // ball_dx
    .word -1
    // ball_dy
    .word 1
    // gp
    .word 0
    // sp
    .word SPVR_STACK_INIT
    // fp
    .word SPVR_STACK_INIT
    // ra
    .word 0
    // Count
    .word 0
    // Compare
    .word 16500000 / fps
    // STATUS
    .word IE_IRQ5 | IE_IRQ3 | ST0_IE
    // EPC
    .word GAME_START

    .global current_thread
current_thread:
    .word 0

    .global next_thread
next_thread:
    .word GAME_TCB


    .section .text
    .p2align 2

    .global START
START:
    la t0, _sbss
    la t1, _ebss
    beq t0, t1, bss_init_done
    nop
bss_init:
    sw  zero, 0(t0)
    addiu t0, t0, 4
    bne t0, t1, bss_init
    nop
bss_init_done:
    la t2, _text_ebase_begin
    mtc0 t2, CP0_EBASE

    /* init serial */
    la  t0, UART0

    //      FIFO_ENABLE | FIFO_RCV_RST | FIFO_XMT_RST | FIFO_TRIGGER_1
    li  t1, 0x1         | 0x2          | 0x4          | 0x0
    sb  t1, 2(t0)   // FIFO
    li  t1, 0x80    // CFCR_DliB, divisor litch
    sb  t1, 3(t0)   // CFCR
    li  t1, 0x23    // modify Baud 57600
    sb  t1, 0(t0)   // DATA
    srl t1, 8
    sb  t1, 1(t0)   // IER

    li  t1, 0x3     // CFCR_8BITS
    sb  t1, 3(t0)   // CFCR
    //      MCR_DTR | MCR_RTS
    li  t1, 0x1     | 0x2
    sb  t1, 4(t0)   // MCR
    li  t1, 0x1     // IRxE
    sb  t1, 1(t0)   // IER

    // la  t0, UART1

    // //      FIFO_ENABLE | FIFO_RCV_RST | FIFO_XMT_RST | FIFO_TRIGGER_1
    // li  t1, 0x1         | 0x2          | 0x4          | 0x0
    // sb  t1, 2(t0)   // FIFO
    // li  t1, 0x80    // CFCR_DliB, divisor litch
    // sb  t1, 3(t0)   // CFCR
    // li  t1, 0x1b    // modify Baud 76388.89
    // sb  t1, 0(t0)   // DATA
    // srl t1, 8
    // sb  t1, 1(t0)   // IER

    // li  t1, 0x3     // CFCR_8BITS
    // sb  t1, 3(t0)   // CFCR
    // //      MCR_DTR | MCR_RTS
    // li  t1, 0x1     | 0x2
    // sb  t1, 4(t0)   // MCR
    // li  t1, 0x1     // IRxE
    // sb  t1, 1(t0)   // IER

    la a0, UART0
    la a1, pingpong
    jal PRINT
    nop

    la a0, UART1
    li a1, KB_RESET
    jal WRITESERIAL
    nop

    lui t0, %hi(SEG7) + 1
    li t1, 0
    sw t1, %lo(SEG7)(t0)

    j RESTART_LOAD
    nop


    .set reorder
    .set at
