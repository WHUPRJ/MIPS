module onehot_bin4 (
    input  logic [3:0] onehot,
    output logic [1:0] bin
);
  assign bin = {onehot[3] | onehot[2], onehot[3] | onehot[1]};
endmodule
