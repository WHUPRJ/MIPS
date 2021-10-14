module onehot_bin8 (
    input  logic [7:0] onehot,
    output logic [2:0] bin
);
  logic [1:0] bin1, bin0;
  onehot_bin4 onehot_bin4_1(onehot[7:4], bin1);
  onehot_bin4 onehot_bin4_0(onehot[3:0], bin0);
  assign bin = {|{onehot[7:4]}, bin1 | bin0};
endmodule
