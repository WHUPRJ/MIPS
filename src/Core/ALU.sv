`include "defines.svh"

module ALU(
        input  word_t    a, b,
        input  aluctrl_t aluctrl,
        output word_t    aluout,
        output logic     overflow);

    wire logic alt = aluctrl.alt;

    wire logic [4:0] sa = a[4:0];
    wire logic       ex = alt & b[31];
    wire word_t      sl = b << sa;
    /* verilator lint_off WIDTH */
    wire word_t      sr = {{31{ex}}, b} >> sa;
    /* verilator lint_on WIDTH */

    wire word_t b2 = alt ? ~b : b;
    wire word_t sum;
    wire logic  lt, ltu;

    /* verilator lint_off WIDTH */
    assign {lt, ltu, sum} = {a[31], 1'b0, a} + {b2[31], 1'b1, b2} + alt; // alt for cin(CARRY4) at synthesis
    /* verilator lint_on WIDTH */
    assign aluout = (aluctrl.f_sl   ? sl                     : 32'b0)
                  | (aluctrl.f_sr   ? sr                     : 32'b0)
                  | (aluctrl.f_add  ? sum                    : 32'b0)
                  | (aluctrl.f_and  ? a & b                  : 32'b0)
                  | (aluctrl.f_or   ? alt ? ~(a | b) : a | b : 32'b0)
                  | (aluctrl.f_xor  ? a ^ b                  : 32'b0)
                  | (aluctrl.f_slt  ? {31'b0, lt }           : 32'b0)
                  | (aluctrl.f_sltu ? {31'b0, ltu}           : 32'b0)
                  | (aluctrl.f_mova ? a                      : 32'b0);
    assign overflow = lt ^ sum[31];
endmodule
