module prio_mux5 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] d0,
    input  logic [WIDTH-1:0] d1,
    input  logic [WIDTH-1:0] d2,
    input  logic [WIDTH-1:0] d3,
    input  logic [WIDTH-1:0] d4,
    input  logic [      3:0] s,
    output logic [WIDTH-1:0] q
);

  assign q = s[3] ? d4 : s[2] ? d3 : s[1] ? d2 : s[0] ? d1 : d0;

endmodule
