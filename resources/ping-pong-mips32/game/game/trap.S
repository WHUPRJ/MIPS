#include <regdef.h>
#include <mipsregs.h>
#include <exception.h>
#include <game.h>

    .set noreorder
    .set noat


    .section .text.ebase180
    .p2align 2

    lui k0, %hi(current_thread)
    mfc0 k1, CP0_STATUS
    lw k0, %lo(current_thread)(k0)
    sw k1, TF_STATUS(k0)
    mfc0 k0, CP0_CAUSE
    andi k1, k0, CAUSEF_EXCCODE
    bnez k1, SYSCALL
    nop
    srl k1, k0, 15
    or k0, k0, k1
7:
    mfc0 k1, CP0_STATUS
    and k0, k0, k1
    andi k1, k0, C_IRQ5
    beqz k1, 6f
    andi k1, k0, C_IRQ4
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL7(k0)
    jr k1
    nop
6:
    beqz k1, 5f
    andi k1, k0, C_IRQ3
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL6(k0)
    jr k1
    nop
5:
    beqz k1, 4f
    andi k1, k0, C_IRQ2
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL5(k0)
    jr k1
    nop
4:
    beqz k1, 3f
    andi k1, k0, C_IRQ1
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL4(k0)
    jr k1
    nop
3:
    beqz k1, 2f
    andi k1, k0, C_IRQ0
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL3(k0)
    jr k1
    nop
2:
    beqz k1, 1f
    andi k1, k0, C_SW1
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL2(k0)
    jr k1
    nop
1:
    beqz k1, 0f
    nop
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL1(k0)
    jr k1
    nop
0:
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_INTHDL0(k0)
    jr k1
    nop

SYSCALL:
    li k1, EX_SYS
    bne k0, k1, DEFAULT_INT_HANDLER
    nop
    mfc0 k1, CP0_EPC
    addiu k1, k1, 0x4
    mtc0 k1, CP0_EPC

    .global RESTART_SAVE
RESTART_SAVE:
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    sw AT, TF_AT(k0)
    sw v0, TF_v0(k0)
    sw v1, TF_v1(k0)
    sw a0, TF_a0(k0)
    sw a1, TF_a1(k0)
    sw a2, TF_a2(k0)
    sw a3, TF_a3(k0)
    sw t0, TF_t0(k0)
    sw t1, TF_t1(k0)
    sw t2, TF_t2(k0)
    sw t3, TF_t3(k0)
    sw t4, TF_t4(k0)
    sw t5, TF_t5(k0)
    sw t6, TF_t6(k0)
    sw t7, TF_t7(k0)
    sw s0, TF_s0(k0)
    sw s1, TF_s1(k0)
    sw s2, TF_s2(k0)
    sw s3, TF_s3(k0)
    mfc0 k1, CP0_COUNT
    sw s4, TF_s4(k0)
    sw s5, TF_s5(k0)
    sw k1, TF_COUNT(k0)
    sw s6, TF_s6(k0)
    sw s7, TF_s7(k0)
    mfc0 k1, CP0_COMPARE
    sw t8, TF_t8(k0)
    sw t9, TF_t9(k0)
    sw k1, TF_COMPARE(k0)
    sw gp, TF_gp(k0)
    sw sp, TF_sp(k0)
    mfc0 k1, CP0_EPC
    sw fp, TF_fp(k0)
    sw ra, TF_ra(k0)
    sw k1, TF_EPC(k0)

    .global RESTART_LOAD
RESTART_LOAD:
    lui k0, %hi(next_thread)
    lui k1, %hi(current_thread)
    lw k0, %lo(next_thread)(k0)
    sw k0, %lo(current_thread)(k1)
    lw AT, TF_AT(k0)
    lw v0, TF_v0(k0)
    lw v1, TF_v1(k0)
    lw a0, TF_a0(k0)
    lw a1, TF_a1(k0)
    lw a2, TF_a2(k0)
    lw a3, TF_a3(k0)
    lw t0, TF_t0(k0)
    lw t1, TF_t1(k0)
    lw t2, TF_t2(k0)
    lw t3, TF_t3(k0)
    lw t4, TF_t4(k0)
    lw t5, TF_t5(k0)
    lw t6, TF_t6(k0)
    lw t7, TF_t7(k0)
    lw s0, TF_s0(k0)
    lw s1, TF_s1(k0)
    lw s2, TF_s2(k0)
    lw s3, TF_s3(k0)
    lw k1, TF_COUNT(k0)
    lw s4, TF_s4(k0)
    lw s5, TF_s5(k0)
    mtc0 k1, CP0_COUNT
    lw s6, TF_s6(k0)
    lw s7, TF_s7(k0)
    lw k1, TF_COMPARE(k0)
    lw t8, TF_t8(k0)
    lw t9, TF_t9(k0)
    mtc0 k1, CP0_COMPARE
    lw gp, TF_gp(k0)
    lw sp, TF_sp(k0)
    lw k1, TF_EPC(k0)
    lw fp, TF_fp(k0)
    lw ra, TF_ra(k0)
    mtc0 k1, CP0_EPC

    .global RESTART
RESTART:
    lui k0, %hi(current_thread)
    lw k0, %lo(current_thread)(k0)
    lw k1, TF_STATUS(k0)
    ori k1, k1, ST0_EXL
    mtc0 k1, CP0_STATUS
    eret

//     .global DEFAULT_TIMER
// DEFAULT_TIMER:
//     mtc0 zero, CP0_COUNT
//     j RESTART
//     nop

    .global DEFAULT_INT_HANDLER
DEFAULT_INT_HANDLER:
    j RESTART
    nop


    .set reorder
    .set at
