module onehot_bin32 (
    input  logic [31:0] onehot,
    output logic [ 4:0] bin
);
  logic [3:0] bin1, bin0;
  onehot_bin16 onehot_bin16_1(onehot[31:16], bin1);
  onehot_bin16 onehot_bin16_0(onehot[15: 0], bin0);
  assign bin = {|{onehot[31:16]}, bin1 | bin0};
endmodule
