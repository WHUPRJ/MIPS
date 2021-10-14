module extender #(
    parameter OWIDTH = 8,
    parameter IWIDTH = 8
) (
    input  logic [IWIDTH-1:0] d,
    input  logic              s,
    output logic [OWIDTH-1:0] q
);

  assign q = {{(OWIDTH - IWIDTH) {s & d[IWIDTH-1]}}, d};

endmodule
