module ffenr #(
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] d,
    input  logic             en,
    output logic [WIDTH-1:0] q
);

  always_ff @(posedge clk)
    if (rst) q <= {WIDTH{1'b0}};
    else if (en) q <= d;
endmodule
