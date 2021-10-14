`include "defines.svh"

module RF (
    input  logic       clk,
    input  logic       rst,
    input  logic [4:0] raddr1,
    input  logic [4:0] raddr2,
    input  logic [4:0] raddr3,
    input  logic [4:0] raddr4,
    input  logic       we1,
    input  logic       we2,
    input  logic [4:0] waddr1,
    input  logic [4:0] waddr2,
    input  word_t      wdata1,
    input  word_t      wdata2,
    output word_t      rdata1,
    output word_t      rdata2,
    output word_t      rdata3,
    output word_t      rdata4
);

  word_t rf[31:0];

  always_ff @(posedge clk)
    if (rst) for (int i = 0; i < 32; i = i + 1) rf[i] <= 32'b0;
    else begin
      if (we1 & waddr1 != 0) rf[waddr1] <= wdata1;
      if (we2 & waddr2 != 0) rf[waddr2] <= wdata2;
    end

  assign rdata1 = raddr1 != 0 ? rf[raddr1] : 32'b0;
  assign rdata2 = raddr2 != 0 ? rf[raddr2] : 32'b0;
  assign rdata3 = raddr3 != 0 ? rf[raddr3] : 32'b0;
  assign rdata4 = raddr4 != 0 ? rf[raddr4] : 32'b0;

endmodule
