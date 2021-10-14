module ffen #(
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] d,
    input  logic             en,
    output logic [WIDTH-1:0] q
);

  always_ff @(posedge clk) if (en) q <= d;
endmodule
