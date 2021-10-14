module onehot_bin16 (
    input  logic [15:0] onehot,
    output logic [ 3:0] bin
);
  logic [2:0] bin1, bin0;
  onehot_bin8 onehot_bin8_1(onehot[15:8], bin1);
  onehot_bin8 onehot_bin8_0(onehot[ 7:0], bin0);
  assign bin = {|{onehot[15:8]}, bin1 | bin0};
endmodule
