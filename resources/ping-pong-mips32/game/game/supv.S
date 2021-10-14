#include <regdef.h>
#include <mipsregs.h> 
#include <game.h>

    .set noreorder
    .set noat


    .section .rodata
    .p2align 2

resume:
    .asciz "resume\n"


    .section .text
    .p2align 2

    .global SUPV_START
SUPV_START:
    lui t0, %hi(SWITCH) + 1
    lw t1, %lo(SWITCH)(t0)
    andi s0, s0, 0x2
    sltu t1, zero, t1
    or s0, s0, t1
    la t0, kb_buffer
    lw t2, -8(t0)
    lw t3, -4(t0)
    beq t2, t3, 3f
    addu t1, t0, t2
    j kb_readbuffer
    lw t5, 0(t1)
kb_readbuffer_loop:
    andi t2, t2, 0x7c
    beq t2, t3, 2f
    addu t1, t0, t2
    lw t5, 0(t1)
kb_readbuffer:
    li t1, KB_PAUSE
    bne t5, t1, 1f
    li t1, KB_RESUME
    addiu t2, t2, 4
    j kb_readbuffer_loop
    ori s0, s0, 0x2
1:
    bne t5, t1, kb_readbuffer_loop
    addiu t2, t2, 4
    j kb_readbuffer_loop
    andi s0, s0, 0x1
2:
    sw t2, -8(t0)
3:
    bnez s0, SUPV_START
    nop
    la a0, UART0
    la a1, resume
    jal PRINT
    nop
    lui t0, %hi(next_thread)
    la t1, GAME_TCB
    sw t1, %lo(next_thread)(t0)
    syscall
    j SUPV_START
    nop

    .global SUPV_SHELL
SUPV_SHELL:
    j RESTART
    nop


    .set reorder
    .set at
