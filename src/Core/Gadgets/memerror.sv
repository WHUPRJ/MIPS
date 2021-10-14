module memerror (
    input  logic  [1:0] addr,
    input  logic  [1:0] size,
    output logic        error
);

  always_comb
    casez (size)
      2'b11: begin
        error = (addr != 2'b00);
      end
      2'b10: begin
        error = 1'b0;
      end
      2'b01: begin
        error = (addr[0] != 1'b0);
      end
      2'b00: begin
        error = 1'b0;
      end
      default: begin error = 1'b1; end
    endcase
endmodule
