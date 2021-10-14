module mux4 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] d0,
    input  logic [WIDTH-1:0] d1,
    input  logic [WIDTH-1:0] d2,
    input  logic [WIDTH-1:0] d3,
    input  logic [      1:0] s,
    output logic [WIDTH-1:0] q
);

  assign q = s[1] ? s[0] ? d3 : d2 : s[0] ? d1 : d0;

endmodule
