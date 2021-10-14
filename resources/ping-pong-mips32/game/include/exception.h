#ifndef EXCEPTION_H
#define EXCEPTION_H

#define EX_MASK     0xFC
#define EX_INT      (0x00 << 2)
#define EX_MOD      (0x01 << 2)
#define EX_TLBL     (0x02 << 2)
#define EX_TLBS     (0x03 << 2)
#define EX_ADEL     (0x04 << 2)
#define EX_ADES     (0x05 << 2)
#define EX_SYS      (0x08 << 2)
#define EX_BP       (0x09 << 2)
#define EX_RI       (0x0A << 2)
#define EX_OV       (0x0C << 2)

#define TF_SIZE     0xA4
#define TF_INTHDL0  0x00
#define TF_INTHDL1  0x04
#define TF_INTHDL2  0x08
#define TF_INTHDL3  0x0C
#define TF_INTHDL4  0x10
#define TF_INTHDL5  0x14
#define TF_INTHDL6  0x18
#define TF_INTHDL7  0x1C
#define TF_AT       0x20
#define TF_v0       0x24
#define TF_v1       0x28
#define TF_a0       0x2C
#define TF_a1       0x30
#define TF_a2       0x34
#define TF_a3       0x38
#define TF_t0       0x3C
#define TF_t1       0x40
#define TF_t2       0x44
#define TF_t3       0x48
#define TF_t4       0x4C
#define TF_t5       0x50
#define TF_t6       0x54
#define TF_t7       0x58
#define TF_s0       0x5C
#define TF_s1       0x60
#define TF_s2       0x64
#define TF_s3       0x68
#define TF_s4       0x6C
#define TF_s5       0x70
#define TF_s6       0x74
#define TF_s7       0x78
#define TF_t8       0x7C
#define TF_t9       0x80
#define TF_gp       0x84
#define TF_sp       0x88
#define TF_fp       0x8C
#define TF_ra       0x90
#define TF_COUNT    0x94
#define TF_COMPARE  0x98
#define TF_STATUS   0x9C
#define TF_EPC      0xA0

#endif
