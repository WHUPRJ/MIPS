#include <regdef.h>

    .set noreorder
    .set noat


    .section .text
    .p2align 2

    .global WRITESERIAL
WRITESERIAL:
1:
    lb   v0, 5(a0)
    andi v0, v0, 0x20
    beqz v0, 1b
    nop
    sb   a1, 0(a0)
    jr   ra
    nop

    .global PRINT
PRINT:
    lb    v1, 0(a1)
1:
    lb    v0, 5(a0)
    andi  v0, v0, 0x20
    beqz  v0, 1b
    nop
    sb    v1, 0(a0)
    lb    v1, 1(a1)
    bne   v1, zero, 1b
    addiu a1, a1, 0x1
    jr    ra
    nop

    .global READSERIAL
READSERIAL:
1:
    lb   v0, 5(a0)
    andi v0, v0, 0x01
    beqz v0, 1b
    nop
    lb   v0, 0(a0)
    jr   ra
    nop

    .global TRYREADSERIAL
TRYREADSERIAL:
    lb   v1, 5(a0)
    andi v1, v1, 0x01
    beqz v1, 1f
    nop
    lb   v0, 0(a0)
1:
    jr   ra
    nop


    .set reorder
    .set at
