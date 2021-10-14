`include "defines.svh"

module Queue #(parameter WIDTH = 64) (
    input clk,
    input rst,

    input  logic             vinA,
    input  logic [WIDTH-1:0] inA,

    input  logic             vinB,
    input  logic [WIDTH-1:0] inB,

    input  logic             enA,
    output logic             voutA,
    output logic [WIDTH-1:0] outA,

    input  logic             enB,
    output logic             voutB,
    output logic [WIDTH-1:0] outB,

    output logic [3:0]       valids
);

  typedef struct packed {
    logic             valid;
    logic [WIDTH-1:0] data;
  } item_t;

  logic  en1,   en2,   en3,   en4;
  item_t item1, item2, item3, item4;
  item_t next1, next2, next3, next4;

  assign {voutA, outA} = item1.valid ? item1 : {vinA, inA};
  assign {voutB, outB} = item2.valid ? item2 : item1.valid ? {vinA, inA} : {vinB, inB};

  assign en1 = ~enA & ~item1.valid | enA & (~enB | item1.valid);
  assign en2 = ~enA & ~item2.valid | enA & (~enB & item1.valid | item2.valid);
  assign en3 = ~enA & (item1.valid & ~item2.valid | item2.valid & ~item3.valid) | enA & item2.valid & (~enB | item3.valid);
  assign en4 = ~enA & (item2.valid & ~item3.valid | item3.valid & ~item4.valid) | enA & item3.valid & (~enB | item4.valid);

  assign valids = {item4.valid, item3.valid, item2.valid, item1.valid};

  mux4 #(1 + WIDTH) next1_mux (
      {vinB, inB},
      {vinA, inA},
      item3,
      item2,
      {item2.valid & (~enB | item3.valid), (~enB & (~enA | item1.valid) | enB & ~item3.valid & item2.valid)},
      next1
  );
  mux4 #(1 + WIDTH) next2_mux (
      {vinB, inB},
      {vinA, inA},
      item4,
      item3,
      {item3.valid & (~enB | item4.valid), item1.valid & (~enB & (~enA | item2.valid) | enB & item3.valid & ~item4.valid)},
      next2
  );
  mux3 #(1 + WIDTH) next3_mux (
      {vinB, inB},
      {vinA, inA},
      item4,
      {~enB & item4.valid, item2.valid & (~enB & (~enA | item3.valid) | item4.valid)},
      next3
  );
  mux2 #(1 + WIDTH) next4_mux (
      {vinB, inB},
      {vinA, inA},
      ~enB & item3.valid & (~enA | item4.valid),
      next4
  );

  ffenr #(1) valid1_ff (clk, rst, next1.valid, en1, item1.valid);
  ffenr #(1) valid2_ff (clk, rst, next2.valid, en2, item2.valid);
  ffenr #(1) valid3_ff (clk, rst, next3.valid, en3, item3.valid);
  ffenr #(1) valid4_ff (clk, rst, next4.valid, en4, item4.valid);
  ffen #(WIDTH) data1_ff (clk, next1.data, en1, item1.data);
  ffen #(WIDTH) data2_ff (clk, next2.data, en2, item2.data);
  ffen #(WIDTH) data3_ff (clk, next3.data, en3, item3.data);
  ffen #(WIDTH) data4_ff (clk, next4.data, en4, item4.data);
endmodule
