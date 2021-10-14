`include "defines.svh"

module pcenr (
    input clk, rst,
    input word_t d,
    input logic en,
    output word_t q
);

  always_ff @(posedge clk)
    if (rst) q <= (`PCRST - 8);
    else if (en) q <= d;
endmodule
