module mux6 #(
    parameter WIDTH = 8
) (
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic [WIDTH-1:0] d2,
    input logic [WIDTH-1:0] d3,
    input logic [WIDTH-1:0] d4,
    input logic [WIDTH-1:0] d5,

    input  logic [      2:0] s,
    output logic [WIDTH-1:0] q
);

  always_comb begin
    case (s)
      3'b000:  q = d0;
      3'b001:  q = d1;
      3'b010:  q = d2;
      3'b011:  q = d3;
      3'b100:  q = d4;
      default: q = d5;
    endcase
  end
endmodule
