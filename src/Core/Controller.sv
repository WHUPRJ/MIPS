`include "defines.svh"

module Controller (
    input  word_t       inst,
    input  logic        eq,
    input  logic        ltz,
    input  word_t       rt,
    output Ctrl_t       ctrl,
    output word_t       imm,
    output logic  [4:0] sa
);

  assign ctrl.RS = inst[25:21];
  assign ctrl.RT = inst[20:16];
  mux3 #(5) RD_mux (
      inst[15:11],
      5'b11111,
      ctrl.RT,
      {~inst[29] & inst[30] | inst[29] & ~inst[30] | inst[31], inst[26]},
      ctrl.RD
  );

  assign sa = inst[10:6];
  mux3 #(32) imm_mux (
      {16'b0, inst[15:0]},
      {{16{inst[15]}}, inst[15:0]},
      {inst[15:0], 16'b0},
      {~inst[31] & inst[28] & inst[27] & inst[26], inst[31] | ~inst[28]},
      imm
  );

  assign ctrl.BJRJ = ~inst[26] & (~inst[27] & (~inst[28] & ~inst[30] & ~inst[31] & ~inst[29] & inst[3] & ~inst[1] & ~inst[4] & ~inst[2] | inst[28] & ~inst[29] & ~inst[31]) | inst[27] & ~inst[31] & ~inst[29]) | inst[26] & ~inst[31] & ~inst[29] & (~inst[19] | inst[27] | inst[28]);
  assign ctrl.B    = ~inst[26] & inst[28] & ~inst[29] & ~inst[31] | inst[26] & ~inst[31] & ~inst[29] & (~inst[27] & ~inst[19] | inst[28]);
  assign ctrl.JR   = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[4] & inst[3] & ~inst[2] & ~inst[1];
  assign ctrl.J    = ~inst[31] & ~inst[29] & ~inst[28] & inst[27];
  // Take Care of BGO
  assign ctrl.BGO  = ~inst[26] & (eq | inst[27] & ltz) | inst[26] & (~inst[27] & (~inst[28] & (inst[16] & ~ltz | ~inst[16] & ltz) | inst[28] & ~eq) | inst[27] & ~eq & ~ltz);

  assign ctrl.PRV     = ~inst[31] & inst[30] & ~inst[29];
  assign ctrl.SYSCALL = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[3] & inst[2] & ~inst[0];
  assign ctrl.BREAK   = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[3] & inst[2] & ~inst[1] & inst[0];
  assign ctrl.ERET    = ~inst[31] & inst[30] & inst[4];
  assign ctrl.OFA     = ~inst[26] & ~inst[30] & (~inst[29] & ~inst[31] & ~inst[28] & ~inst[27] & inst[5] & ~inst[0] & ~inst[4] & ~inst[2] & ~inst[3] | inst[29] & ~inst[27] & ~inst[31] & ~inst[28]);

  assign ctrl.ES = ~inst[30] & (~inst[28] & ~inst[27] & (~inst[26] & (~inst[3] & inst[2] | inst[3] & (inst[1] | inst[4]) | inst[5]) | inst[26] & inst[19]) | inst[31]) | inst[29];
  assign ctrl.ET = ~inst[26] & ~inst[27] & ~inst[31] & (~inst[30] & ~inst[29] & ~inst[28] & (~inst[3] & ~inst[4] | inst[3] & inst[4] | inst[5]) | inst[30] & inst[29]);
  assign ctrl.DS = ~inst[26] & (~inst[28] & ~inst[30] & ~inst[31] & ~inst[29] & ~inst[27] & inst[3] & ~inst[1] & ~inst[4] & ~inst[2] | inst[28] & ~inst[29] & ~inst[31]) | inst[26] & ~inst[31] & ~inst[29] & (~inst[27] & ~inst[19] | inst[28]);
  assign ctrl.DT = ~inst[28] & ~inst[26] & ~inst[30] & ~inst[31] & ~inst[29] & ~inst[27] & inst[3] & inst[1] & ~inst[5] & ~inst[4] | inst[28] & ~inst[29] & ~inst[31] & ~inst[27];

  assign ctrl.DP0 = ~inst[31] & (~inst[30] & (~inst[26] & (~inst[4] | ~inst[5] | inst[27] | inst[28]) | inst[26] & (~inst[19] | inst[27] | inst[28])) | inst[30] & (~inst[25] | inst[4]) | inst[29]) | inst[31] & inst[30];
  assign ctrl.DP1 = ~inst[30] & (~inst[4] | inst[5] | inst[28] | inst[29] | inst[31] | inst[27] | inst[26]) | inst[30] & ~inst[29] & (inst[25] | inst[31]);

  assign ctrl.ECtrl.OP.f_sl   = ~inst[31] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & ~inst[3] & ~inst[1];
  assign ctrl.ECtrl.OP.f_sr   = ~inst[31] & ~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & ~inst[5] & ~inst[3] & inst[1];
  assign ctrl.ECtrl.OP.f_add  = (~inst[28] & (~inst[26] & ~inst[27] & ((~inst[5] & inst[3] & ~inst[1] | inst[5] & (~inst[0] & (~inst[2] & ~inst[4] & ~inst[3] | inst[2] & inst[4]) | inst[0] & ~inst[2] & ~inst[4] & ~inst[3])) | inst[29]) | inst[26] & (~inst[29] & ((~inst[16] & (inst[20] | inst[18]) | inst[16] & inst[20]) | inst[27]) | inst[29] & ~inst[27])) | inst[31]);
  assign ctrl.ECtrl.OP.f_and  = ~inst[31] & (~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & inst[5] & ~inst[0] & inst[2] & ~inst[4] & ~inst[1] | inst[28] & ~inst[27] & ~inst[26]);
  assign ctrl.ECtrl.OP.f_or   = ~inst[31] & (~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & inst[5] & inst[2] & inst[0] | inst[28] & ~inst[27] & inst[26]);
  assign ctrl.ECtrl.OP.f_xor  = ~inst[31] & (~inst[28] & ~inst[26] & ~inst[27] & ~inst[29] & inst[5] & ~inst[0] & inst[2] & ~inst[4] & inst[1] | inst[28] & inst[27]);
  assign ctrl.ECtrl.OP.f_slt  = ~inst[31] & ~inst[28] & (~inst[26] & (~inst[29] & inst[5] & ~inst[0] & ~inst[2] & (inst[3] | inst[4]) | inst[27]) | inst[26] & ~inst[29] & ~inst[27] & ~inst[16] & ~inst[18] & ~inst[20]);
  assign ctrl.ECtrl.OP.f_sltu = ~inst[31] & ~inst[28] & (~inst[26] & ~inst[27] & ~inst[29] & inst[5] & inst[0] & ~inst[2] & (inst[3] | inst[4]) | inst[26] & (~inst[29] & ~inst[27] & inst[16] & ~inst[20] | inst[29] & inst[27]));
  assign ctrl.ECtrl.OP.f_mova = ~inst[31] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & inst[3] & inst[1];
  assign ctrl.ECtrl.OP.alt    = ~inst[31] & ~inst[28] & (~inst[29] & ~inst[27] & (~inst[26] & (inst[1] & (inst[0] | inst[5]) | inst[4]) | inst[26] & ~inst[20]) | inst[29] & inst[27]);

  assign ctrl.ECtrl.SA = SA_t'({(~inst[27] & (~inst[26] & ((inst[3] & inst[1] | inst[2]) | inst[5]) | inst[26] & ~inst[20]) | inst[31]) | inst[29], (~inst[28] & (inst[2] | inst[3] | inst[5] | inst[29] | inst[26]) | inst[28] & (~inst[27] | ~inst[26])) | inst[31]});
  assign ctrl.ECtrl.SB = SB_t'({(inst[26] & ~inst[27] & ~inst[20] | inst[31]) | inst[29], inst[3] & ~inst[5] | inst[26]});

  assign ctrl.MCtrl0.HW  = ~inst[30] & ~inst[26] & ~inst[29] & ~inst[28] & ~inst[27] & inst[4] & (~inst[5] & ~inst[1] & inst[0] | inst[3]) | inst[30] & inst[29] & ~inst[1];
  assign ctrl.MCtrl0.LW  = ~inst[30] & ~inst[26] & ~inst[29] & ~inst[28] & ~inst[27] & inst[4] & (~inst[5] & inst[1] & inst[0] | inst[3]) | inst[30] & inst[29] & ~inst[1];
  assign ctrl.MCtrl0.HLS = HLS_t'({(~inst[30] & ~inst[26] & ~inst[27] & ~inst[31] & ~inst[29] & ~inst[28] & inst[4] & inst[3] | inst[30] & inst[29]), inst[1] & ~inst[30], inst[0]});
  assign ctrl.MCtrl0.MAS = MAS_t'({inst[2], inst[30] & ~inst[2] & ~inst[1]});
  assign ctrl.MCtrl0.C0D = inst[15:11];
  assign ctrl.MCtrl0.C0W = ~inst[31] & inst[30] & ~inst[29] & inst[23] & ~inst[3];
  assign ctrl.MCtrl0.SEL = inst[2:0];
  assign ctrl.MCtrl0.RS0 = RS0_t'({~inst[30] & (~inst[4] | inst[5] | inst[29] | inst[26]), inst[30], ~inst[29] & (~inst[1] | inst[30])});

  assign ctrl.MCtrl1.MR       = inst[31] & ~inst[30];
  assign ctrl.MCtrl1.MWR      = inst[29];
  assign ctrl.MCtrl1.MX       = ~inst[28];
  assign ctrl.MCtrl1.ALR      = ALR_t'({inst[28] & inst[27] & ~inst[26], ~inst[28] & inst[27] & ~inst[26]});
  assign ctrl.MCtrl1.SZ       = inst[27:26];
  assign ctrl.MCtrl1.TLBR     = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & ~inst[1];
  assign ctrl.MCtrl1.TLBWI    = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & inst[1];
  assign ctrl.MCtrl1.TLBWR    = ~inst[31] & inst[30] & ~inst[29] & inst[25] & ~inst[3] & (inst[2] | ~inst[1]);
  assign ctrl.MCtrl1.TLBP     = ~inst[31] & inst[30] & ~inst[4] & inst[3];
  assign ctrl.MCtrl1.CACHE_OP = CacheOp_t'({inst[29] & inst[28] & inst[26] & inst[16], inst[29] & inst[28] & inst[26] & ~inst[20], inst[29] & inst[28] & inst[26] & ~inst[18] & (inst[20] | inst[19] | ~inst[16])});

  assign ctrl.Trap.TEN = ~inst[30] & ~inst[27] & (~inst[26] & ~inst[31] & ~inst[29] & ~inst[28] & inst[4] & inst[5] | inst[26] & ~inst[31] & ~inst[29] & ~inst[28] & inst[19]) | inst[30] & ~inst[29] & ~inst[31];
  assign ctrl.Trap.TP  = TrapOp_t'({~inst[26] & inst[2] | inst[26] & inst[18], ~inst[26] & inst[1] | inst[26] & inst[17]});

  logic mov, rw, eqz;
  assign mov = ~inst[31] & ~inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[5] & ~inst[4] & inst[3] & ~inst[2] & inst[1];
  assign rw  = ~inst[30] & (~inst[26] & (~inst[27] & (~inst[31] & (~inst[28] & (~inst[4] & (~inst[3] | ~inst[2] & (inst[0] | inst[1])) | inst[4] & ~inst[5] & ~inst[3] & ~inst[0]) | inst[29]) | inst[31] & ~inst[29]) | inst[27] & (~inst[31] & inst[29] | inst[31] & ~inst[29])) | inst[26] & (~inst[29] & (~inst[27] & ~inst[28] & inst[20] | inst[27] & ~inst[28] | inst[31]) | inst[29] & ~inst[31])) | inst[30] & ~inst[31] & ~inst[3] & (~inst[29] & ~inst[25] & ~inst[23] | inst[29] & inst[1]);
  assign eqz = rt == 32'h0;
  assign ctrl.WCtrl.RW = ctrl.RD != 5'b00000 & (~mov | ~inst[0] & eqz | inst[0] & ~eqz) & rw;

endmodule
