#include <regdef.h>

    .set noreorder
    .set noat


    .section .text.init
    .p2align 2

    .global INITLOCATE
INITLOCATE:
    li k0, 0xa0000000
    li k1, 0xbfc00000
    li t0, _text_ebase_begin
    li t1, _text_ebase_end
    li t2, _text_ebase_begin
    li t3, _text_code_begin
    li t4, _text_code_end
    li t5, _text_code_begin
    li t6, _data_begin
    li t7, _data_end
    li t8, _data_begin
    or t0, t0, k0
    or t1, t1, k0
    or t2, t2, k1
    or t3, t3, k0
    or t4, t4, k0
    or t5, t5, k1
    or t6, t6, k0
    or t7, t7, k0
    or t8, t8, k1
    la t9, START

    /* copy .text.ebase */
1:
    lw    k0, 0(t2)
    addiu t2, t2, 4
    sw    k0, 0(t0)
    addiu t0, t0, 4
    bne   t0, t1, 1b
    nop

    /* copy .text.code */
2:
    lw    k1, 0(t5)
    addiu t5, t5, 4
    sw    k1, 0(t3)
    addiu t3, t3, 4
    bne   t3, t4, 2b
    nop

    /* copy .data */
    beq   t6, t7, 4f
    nop
3:
    lw    k0, 0(t8)
    addiu t8, t8, 4
    sw    k0, 0(t6)
    addiu t6, t6, 4
    bne   t6, t7, 3b
    nop

4:
    jr t9
    nop


    .set reorder
    .set at
