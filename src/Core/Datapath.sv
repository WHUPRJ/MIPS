`include "defines.svh"
`include "CP0.svh"
`include "ICache.svh"
`include "DCache.svh"

module Datapath (
    input  clk,
    input  rst,

    // MMU
    sramro_i.master  fetch_i,
    sram_i.master    mem_i,
    output CacheOp_t cache_op,
    input  logic     iTLBRefill,
    input  logic     iTLBInvalid,
    input  logic     iAddressError,
    input  logic     dTLBRefill,
    input  logic     dTLBInvalid,
    input  logic     dTLBModified,
    input  logic     dAddressError,
    output logic     tlb_tlbwi,
    output logic     tlb_tlbwr,
    output logic     tlb_tlbp,
    output logic     c0_tlbr,
    output logic     c0_tlbp,

    // CP0
    input  logic        C0_int,
    output logic [4:0]  C0_addr,
    output logic [2:0]  C0_sel,
    input  word_t       C0_rdata,
    output logic        C0_we,
    output word_t       C0_wdata,
    output EXCEPTION_t  C0_exception,
    input  word_t       C0_ERETPC,
    input  logic        C0_Bev,
    input  logic [19:0] C0_EBase,
    input  logic        C0_kernel,

    //debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,

    output wire [31:0] debug_wb1_pc,
    output wire [ 3:0] debug_wb1_rf_wen,
    output wire [ 4:0] debug_wb1_rf_wnum,
    output wire [31:0] debug_wb1_rf_wdata,

    output wire        debug_wb_pc_A
);

  logic rstD, rstM;

  PF_t          PF;
  F_t           F;
  D_t           D;
  E_t           E;
  M_t           M;
  W_t           W;

  // Pre Fetch
  logic         PF_go;

  word_t        PF_pcp8;
  word_t        PF_pcb;
  word_t        PF_pcj;
  word_t        PF_pcjr;
  word_t        PF_pc0;

  // Instr Queue
  logic         IQ_IA_valid;
  word_t        IQ_IA_inst;
  word_t        IQ_IA_pc;

  logic         IQ_IB_valid;
  word_t        IQ_IB_inst;
  word_t        IQ_IB_pc;

  logic         IQ_IA_TLBRefill;
  logic         IQ_IA_TLBInvalid;
  logic         IQ_IA_AddressError;
  logic         IQ_IB_TLBRefill;
  logic         IQ_IB_TLBInvalid;
  logic         IQ_IB_AddressError;

  logic   [3:0] IQ_valids;

  // Decode
  logic         D_readygo;
  logic         D_readygo1;
  logic         D_IA_can_dispatch;
  logic         D_IB_can_dispatch;
  logic         D_go;
  logic         D_IA_go;
  logic         D_IB_go;
  logic         D_I0_go;
  logic         D_I1_go;

  logic         D_IA_FS_M_I0;
  logic         D_IA_FS_M_I1;
  logic         D_IA_FS_W_I0;
  logic         D_IA_FS_W_I1;
  word_t        D_IA_ForwardS;

  logic         D_IA_FT_M_I0;
  logic         D_IA_FT_M_I1;
  logic         D_IA_FT_W_I0;
  logic         D_IA_FT_W_I1;
  word_t        D_IA_ForwardT;

  logic         D_IB_FS_M_I0;
  logic         D_IB_FS_M_I1;
  logic         D_IB_FS_W_I0;
  logic         D_IB_FS_W_I1;
  word_t        D_IB_ForwardS;

  logic         D_IB_FT_M_I0;
  logic         D_IB_FT_M_I1;
  logic         D_IB_FT_W_I0;
  logic         D_IB_FT_W_I1;
  word_t        D_IB_ForwardT;

  logic         D_IA_valid;
  logic         D_IB_valid;
  logic         D_IA_iv;
  logic         D_IB_iv;

  logic         D_IA_TLBRefill;
  logic         D_IA_TLBInvalid;
  logic         D_IA_AddressError;
  logic         D_IB_TLBRefill;
  logic         D_IB_TLBInvalid;
  logic         D_IB_AddressError;

  logic         D_IA_Hazard;
  logic         D_IB_Hazard;

  // Execute
  logic         E_valid;
  logic         E_go;
  logic         E_I0_go;
  logic         E_I1_go;
  logic         E_I1_goWithoutOF;

  word_t        E_I0_A;
  word_t        E_I0_B;
  logic         E_I0_Overflow;
  logic         E_I0_NowExcValid;
  logic         E_I0_NowExcValidWithoutOF;
  logic         E_I0_PrevExcValid;
  logic   [4:0] E_I0_PrevExcCode;
  logic         E_I0_PrevERET;
  logic         E_I0_PrevREFILL;
  logic         E_I0_ExcValidWithoutOF;

  word_t        E_I1_A;
  word_t        E_I1_B;
  word_t        E_I1_ADDR;
  logic         E_I1_Overflow;
  logic         E_I1_STRBERROR;
  logic         E_I1_NowExcValid;
  logic         E_I1_NowExcValidWithoutOF;
  logic         E_I1_PrevExcValid;
  logic   [4:0] E_I1_PrevExcCode;
  logic         E_I1_PrevERET;
  logic         E_I1_PrevREFILL;
  logic         E_I1_ExcValidWithoutOF;

  logic         E_I0_FS_M_I0;
  logic         E_I0_FS_M_I1;
  logic         E_I0_FS_W_I0;
  logic         E_I0_FS_W_I1;
  word_t        E_I0_ForwardS;

  logic         E_I0_FT_M_I0;
  logic         E_I0_FT_M_I1;
  logic         E_I0_FT_W_I0;
  logic         E_I0_FT_W_I1;
  word_t        E_I0_ForwardT;

  logic         E_I1_FS_M_I0;
  logic         E_I1_FS_M_I1;
  logic         E_I1_FS_W_I0;
  logic         E_I1_FS_W_I1;
  word_t        E_I1_ForwardS;

  logic         E_I1_FT_M_I0;
  logic         E_I1_FT_M_I1;
  logic         E_I1_FT_W_I0;
  logic         E_I1_FT_W_I1;
  word_t        E_I1_ForwardT;

  // Memory
  logic         M_go;
  logic         M_I0_go;
  logic         M_I1_go;

  logic         dTLBExcValid;
  logic         dTLBRefillB;
  logic         dTLBInvalidB;
  logic         dTLBModifiedB;
  logic         dAddressErrorB;
  EXCEPTION_t   M_exception;
  logic         M_exception_REFILL;

  logic  [ 7:0] M_I1_Byte;
  logic  [15:0] M_I1_Half;
  word_t        M_I1_ByteX;
  word_t        M_I1_HalfX;
  word_t        M_I1_MDataA;
  word_t        M_I1_MDataUL;
  word_t        M_I1_MDataUR;
  word_t        M_I1_MData;

  logic         M_I0_DIV_valid;
  word_t        M_I0_DIVH;
  word_t        M_I0_DIVL;
  logic         M_I0_DIVU_valid;
  word_t        M_I0_DIVUH;
  word_t        M_I0_DIVUL;

  logic         M_I0_DIV_bvalid;
  word_t        M_I0_DIVHB;
  word_t        M_I0_DIVLB;
  logic         M_I0_DIVU_bvalid;
  word_t        M_I0_DIVUHB;
  word_t        M_I0_DIVULB;

  logic   [5:0] M_I0_MULT_CNTR;

  word_t        M_I0_MULTH;
  word_t        M_I0_MULTL;
  word_t        M_I0_MULTUH;
  word_t        M_I0_MULTUL;

  word_t        M_I0_MULTHF;
  word_t        M_I0_MULTLF;
  word_t        M_I0_MULTUHF;

  logic         M_I0_MAS_bvalid;
  word_t        M_I0_MASH;
  word_t        M_I0_MASL;
  word_t        M_I0_MUASH;
  word_t        M_I0_MUASL;

  logic         M_I0_MULT_bvalid;
  word_t        M_I0_MULTLB;
  word_t        M_I0_MULTHB;
  word_t        M_I0_MULTUHB;

  word_t        M_I0_HI;
  word_t        M_I0_LO;

  logic         M_I1_Trap;
  logic         M_I1_NowExcValid;
  logic         M_I1_PrevExcValid;
  logic   [4:0] M_I1_PrevExcCode;
  logic         M_I1_PrevREFILL;

  logic         M_I0_FS_M_I1;
  logic         M_I0_FS_W_I0;
  logic         M_I0_FS_W_I1;
  word_t        M_I0_ForwardS;

  logic         M_I0_FT_M_I1;
  logic         M_I0_FT_W_I0;
  logic         M_I0_FT_W_I1;
  word_t        M_I0_ForwardT;

  logic         M_I1_FT_M_I0;
  logic         M_I1_FT_W_I0;
  logic         M_I1_FT_W_I1;
  word_t        M_I1_ForwardT;

  logic         M_I1_DataR_OK;
  word_t        M_I1_DataR;

  word_t        HI;
  word_t        LO;

  //---------------------------------------------------------------------------//
  //                                 Pre Fetch                                 //
  //---------------------------------------------------------------------------//

  assign PF_pcp8 = {F.pc[31:3] + 1'b1, 3'b0};
  assign PF_pcb  = {D.IB_pc[31:2] + {{14{D.IA_inst[15]}}, D.IA_inst[15:0]}, 2'b0};
  assign PF_pcjr = D_IA_ForwardS;
  assign PF_pcj  = {D.IB_pc[31:28], D.IA_inst[25:0], 2'b0};
  assign PF_pc0  = (D.IA.B  ? PF_pcb  : 32'b0)
                 | (D.IA.JR ? PF_pcjr : 32'b0)
                 | (D.IA.J  ? PF_pcj  : 32'b0);
  prio_mux5 #(32) PF_pc_mux (
      PF_pc0,
      PF_pcp8,
      {C0_Bev ? 23'h5fe001 : {C0_EBase, 3'h0}, `Off_GExc},
      {C0_Bev ? 23'h5fe001 : {C0_EBase, 3'h0}, `Off_TRef},
      C0_ERETPC,
      {M_exception.ERET, M_exception_REFILL, M_exception.ExcValid, ~D_IB_valid | ~D.IA.BJRJ | D.IA.B & ~D.IA.BGO},
      PF.pc
  );

  assign rstD = D_IA_valid & (D.IA.B & D.IA.BGO | D.IA.JR | D.IA.J) & D_IB_valid & D_readygo;
  assign rstM = C0_exception.ExcValid;

  assign PF_go = ~D.IA_ExcValid & ~D.IB_ExcValid & ~E_I0_ExcValidWithoutOF & ~E_I1_ExcValidWithoutOF
               & (~D_IB_valid | ~D.IA.JR | PF_pcjr[1:0] == 2'b00);
  assign fetch_i.req = M_exception.ExcValid
    | PF_go & (~D_IB_valid & ~fetch_i.data_ok | (~D.IA.BJRJ | D_readygo)
      & (rstD
         | ~IQ_valids[0]
         | ~IQ_valids[1] & (~fetch_i.data_ok | PF.pc[2] | F.pc[2] | D_readygo)
         | ~IQ_valids[2] & (~fetch_i.data_ok | PF.pc[2] & (F.pc[2] | D_readygo) | F.pc[2] & D_readygo | D_readygo & D_readygo1)
         | ~IQ_valids[3] & (~fetch_i.data_ok & (PF.pc[2] | D_readygo) | PF.pc[2] & (F.pc[2] & D_readygo | D_readygo & D_readygo1) | F.pc[2] & D_readygo & D_readygo1)
         |  IQ_valids[3] & (~fetch_i.data_ok & (PF.pc[2] & D_readygo | D_readygo & D_readygo1) | PF.pc[2] & F.pc[2] & D_readygo & D_readygo1)));
  assign fetch_i.addr = {PF.pc[31:3], 3'b000};

  //---------------------------------------------------------------------------//
  //                                Fetch Stage                                //
  //---------------------------------------------------------------------------//

  // F.FF
  pcenr F_pc_ff (
      clk,
      rst,
      PF.pc,
      F.en,
      F.pc
  );

  assign F.en = PF.pc[1:0] != 2'b00 & D_IA_can_dispatch | fetch_i.req & fetch_i.addr_ok;

  assign F.ExcValid = F.pc[1:0] != 2'b00 | iTLBRefill | iTLBInvalid | iAddressError;

  //---------------------------------------------------------------------------//
  //                                Instr Queue                                //
  //---------------------------------------------------------------------------//

  Queue #(67) InstrQueue (
      .clk(clk),
      .rst(rst | rstD | rstM),

      .vinA(fetch_i.data_ok | F.ExcValid),
      .inA ({F.pc[2] ? fetch_i.rdata1 : fetch_i.rdata0, F.pc,
             iTLBRefill, iTLBInvalid, iAddressError}),

      .vinB(fetch_i.data_ok & ~F.pc[2]),
      .inB ({fetch_i.rdata1, F.pc[31:3], 3'b100, 3'b00}),

      .enA  (D.en0),
      .voutA(IQ_IA_valid),
      .outA ({IQ_IA_inst, IQ_IA_pc, IQ_IA_TLBRefill, IQ_IA_TLBInvalid, IQ_IA_AddressError}),

      .enB  (D.en1),
      .voutB(IQ_IB_valid),
      .outB ({IQ_IB_inst, IQ_IB_pc, IQ_IB_TLBRefill, IQ_IB_TLBInvalid, IQ_IB_AddressError}),

      .valids(IQ_valids)
  );

  //---------------------------------------------------------------------------//
  //                               Decode  Stage                               //
  //---------------------------------------------------------------------------//

  // D.FF
  ffenr #(1 + 32 + 32 + 3) D_IA_ff (
      clk,
      rst | rstM,
      D.en1 ? {IQ_IA_valid & ~rstD, IQ_IA_pc, IQ_IA_inst, IQ_IA_TLBRefill, IQ_IA_TLBInvalid, IQ_IA_AddressError}
            : {D_IB_valid, D.IB_pc, D.IB_inst, D_IB_TLBRefill, D_IB_TLBInvalid, D_IB_AddressError},
      ~D_IA_valid | D_go & E.en,
      {D_IA_valid, D.IA_pc, D.IA_inst, D_IA_TLBRefill, D_IA_TLBInvalid, D_IA_AddressError}
  );
  ffenr #(1 + 32 + 32 + 3) D_IB_ff (
      clk,
      rst | rstM,
      D.en1 ? {IQ_IB_valid & ~rstD, IQ_IB_pc, IQ_IB_inst, IQ_IB_TLBRefill, IQ_IB_TLBInvalid, IQ_IB_AddressError}
            : {IQ_IA_valid & ~rstD, IQ_IA_pc, IQ_IA_inst, IQ_IA_TLBRefill, IQ_IA_TLBInvalid, IQ_IA_AddressError},
      D.en0,
      {D_IB_valid, D.IB_pc, D.IB_inst, D_IB_TLBRefill, D_IB_TLBInvalid, D_IB_AddressError}
  );

  ffenr #(1) D_IA_Delay_ff (
      clk,
      rst | rstM,
      D.en1 ? 1'b0 : D.IB_Delay,
      ~D_IA_valid | D_go & E.en,
      D.IA_Delay
  );

  // Register File
  RF RegisterFile (
      .clk(clk),
      .rst(rst),
      .raddr1(D.IA.RS),
      .raddr2(D.IA.RT),
      .raddr3(D.IB.RS),
      .raddr4(D.IB.RT),
      .we1(W.I0.WCtrl.RW & ( W.A | ~W.I1.WCtrl.RW | W.I0.RD != W.I1.RD)),
      .we2(W.I1.WCtrl.RW & (~W.A | ~W.I0.WCtrl.RW | W.I0.RD != W.I1.RD)),
      .waddr1(W.I0.RD),
      .waddr2(W.I1.RD),
      .wdata1(W.I0.RDataW),
      .wdata2(W.I1.RDataW),
      .rdata1(D.IA_S),
      .rdata2(D.IA_T),
      .rdata3(D.IB_S),
      .rdata4(D.IB_T)
  );

  assign debug_wb_pc_A = W.A;

  assign debug_wb_rf_wen   = {4{W.I0.WCtrl.RW}};
  assign debug_wb_rf_wnum  = W.I0.RD;
  assign debug_wb_rf_wdata = W.I0.RDataW;

  assign debug_wb1_rf_wen   = {4{W.I1.WCtrl.RW}};
  assign debug_wb1_rf_wnum  = W.I1.RD;
  assign debug_wb1_rf_wdata = W.I1.RDataW;

`ifndef SIMULATION_PC
  assign debug_wb_pc  = 32'hFFFFFFFF;
  assign debug_wb1_pc = 32'hFFFFFFFF;
`else
  assign debug_wb_pc  = W.I0.pc;
  assign debug_wb1_pc = W.I1.pc;
`endif

  // D.Decode
  Controller D_IA_ctrl (
      .inst(D.IA_inst),
      .eq  (D_IA_ForwardS == D_IA_ForwardT),
      .ltz (D_IA_ForwardS[31]),
      .rt  (D_IA_ForwardT),
      .ctrl(D.IA),
      .imm (D.IA_imm),
      .sa  (D.IA_sa)
  );
  Controller D_IB_ctrl (
      .inst(D.IB_inst),
      .eq  (D_IB_ForwardS == D_IB_ForwardT),
      .ltz (D_IB_ForwardS[31]),
      .rt  (D_IB_ForwardT),
      .ctrl(D.IB),
      .imm (D.IB_imm),
      .sa  (D.IB_sa)
  );

  // D.Exc
  instr_valid D_IA_instr_valid (
      D.IA_inst,
      D_IA_iv
  );
  instr_valid D_IB_instr_valid (
      D.IB_inst,
      D_IB_iv
  );

  // INFO: Merge "pc[1:0] != 2'b00" into AddressError
  assign D.IA_ExcValid = D_IA_valid & ( D.IA_pc[1:0] != 2'b00
                                      | ~D_IA_iv
                                      | D_IA_TLBRefill | D_IA_TLBInvalid
                                      | D_IA_AddressError
                                      | D.IA.SYSCALL | D.IA.BREAK | D.IA.ERET
                                      | D.IA.PRV & ~C0_kernel);
  assign D.IA_ERET     = D_IA_valid & D.IA_pc[1:0] == 2'b00 & ~D_IA_TLBRefill & ~D_IA_TLBInvalid & ~D_IA_AddressError & D_IA_iv & D.IA.ERET;
  assign D.IA_REFILL   = D_IA_valid & D.IB_pc[1:0] == 2'b00 & D_IA_TLBRefill;
  assign D.IA_ExcCode  = D.IA_pc[1:0] != 2'b00 | D_IA_AddressError ? `EXCCODE_ADEL
                       : D_IA_TLBRefill                            ? `EXCCODE_TLBL
                       : D_IA_TLBInvalid                           ? `EXCCODE_TLBL
                       : ~D_IA_iv                                  ? `EXCCODE_RI
                       : ~D.IA_inst[30] & D.IA_inst[0]             ? `EXCCODE_BP
                       : ~D.IA_inst[30] & ~D.IA_inst[0]            ? `EXCCODE_SYS
                       : `EXCCODE_CPU;

  assign D.IB_ExcValid = D_IB_valid & ( D.IB_pc[1:0] != 2'b00
                                      | ~D_IB_iv
                                      | D_IB_TLBRefill | D_IB_TLBInvalid
                                      | D_IB_AddressError
                                      | D.IB.SYSCALL | D.IB.BREAK | D.IB.ERET
                                      | D.IB_Delay & D.IB.BJRJ
                                      | D.IB.PRV & ~C0_kernel);
  assign D.IB_ERET     = D_IB_valid & D.IB_pc[1:0] == 2'b00 & ~D_IB_TLBRefill & ~D_IB_TLBInvalid & ~D_IB_AddressError & D_IB_iv & D.IB.ERET & ~D.IB_Delay;
  assign D.IB_REFILL   = D_IB_valid & D.IB_pc[1:0] == 2'b00 & D_IB_TLBRefill;
  // EXCCODE_BP and EXCCODE_SYSCALL -> exc.txt
  assign D.IB_ExcCode  = D.IB_pc[1:0] != 2'b00 | D_IB_AddressError  ? `EXCCODE_ADEL
                       : D_IB_TLBRefill                             ? `EXCCODE_TLBL
                       : D_IB_TLBInvalid                            ? `EXCCODE_TLBL
                       : ~D_IB_iv                                   ? `EXCCODE_RI
                       : D.IB.ERET                                  ? `EXCCODE_RI
                       : D.IB_Delay & D.IB.BJRJ                     ? `EXCCODE_RI
                       : ~D.IB_inst[30] & D.IB_inst[0]              ? `EXCCODE_BP
                       : ~D.IB_inst[30] & ~D.IB_inst[0]             ? `EXCCODE_SYS
                       : `EXCCODE_CPU;
  assign D.IB_Delay    = D.IA.BJRJ;

  // D.Dispatch
                // Not Arith -> Arith
  assign D_IA_Hazard = E.I0.WCtrl.RW & D.IA.RS == E.I0.RD & D.IA.ES & ~E.I0.MCtrl.RS0[2]
                     | E.I0.WCtrl.RW & D.IA.RT == E.I0.RD & D.IA.ET & ~E.I0.MCtrl.RS0[2]
                // Load -> Arith
                     | E.I1.WCtrl.RW & D.IA.RS == E.I1.RD & D.IA.ES & E.I1.MCtrl.MR
                     | E.I1.WCtrl.RW & D.IA.RT == E.I1.RD & D.IA.ET & E.I1.MCtrl.MR
                // Arith -> B / JR
                     | E.I0.WCtrl.RW & D.IA.RS == E.I0.RD & D.IA.DS
                     | E.I0.WCtrl.RW & D.IA.RT == E.I0.RD & D.IA.DT
                     | E.I1.WCtrl.RW & D.IA.RS == E.I1.RD & D.IA.DS
                     | E.I1.WCtrl.RW & D.IA.RT == E.I1.RD & D.IA.DT
                // Not Arith -> B / JR
                     | M.I0.WCtrl.RW & D.IA.RS == M.I0.RD & D.IA.DS & ~M.I0.MCtrl.RS0[2]
                     | M.I0.WCtrl.RW & D.IA.RT == M.I0.RD & D.IA.DT & ~M.I0.MCtrl.RS0[2]
                // Load -> B / JR
                     | M.I1.WCtrl.RW & D.IA.RS == M.I1.RD & D.IA.DS & M.I1.MCtrl.MR
                     | M.I1.WCtrl.RW & D.IA.RT == M.I1.RD & D.IA.DT & M.I1.MCtrl.MR
                // CP0 Execution Hazards
                // Hazards Related to the TLB
                     | E.I0.MCtrl.C0W & D.IA.MCtrl1.TLBP & E.I0.MCtrl.C0D == C0_ENTRYHI
                ;

                // Not Arith -> Arith
  assign D_IB_Hazard = E.I0.WCtrl.RW & D.IB.RS == E.I0.RD & D.IB.ES & ~E.I0.MCtrl.RS0[2]
                     | E.I0.WCtrl.RW & D.IB.RT == E.I0.RD & D.IB.ET & ~E.I0.MCtrl.RS0[2]
                // Load -> Arith
                     | E.I1.WCtrl.RW & D.IB.RS == E.I1.RD & D.IB.ES & E.I1.MCtrl.MR
                     | E.I1.WCtrl.RW & D.IB.RT == E.I1.RD & D.IB.ET & E.I1.MCtrl.MR
                // Arith -> Arith
                     | D.IA.WCtrl.RW & D.IB.RS == D.IA.RD & D.IB.ES
                     | D.IA.WCtrl.RW & D.IB.RT == D.IA.RD & D.IB.ET
                // Load -> MulDiv
                     | D.IA.WCtrl.RW & D.IB.RS == D.IA.RD & D.IB.MCtrl0.HLS[2] & ~D.IA.DP0
                // Load -> C0
                     | D.IA.WCtrl.RW & D.IB.RT == D.IA.RD & D.IB.MCtrl0.C0W & ~D.IA.DP0
                // Not Arith -> Store
                     | D.IA.WCtrl.RW & D.IB.RT == D.IA.RD & D.IB.MCtrl1.MWR & ~D.IA.DP1
                // Not Arith -> LWL/LWR
                     | D.IA.WCtrl.RW & D.IB.RT == D.IA.RD & |D.IB.MCtrl1.ALR & ~D.IA.DP1
                // CP0 Execution Hazards
                // Hazards Related to the TLB
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBR  & D.IA.MCtrl0.C0D == C0_INDEX
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBWI & D.IA.MCtrl0.C0D == C0_ENTRYHI
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBWI & D.IA.MCtrl0.C0D == C0_ENTRYLO0
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBWI & D.IA.MCtrl0.C0D == C0_ENTRYLO1
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBWI & D.IA.MCtrl0.C0D == C0_INDEX & ~D.IB.MCtrl1.TLBWR
                    //  | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBWI & D.IA.MCtrl0.C0D == C0_PAGEMASK
                     | E.I0.MCtrl.C0W   & D.IB.MCtrl1.TLBP  & E.I0.MCtrl.C0D  == C0_ENTRYHI
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.TLBP  & D.IA.MCtrl0.C0D == C0_ENTRYHI
                     | D.IA.MCtrl0.C0W  & D.IB.MCtrl1.MR    & D.IA.MCtrl0.C0D == C0_ENTRYHI
                  // TODO: CACHE
                     | D.IA.MCtrl1.TLBR & D.IB.MCtrl0.C0W
                     | D.IA.MCtrl1.TLBP & D.IB.MCtrl0.C0W
                     | D.IA.MCtrl1.TLBR & D.IB.WCtrl.RW     & D.IB.MCtrl0.C0D == C0_ENTRYHI  & D.IB.MCtrl0.RS0 == RS0_C0
                     | D.IA.MCtrl1.TLBR & D.IB.WCtrl.RW     & D.IB.MCtrl0.C0D == C0_ENTRYLO0 & D.IB.MCtrl0.RS0 == RS0_C0
                     | D.IA.MCtrl1.TLBR & D.IB.WCtrl.RW     & D.IB.MCtrl0.C0D == C0_ENTRYLO1 & D.IB.MCtrl0.RS0 == RS0_C0
                    //  | D.IA.MCtrl1.TLBR & D.IB.WCtrl.RW     & D.IB.MCtrl0.C0D == C0_PAGEMASK & D.IB.MCtrl0.RS0 == RS0_C0
                     | D.IA.MCtrl1.TLBP & D.IB.WCtrl.RW     & D.IB.MCtrl0.C0D == C0_INDEX    & D.IB.MCtrl0.RS0 == RS0_C0
                // Hazards Related to Exceptions or Interrupts
                     | D.IA.MCtrl0.C0W  & D.IB.ERET         & D.IA.MCtrl0.C0D == C0_EPC
                ;

  assign D.A = (D.IA.DP0 & D.IA.DP1 | D.IA_ExcValid) ? D.IB.DP0 : D.IA.DP1;

  assign D_IA_can_dispatch = ~D_IA_valid | D.IA_ExcValid | ~D_IA_Hazard & (~D.IA.BJRJ | D_IB_valid);
  assign D_IB_can_dispatch = ~D_IB_valid | D.IB_ExcValid & ~(D.IB.ERET & ~D.IB_Delay) | ~D_IB_Hazard & ~D.IB.BJRJ & (D.A ? D.IB.DP0 : D.IB.DP1);

  assign D_readygo  = ~D_IA_valid | ~D_IB_valid | D_IA_can_dispatch & E.en;
  assign D_readygo1 = ~D_IA_valid | D_IB_can_dispatch & D_IA_can_dispatch & E.en;

  assign D.en0 = ~D_IA_valid | ~D_IB_valid | D_go & E.en;
  assign D.en1 = ~D_IA_valid | D_IB_can_dispatch & D_go & E.en;

  assign D_go    = (~PF_go | ~D.IA.BJRJ | D.IA.B & ~D.IA.BGO | fetch_i.req & fetch_i.addr_ok) & D_IA_can_dispatch | D.IA_ExcValid;
  assign D_IA_go = D_IA_valid & ~D.IA_ExcValid;
  assign D_IB_go = D_IB_valid & ~D.IB_ExcValid & D_IB_can_dispatch & ~D.IA_ExcValid;

  assign D_I0_go       = D.A ? D_IB_go       : D_IA_go;
  assign D.I0.pc       = D.A ? D.IB_pc       : D.IA_pc;
  assign D.I0.ExcValid = D.A ? D.IB_ExcValid : D.IA_ExcValid;
  assign D.I0.ERET     = D.A ? D.IB_ERET     : D.IA_ERET;
  assign D.I0.REFILL   = D.A ? D.IB_REFILL   : D.IA_REFILL;
  assign D.I0.ExcCode  = D.A ? D.IB_ExcCode  : D.IA_ExcCode;
  assign D.I0.Delay    = D.A ? D.IB_Delay    : D.IA_Delay;
  assign D.I0.OFA      = D.A ? D.IB.OFA      : D.IA.OFA;
  assign D.I0.RS       = D.A ? D.IB.RS       : D.IA.RS;
  assign D.I0.RT       = D.A ? D.IB.RT       : D.IA.RT;
  assign D.I0.S        = D.A ? D_IB_ForwardS : D_IA_ForwardS;
  assign D.I0.T        = D.A ? D_IB_ForwardT : D_IA_ForwardT;
  assign D.I0.imm      = D.A ? D.IB_imm      : D.IA_imm;
  assign D.I0.sa       = D.A ? D.IB_sa       : D.IA_sa;
  assign D.I0.ECtrl    = D.A ? D.IB.ECtrl    : D.IA.ECtrl;
  assign D.I0.MCtrl    = D.A ? D.IB.MCtrl0   : D.IA.MCtrl0;
  assign D.I0.RD       = D.A ? D.IB.RD       : D.IA.RD;
  assign D.I0.WCtrl    = D.A ? D.IB.WCtrl    : D.IA.WCtrl;

  assign D_I1_go       = D.A ? D_IA_go       : D_IB_go;
  assign D.I1.pc       = D.A ? D.IA_pc       : D.IB_pc;
  assign D.I1.ExcValid = D.A ? D.IA_ExcValid : D.IB_ExcValid;
  assign D.I1.ERET     = D.A ? D.IA_ERET     : D.IB_ERET;
  assign D.I1.REFILL   = D.A ? D.IA_REFILL   : D.IB_REFILL;
  assign D.I1.ExcCode  = D.A ? D.IA_ExcCode  : D.IB_ExcCode;
  assign D.I1.Delay    = D.A ? D.IA_Delay    : D.IB_Delay;
  assign D.I1.OFA      = D.A ? D.IA.OFA      : D.IB.OFA;
  assign D.I1.RS       = D.A ? D.IA.RS       : D.IB.RS;
  assign D.I1.RT       = D.A ? D.IA.RT       : D.IB.RT;
  assign D.I1.S        = D.A ? D_IA_ForwardS : D_IB_ForwardS;
  assign D.I1.T        = D.A ? D_IA_ForwardT : D_IB_ForwardT;
  assign D.I1.imm      = D.A ? D.IA_imm      : D.IB_imm;
  assign D.I1.sa       = D.A ? D.IA_sa       : D.IB_sa;
  assign D.I1.ECtrl    = D.A ? D.IA.ECtrl    : D.IB.ECtrl;
  assign D.I1.MCtrl    = D.A ? D.IA.MCtrl1   : D.IB.MCtrl1;
  assign D.I1.Trap     = D.A ? D.IA.Trap     : D.IB.Trap;
  assign D.I1.RD       = D.A ? D.IA.RD       : D.IB.RD;
  assign D.I1.WCtrl    = D.A ? D.IA.WCtrl    : D.IB.WCtrl;

  // D.Forwarding
  assign D_IA_FS_M_I0 = M.I0.WCtrl.RW & D.IA.RS == M.I0.RD;
  assign D_IA_FS_M_I1 = M.I1.WCtrl.RW & D.IA.RS == M.I1.RD;
  assign D_IA_FS_W_I0 = W.I0.WCtrl.RW & D.IA.RS == W.I0.RD;
  assign D_IA_FS_W_I1 = W.I1.WCtrl.RW & D.IA.RS == W.I1.RD;
  mux3 #(32) D_IA_ForwardS_mux (
      D.IA_S,
      (~D_IA_FS_W_I0 | D_IA_FS_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~D_IA_FS_M_I0 | D_IA_FS_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {D_IA_FS_M_I0 | D_IA_FS_M_I1, D_IA_FS_W_I0 | D_IA_FS_W_I1},
      D_IA_ForwardS
  );

  assign D_IA_FT_M_I0 = M.I0.WCtrl.RW & D.IA.RT == M.I0.RD;
  assign D_IA_FT_M_I1 = M.I1.WCtrl.RW & D.IA.RT == M.I1.RD;
  assign D_IA_FT_W_I0 = W.I0.WCtrl.RW & D.IA.RT == W.I0.RD;
  assign D_IA_FT_W_I1 = W.I1.WCtrl.RW & D.IA.RT == W.I1.RD;
  mux3 #(32) D_IA_ForwardT_mux (
      D.IA_T,
      (~D_IA_FT_W_I0 | D_IA_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~D_IA_FT_M_I0 | D_IA_FT_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {D_IA_FT_M_I0 | D_IA_FT_M_I1, D_IA_FT_W_I0 | D_IA_FT_W_I1},
      D_IA_ForwardT
  );

  assign D_IB_FS_M_I0 = M.I0.WCtrl.RW & D.IB.RS == M.I0.RD;
  assign D_IB_FS_M_I1 = M.I1.WCtrl.RW & D.IB.RS == M.I1.RD;
  assign D_IB_FS_W_I0 = W.I0.WCtrl.RW & D.IB.RS == W.I0.RD;
  assign D_IB_FS_W_I1 = W.I1.WCtrl.RW & D.IB.RS == W.I1.RD;
  mux3 #(32) D_IB_ForwardS_mux (
      D.IB_S,
      (~D_IB_FS_W_I0 | D_IB_FS_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~D_IB_FS_M_I0 | D_IB_FS_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {D_IB_FS_M_I0 | D_IB_FS_M_I1, D_IB_FS_W_I0 | D_IB_FS_W_I1},
      D_IB_ForwardS
  );

  assign D_IB_FT_M_I0 = M.I0.WCtrl.RW & D.IB.RT == M.I0.RD;
  assign D_IB_FT_M_I1 = M.I1.WCtrl.RW & D.IB.RT == M.I1.RD;
  assign D_IB_FT_W_I0 = W.I0.WCtrl.RW & D.IB.RT == W.I0.RD;
  assign D_IB_FT_W_I1 = W.I1.WCtrl.RW & D.IB.RT == W.I1.RD;
  mux3 #(32) D_IB_ForwardT_mux (
      D.IB_T,
      (~D_IB_FT_W_I0 | D_IB_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~D_IB_FT_M_I0 | D_IB_FT_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {D_IB_FT_M_I0 | D_IB_FT_M_I1, D_IB_FT_W_I0 | D_IB_FT_W_I1},
      D_IB_ForwardT
  );

  //---------------------------------------------------------------------------//
  //                               Execute Stage                               //
  //---------------------------------------------------------------------------//

  // E.FF
  ffenr #(1) E_valid_ff (
      clk,
      rst | rstM,
      D_IA_valid,
      E.en,
      E_valid       // just pc valid
  );
  ffen #(1) E_A_ff (
      clk,
      D.A,
      E.en,
      E.A
  );
  ffen #(32) E_I0_pc_ff (
      clk,
      D.I0.pc,
      E.en,
      E.I0.pc
  );
  ffenrc #(1 + 1 + 1 + 5 + 1) E_I0_Exc_ff (
      clk,
      rst | rstM,
      {D.I0.ExcValid, D.I0.ERET, D.I0.REFILL, D.I0.ExcCode, D.I0.Delay},
      E.en,
      ~D_go,
      {E_I0_PrevExcValid, E_I0_PrevERET, E_I0_PrevREFILL, E_I0_PrevExcCode, E.I0.Delay}
  );
  ffenrc #(1) E_I0_ExcCtrl_ff (
      clk,
      rst | rstM,
      D.I0.OFA,
      E.en,
      ~D_go | ~D_I0_go,
      E.I0.OFA
  );
  ffen #(5 + 5) E_I0_RST_ff (
      clk,
      {D.I0.RS, D.I0.RT},
      E.en,
      {E.I0.RS, E.I0.RT}
  );
  ffen #(32 + 32) E_I0_ST_ff (
      clk,
      E.en ? {D.I0.S, D.I0.T} : {E_I0_ForwardS, E_I0_ForwardT},
      1'b1,
      {E.I0.S, E.I0.T}
  );
  ffen #(32 + 5) E_I0_IS_ff (
      clk,
      {D.I0.imm, D.I0.sa},
      E.en,
      {E.I0.imm, E.I0.sa}
  );
  ffen #(14) E_I0_ECtrl_ff (
      clk,
      D.I0.ECtrl,
      E.en,
      E.I0.ECtrl
  );
  ffenrc #(19) E_I0_MCtrl_ff (
      clk,
      rst | rstM,
      D.I0.MCtrl,
      E.en,
      ~D_go | ~D_I0_go,
      E.I0.MCtrl
  );
  ffenrc #(5 + 1) E_I0_WCtrl_ff (
      clk,
      rst | rstM,
      {D.I0.RD, D.I0.WCtrl},
      E.en,
      ~D_go | ~D_I0_go,
      {E.I0.RD, E.I0.WCtrl}
  );

  ffen #(32) E_I1_pc_ff (
      clk,
      D.I1.pc,
      E.en,
      E.I1.pc
  );
  ffenrc #(1 + 1 + 1 + 5 + 1) E_I1_Exc_ff (
      clk,
      rst | rstM,
      {D.I1.ExcValid, D.I1.ERET, D.I1.REFILL, D.I1.ExcCode, D.I1.Delay},
      E.en,
      ~D_go,
      {E_I1_PrevExcValid, E_I1_PrevERET, E_I1_PrevREFILL, E_I1_PrevExcCode, E.I1.Delay}
  );
  ffenrc #(1) E_I1_ExcCtrl_ff (
      clk,
      rst | rstM,
      D.I1.OFA,
      E.en,
      ~D_go | ~D_I1_go,
      E.I1.OFA
  );
  ffen #(5 + 5) E_I1_RST_ff (
      clk,
      {D.I1.RS, D.I1.RT},
      E.en,
      {E.I1.RS, E.I1.RT}
  );
  ffen #(32 + 32) E_I1_ST_ff (
      clk,
      E.en ? {D.I1.S, D.I1.T} : {E_I1_ForwardS, E_I1_ForwardT},
      1'b1,
      {E.I1.S, E.I1.T}
  );
  ffen #(32 + 5) E_I1_IS_ff (
      clk,
      {D.I1.imm, D.I1.sa},
      E.en,
      {E.I1.imm, E.I1.sa}
  );
  ffen #(14) E_I1_ECtrl_ff (
      clk,
      D.I1.ECtrl,
      E.en,
      E.I1.ECtrl
  );
  ffenrc #(14) E_I1_MCtrl_ff (
      clk,
      rst | rstM,
      D.I1.MCtrl,
      E.en,
      ~D_go | ~D_I1_go,
      E.I1.MCtrl
  );
  ffenrc #(3) E_I1_Trap_ff (
      clk,
      rst | rstM,
      D.I1.Trap,
      E.en,
      ~D_go | ~D_I1_go,
      E.I1.Trap
  );
  ffenrc #(5 + 1) E_I1_WCtrl_ff (
      clk,
      rst | rstM,
      {D.I1.RD, D.I1.WCtrl},
      E.en,
      ~D_go | ~D_I1_go,
      {E.I1.RD, E.I1.WCtrl}
  );

  // E.Exc
  assign E_I0_NowExcValidWithoutOF = C0_int & E_valid;
  assign E_I0_NowExcValid          = E_I0_NowExcValidWithoutOF | E_I0_Overflow & E.I0.OFA;
  assign E_I0_ExcValidWithoutOF    = E_I0_PrevExcValid | E_I0_NowExcValidWithoutOF;
  assign E.I0.ExcValid             = E_I0_PrevExcValid | E_I0_NowExcValid;
  assign E.I0.ERET                 = E_I0_PrevERET   & ~C0_int;
  assign E.I0.REFILL               = E_I0_PrevREFILL & ~C0_int;
  assign E.I0.ExcCode              = C0_int            ? 5'h0
                                   : E_I0_PrevExcValid ? E_I0_PrevExcCode : `EXCCODE_OV;

  assign E_I1_NowExcValidWithoutOF = C0_int & E_valid | E.I1.MCtrl.MR & E_I1_STRBERROR;
  assign E_I1_NowExcValid          = E_I1_NowExcValidWithoutOF | E_I1_Overflow & E.I1.OFA;
  assign E_I1_ExcValidWithoutOF    = E_I1_PrevExcValid | E_I1_NowExcValidWithoutOF;
  assign E.I1.ExcValid             = E_I1_PrevExcValid | E_I1_NowExcValid;
  assign E.I1.ERET                 = E_I1_PrevERET   & ~C0_int;
  assign E.I1.REFILL               = E_I1_PrevREFILL & ~C0_int;
  assign E.I1.ExcCode              = C0_int                   ? 5'h0
                                   : E_I1_PrevExcValid        ? E_I1_PrevExcCode
                                   : E_I1_Overflow & E.I1.OFA ? `EXCCODE_OV
                                   : E.I1.MCtrl.MWR           ? `EXCCODE_ADES : `EXCCODE_ADEL;
  assign E.I1.BadVAddr             = E_I1_PrevExcValid        ? E.I1.pc : E.I1.ALUOut;

  assign E_I0_go = ~E_I0_NowExcValid & (~E.A | ~E_I1_NowExcValid);
  assign E_I1_goWithoutOF = ~E_I1_NowExcValidWithoutOF & (E.A | ~E_I0_NowExcValidWithoutOF);
  assign E_I1_go = ~E_I1_NowExcValid & (E.A | ~E_I0_NowExcValid);

  // E.I0.ALU
  mux4 #(32) E_I0_A_mux (
      {27'b0, E.I0.sa},
      E.I0.pc,
      32'd0,
      E_I0_ForwardS,
      E.I0.ECtrl.SA,
      E_I0_A
  );
  mux3 #(32) E_I0_B_mux (
      E_I0_ForwardT,
      32'd8,
      E.I0.imm,
      E.I0.ECtrl.SB,
      E_I0_B
  );
  ALU E_I0_ALU (
      E_I0_A,
      E_I0_B,
      E.I0.ECtrl.OP,
      E.I0.ALUOut,
      E_I0_Overflow
  );

  // E.I0.MUL
  mul_signed E_I0_MULT_mul (
      .CLK(clk),
      .A  (E_I0_ForwardS),
      .B  (E_I0_ForwardT),
      .P  ({M_I0_MULTH, M_I0_MULTL})
  );
  mul_unsigned E_I0_MULTU_mul (
      .CLK(clk),
      .A  (E_I0_ForwardS),
      .B  (E_I0_ForwardT),
      .P  ({M_I0_MULTUH, M_I0_MULTUL})
  );

  // E.I0.DIV
  div_signed E_I0_DIV_div (
      .aclk                  (clk),
      .s_axis_dividend_tvalid(E.I0.MCtrl.HLS == DIV & E_go & E_I0_go & M.en),
      .s_axis_dividend_tdata (E_I0_ForwardS),
      .s_axis_divisor_tvalid (E.I0.MCtrl.HLS == DIV & E_go & E_I0_go & M.en),
      .s_axis_divisor_tdata  (E_I0_ForwardT),
      .m_axis_dout_tvalid    (M_I0_DIV_valid),
      .m_axis_dout_tdata     ({M_I0_DIVL, M_I0_DIVH})
  );
  div_unsigned E_I0_DIVU_div (
      .aclk                  (clk),
      .s_axis_dividend_tvalid(E.I0.MCtrl.HLS == DIVU & E_go & E_I0_go & M.en),
      .s_axis_dividend_tdata (E_I0_ForwardS),
      .s_axis_divisor_tvalid (E.I0.MCtrl.HLS == DIVU & E_go & E_I0_go & M.en),
      .s_axis_divisor_tdata  (E_I0_ForwardT),
      .m_axis_dout_tvalid    (M_I0_DIVU_valid),
      .m_axis_dout_tdata     ({M_I0_DIVUL, M_I0_DIVUH})
  );

  // E.I1.ALU
  mux4 #(32) E_I1_A_mux (
      {27'b0, E.I1.sa},
      E.I1.pc,
      32'd0,
      E_I1_ForwardS,
      E.I1.ECtrl.SA,
      E_I1_A
  );
  mux3 #(32) E_I1_B_mux (
      E_I1_ForwardT,
      32'd8,
      E.I1.imm,
      E.I1.ECtrl.SB,
      E_I1_B
  );
  ALU E_I1_ALU (
      E_I1_A,
      E_I1_B,
      E.I1.ECtrl.OP,
      E.I1.ALUOut,
      E_I1_Overflow
  );

  // E.I1.MEM
  memerror E_I1_memerror (
      mem_i.addr[1:0],
      E.I1.MCtrl.SZ,
      E_I1_STRBERROR
  );

  assign tlb_tlbp   = E.I1.MCtrl.TLBP;
  assign mem_i.req  = E.I1.MCtrl.MR & E_I1_goWithoutOF & M.en & ~rstM;
  assign E_I1_ADDR  = E_I1_ForwardS + E.I1.imm;
  assign mem_i.addr = |E.I1.MCtrl.ALR                     ? {E_I1_ADDR[31:2], 2'b0}
                      : (cache_op == CNOP | ~cache_op[1]) ? E_I1_ADDR
                      : cache_op[2]                       ? {E_I1_ADDR[32-`DC_INDEXL-1:0], `DC_INDEXL'b0}
                      : {E_I1_ADDR[32-`IC_INDEXL-1:0], `IC_INDEXL'b0};
  assign mem_i.size = {E.I1.MCtrl.SZ[1], E.I1.MCtrl.SZ[0] & ~E.I1.MCtrl.SZ[1]};
  assign cache_op   = E.I1.MCtrl.CACHE_OP;

  assign E.en = E_go & M.en;
  assign E_go = ~mem_i.req | mem_i.addr_ok;

  // E.Forwarding
  assign E_I0_FS_M_I0 = M.I0.WCtrl.RW & E.I0.RS == M.I0.RD;
  assign E_I0_FS_M_I1 = M.I1.WCtrl.RW & E.I0.RS == M.I1.RD;
  assign E_I0_FS_W_I0 = W.I0.WCtrl.RW & E.I0.RS == W.I0.RD;
  assign E_I0_FS_W_I1 = W.I1.WCtrl.RW & E.I0.RS == W.I1.RD;
  mux3 #(32) E_I0_ForwardS_mux (
      E.I0.S,
      (~E_I0_FS_W_I0 | E_I0_FS_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~E_I0_FS_M_I0 | E_I0_FS_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {E_I0_FS_M_I0 | E_I0_FS_M_I1, E_I0_FS_W_I0 | E_I0_FS_W_I1},
      E_I0_ForwardS
  );

  assign E_I0_FT_M_I0 = M.I0.WCtrl.RW & E.I0.RT == M.I0.RD;
  assign E_I0_FT_M_I1 = M.I1.WCtrl.RW & E.I0.RT == M.I1.RD;
  assign E_I0_FT_W_I0 = W.I0.WCtrl.RW & E.I0.RT == W.I0.RD;
  assign E_I0_FT_W_I1 = W.I1.WCtrl.RW & E.I0.RT == W.I1.RD;
  mux3 #(32) E_I0_ForwardT_mux (
      E.I0.T,
      (~E_I0_FT_W_I0 | E_I0_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~E_I0_FT_M_I0 | E_I0_FT_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {E_I0_FT_M_I0 | E_I0_FT_M_I1, E_I0_FT_W_I0 | E_I0_FT_W_I1},
      E_I0_ForwardT
  );

  assign E_I1_FS_M_I0 = M.I0.WCtrl.RW & E.I1.RS == M.I0.RD;
  assign E_I1_FS_M_I1 = M.I1.WCtrl.RW & E.I1.RS == M.I1.RD;
  assign E_I1_FS_W_I0 = W.I0.WCtrl.RW & E.I1.RS == W.I0.RD;
  assign E_I1_FS_W_I1 = W.I1.WCtrl.RW & E.I1.RS == W.I1.RD;
  mux3 #(32) E_I1_ForwardS_mux (
      E.I1.S,
      (~E_I1_FS_W_I0 | E_I1_FS_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~E_I1_FS_M_I0 | E_I1_FS_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {E_I1_FS_M_I0 | E_I1_FS_M_I1, E_I1_FS_W_I0 | E_I1_FS_W_I1},
      E_I1_ForwardS
  );

  assign E_I1_FT_M_I0 = M.I0.WCtrl.RW & E.I1.RT == M.I0.RD;
  assign E_I1_FT_M_I1 = M.I1.WCtrl.RW & E.I1.RT == M.I1.RD;
  assign E_I1_FT_W_I0 = W.I0.WCtrl.RW & E.I1.RT == W.I0.RD;
  assign E_I1_FT_W_I1 = W.I1.WCtrl.RW & E.I1.RT == W.I1.RD;
  mux3 #(32) E_I1_ForwardT_mux (
      E.I1.T,
      (~E_I1_FT_W_I0 | E_I1_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      (~E_I1_FT_M_I0 | E_I1_FT_M_I1 & ~M.A) ? M.I1.ALUOut : M.I0.ALUOut,
      {E_I1_FT_M_I0 | E_I1_FT_M_I1, E_I1_FT_W_I0 | E_I1_FT_W_I1},
      E_I1_ForwardT
  );

  //----------------------------------------------------------------------------//
  //                                Memory Stage                                //
  //----------------------------------------------------------------------------//

  // M.FF
  ffen #(1) M_A_ff (
      clk,
      E.A,
      M.en,
      M.A
  );
  ffen #(32) M_I0_pc_ff (
      clk,
      E.I0.pc,
      M.en,
      M.I0.pc
  );
  ffenrc #(1 + 1 + 1 + 5 + 1) M_I0_Exc_ff (
      clk,
      rst | rstM,
      {E.I0.ExcValid, E.I0.ERET, E.I0.REFILL, E.I0.ExcCode, E.I0.Delay},
      M.en,
      ~E_go,
      {M.I0.ExcValid, M.I0.ERET, M.I0.REFILL, M.I0.ExcCode, M.I0.Delay}
  );
  ffen #(5 + 5) M_I0_RST_ff (
      clk,
      {E.I0.RS, E.I0.RT},
      M.en,
      {M.I0.RS, M.I0.RT}
  );
  ffen #(32 + 32) M_I0_ST_ff (
      clk,
      M.en ? {E_I0_ForwardS, E_I0_ForwardT} : {M_I0_ForwardS, M_I0_ForwardT},
      1'b1,
      {M.I0.S, M.I0.T}
  );
  ffen #(32) M_I0_ALUOut_ff (
      clk,
      E.I0.ALUOut,
      M.en,
      M.I0.ALUOut
  );
  ffenrc #(19) M_I0_MCtrl_ff (
      clk,
      rst | rstM,
      E.I0.MCtrl,
      M.en,
      ~E_go | ~E_I0_go,
      M.I0.MCtrl
  );
  ffenrc #(5 + 1) M_I0_WCtrl_ff (
      clk,
      rst | rstM,
      {E.I0.RD, E.I0.WCtrl},
      M.en,
      ~E_go | ~E_I0_go,
      {M.I0.RD, M.I0.WCtrl}
  );
  ffenr #(6) M_I0_MULT_CNTR_ff (
      clk,
      rst | rstM,
      {E.I0.MCtrl.HLS[2:1] == 2'b10 & E_go & M.en, M_I0_MULT_CNTR[5:1]},
      1'b1,
      M_I0_MULT_CNTR
  );
  ffen #(32) M_I1_pc_ff (
      clk,
      E.I1.pc,
      M.en,
      M.I1.pc
  );
  ffenrc #(1 + 1 + 1 + 5 + 32 + 1) M_I1_Exc_ff (
      clk,
      rst | rstM,
      {E.I1.ExcValid, E.I1.ERET, E.I1.REFILL, E.I1.ExcCode, E.I1.BadVAddr, E.I1.Delay},
      M.en,
      ~E_go,
      {M_I1_PrevExcValid, M.I1.ERET, M_I1_PrevREFILL, M_I1_PrevExcCode, M.I1.BadVAddr, M.I1.Delay}
  );
  ffen #(5) M_I1_RT_ff (
      clk,
      E.I1.RT,
      M.en,
      M.I1.RT
  );
  ffen #(32) M_I1_T_ff (
      clk,
      M.en ? E_I1_ForwardT : M_I1_ForwardT,
      1'b1,
      M.I1.T
  );
  ffen #(32) M_I1_ALUOut_ff (
      clk,
      E.I1.ALUOut,
      M.en,
      M.I1.ALUOut
  );
  ffenrc #(14) M_I1_MCtrl_ff (
      clk,
      rst | rstM,
      E.I1.MCtrl,
      M.en,
      ~E_go | ~E_I1_go,
      M.I1.MCtrl
  );
  ffenrc #(3) M_I1_Trap_ff (
      clk,
      rst | rstM,
      E.I1.Trap,
      M.en,
      ~E_go | ~E_I1_go,
      M.I1.Trap
  );
  ffenrc #(5 + 1) M_I1_WCtrl_ff (
      clk,
      rst | rstM,
      {E.I1.RD, E.I1.WCtrl},
      M.en,
      ~E_go | ~E_I1_go,
      {M.I1.RD, M.I1.WCtrl}
  );

  // M.Exc
  assign M.I0.BadVAddr = M.I0.pc;

  ffenr #(1) dTLBExcValid_ff (
      clk,
      rst,
      M.en,
      1'b1,
      dTLBExcValid
  );
  myBuffer0 #(4) dExc_buffer (
      clk, rst,
      {dTLBRefill,  dTLBInvalid,  dTLBModified, dAddressError},
      dTLBExcValid,
      {dTLBRefillB, dTLBInvalidB, dTLBModifiedB, dAddressErrorB}
  );
  assign M_I1_NowExcValid = dTLBRefillB | dTLBInvalidB | dTLBModifiedB | dAddressErrorB | M_I1_Trap;
  assign M.I1.ExcValid    = M_I1_PrevExcValid | M_I1_NowExcValid;
  assign M.I1.REFILL      = M_I1_PrevREFILL | dTLBRefillB;
  assign M.I1.ExcCode     = M_I1_PrevExcValid ? M_I1_PrevExcCode
                          : M_I1_Trap         ? `EXCCODE_TR
                          : dAddressErrorB    ? M.I1.MCtrl.MWR ? `EXCCODE_ADES : `EXCCODE_ADES
                          : dTLBRefillB       ? M.I1.MCtrl.MWR ? `EXCCODE_TLBS : `EXCCODE_TLBL
                          : dTLBInvalidB      ? M.I1.MCtrl.MWR ? `EXCCODE_TLBS : `EXCCODE_TLBL
                          : `EXCCODE_MOD;

  assign M_I0_go = ~M.A | ~M_I1_NowExcValid;
  assign M_I1_go = ~M_I1_NowExcValid;

  assign {M_exception, M_exception_REFILL} = {
     M.I1.ExcValid | M.I0.ExcValid,
    ~M.I0.ExcValid | M.I1.ExcValid & M.A ? {M.I1.Delay, M.I1.ExcCode, M.I1.BadVAddr, M.I1.pc, M.I1.ERET, M.I1.REFILL}
                                         : {M.I0.Delay, M.I0.ExcCode, M.I0.BadVAddr, M.I0.pc, M.I0.ERET, M.I0.REFILL}
  };
  assign C0_exception = {
    M_exception.ExcValid & M.en,
    M_exception.Delay,
    M_exception.ExcCode,
    M_exception.BadVAddr,
    M_exception.EPC,
    M_exception.ERET & M.en
  };

  // M.I0.MUL
  ffenr #(97) M_I0_MAS_ff (
    clk,rst,
    {M_I0_MULTL,  M_I0_MULTH,  M_I0_MULTUH, M_I0_MULT_CNTR[0]},
    1'b1,
    {M_I0_MULTLF, M_I0_MULTHF, M_I0_MULTUHF, M_I0_MAS_bvalid}
  );

  // TODO: Optimize ME
  assign {M_I0_MUASH, M_I0_MUASL} = M.I0.MCtrl.MAS[0] ? {HI, LO} + {M_I0_MULTUHF, M_I0_MULTLF}
                                                      : {HI, LO} - {M_I0_MULTUHF, M_I0_MULTLF};
  assign {M_I0_MASH, M_I0_MASL} = M.I0.MCtrl.MAS[0] ? $signed({HI, LO}) + $signed({M_I0_MULTHF, M_I0_MULTLF})
                                                    : $signed({HI, LO}) - $signed({M_I0_MULTHF, M_I0_MULTLF});

  myBuffer #(96) M_I0_MULT_buffer (
      clk, rst,
      M_I0_MULT_CNTR[0] & M.I0.MCtrl.MAS == 2'b00 | M_I0_MAS_bvalid & |M.I0.MCtrl.MAS,
      M.I0.MCtrl.MAS == 2'b00 ? {M_I0_MULTL, M_I0_MULTH,  M_I0_MULTUH}
                              : {M_I0_MASL, M_I0_MASH, M_I0_MUASH},
      M.en,
      M_I0_MULT_bvalid,
      {M_I0_MULTLB, M_I0_MULTHB, M_I0_MULTUHB}
  );

  // M.I0.DIV
  myBuffer #(64) M_I0_DIV_buffer (
      clk, rst,
      M_I0_DIV_valid,
      {M_I0_DIVL, M_I0_DIVH},
      M.en,
      M_I0_DIV_bvalid,
      {M_I0_DIVLB, M_I0_DIVHB}
  );
  myBuffer #(64) M_I0_DIVU_buffer (
      clk, rst,
      M_I0_DIVU_valid,
      {M_I0_DIVUL, M_I0_DIVUH},
      M.en,
      M_I0_DIVU_bvalid,
      {M_I0_DIVULB, M_I0_DIVUHB}
  );

  // M.I0.HILOC0
  mux5 #(32) M_I0_RDataW_mux (
      LO,
      HI,
      M_I0_MULTLB,
      C0_rdata,
      M.I0.ALUOut,
      M.I0.MCtrl.RS0,
      M.I0.RDataW
  );
  mux5 #(64) M_I0_HILO_mux (
      {M_I0_MULTHB,   M_I0_MULTLB},
      {M_I0_MULTUHB,  M_I0_MULTLB},
      {M_I0_DIVHB,    M_I0_DIVLB},
      {M_I0_DIVUHB,   M_I0_DIVULB},
      {M_I0_ForwardS, M_I0_ForwardS},
      {~M.I0.MCtrl.HLS[2], M.I0.MCtrl.HLS[1:0]},
      {M_I0_HI,       M_I0_LO}
  );
  ffen #(32) HI_ff (
      clk,
      M_I0_HI,
      M.I0.MCtrl.HW & M_go,
      HI
  );
  ffen #(32) LO_ff (
      clk,
      M_I0_LO,
      M.I0.MCtrl.LW & M_go,
      LO
  );

  assign C0_addr  = M.I0.MCtrl.C0D;
  assign C0_sel   = M.I0.MCtrl.SEL;
  assign C0_we    = M.I0.MCtrl.C0W & M_I0_go;
  assign C0_wdata = M_I0_ForwardT;

  // M.I1.MEM
  assign tlb_tlbwi = M.I1.MCtrl.TLBWI;
  assign tlb_tlbwr = M.I1.MCtrl.TLBWR;
  assign c0_tlbr   = M.I1.MCtrl.TLBR;
  assign c0_tlbp   = M.I1.MCtrl.TLBP & M.en;
  assign mem_i.wr  = M.I1.MCtrl.MWR;
  memoutput M_I1_memoutput (
      .addr (M.I1.ALUOut[1:0]),
      .data (M_I1_ForwardT),
      .size (M.I1.MCtrl.SZ),
      .alr  (M.I1.MCtrl.ALR),
      .wdata(mem_i.wdata),
      .wstrb(mem_i.wstrb)
  );

  mux4 #(8) M_I1_Byte_mux (
      M_I1_DataR[7:0],
      M_I1_DataR[15:8],
      M_I1_DataR[23:16],
      M_I1_DataR[31:24],
      M.I1.ALUOut[1:0],
      M_I1_Byte
  );
  mux2 #(16) M_I1_Half_mux (
      M_I1_DataR[15:0],
      M_I1_DataR[31:16],
      M.I1.ALUOut[1],
      M_I1_Half
  );
  extender #(32, 8) M_I1_ByteX_extender (
      M_I1_Byte,
      M.I1.MCtrl.MX,
      M_I1_ByteX
  );
  extender #(32, 16) M_I1_HalfX_extender (
      M_I1_Half,
      M.I1.MCtrl.MX,
      M_I1_HalfX
  );
  mux3 #(32) M_I1_MDataA_mux (
      M_I1_ByteX,
      M_I1_HalfX,
      M_I1_DataR,
      M.I1.MCtrl.SZ,
      M_I1_MDataA
  );
  mux4 #(32) M_I1_MDataUL_mux (
      {M_I1_DataR[ 7:0], M_I1_ForwardT[23:0]},
      {M_I1_DataR[15:0], M_I1_ForwardT[15:0]},
      {M_I1_DataR[23:0], M_I1_ForwardT[ 7:0]},
      M_I1_DataR,
      M.I1.ALUOut[1:0],
      M_I1_MDataUL
  );
  mux4 #(32) M_I1_MDataUR_mux (
      M_I1_DataR,
      {M_I1_ForwardT[31:24], M_I1_DataR[31: 8]},
      {M_I1_ForwardT[31:16], M_I1_DataR[31:16]},
      {M_I1_ForwardT[31: 8], M_I1_DataR[31:24]},
      M.I1.ALUOut[1:0],
      M_I1_MDataUR
  );
  mux3 #(32) M_I1_MData_mux (
      M_I1_MDataA,
      M_I1_MDataUL,
      M_I1_MDataUR,
      M.I1.MCtrl.ALR,
      M_I1_MData
  );
  mux2 #(32) M_I1_DataRW_mux (
      M.I1.ALUOut,
      M_I1_MData,
      M.I1.MCtrl.MR,
      M.I1.RDataW
  );

  myBuffer #(32) M_I1_DataR_buffer (
      clk, rst,
      mem_i.data_ok,
      mem_i.rdata,
      M.en,
      M_I1_DataR_OK,
      M_I1_DataR
  );

  // M.I1.TRAP
  assign M_I1_Trap = M.I1.Trap.TEN & ( M.I1.Trap.TP == NE ? M.I1.ALUOut    != 32'b0
                                     : M.I1.Trap.TP == EQ ? M.I1.ALUOut    == 32'b0
                                     : M.I1.Trap.TP == LT ? M.I1.ALUOut[0] ==  1'b1
                                     : M.I1.Trap.TP == GE ? M.I1.ALUOut[0] ==  1'b0
                                     : 1'b0);

  assign M.en = M_go & W.en;
  assign M_go = (M.I0.MCtrl.HLS[2:1] != 2'b10 | M_I0_MULT_bvalid)
              & (M.I0.MCtrl.HLS      != DIV   | M_I0_DIV_bvalid)
              & (M.I0.MCtrl.HLS      != DIVU  | M_I0_DIVU_bvalid)
              & (~M.I1.MCtrl.MR | M_I1_NowExcValid | M_I1_DataR_OK)
              & (~M_exception.ExcValid | fetch_i.req & fetch_i.addr_ok);

  // M.Forwarding
  assign M_I0_FS_M_I1 = M.A & M.I1.WCtrl.RW & M.I0.RS == M.I1.RD;
  assign M_I0_FS_W_I0 = W.I0.WCtrl.RW & M.I0.RS == W.I0.RD;
  assign M_I0_FS_W_I1 = W.I1.WCtrl.RW & M.I0.RS == W.I1.RD;
  mux3 #(32) M_I0_ForwardS_mux (
      M.I0.S,
      (~M_I0_FS_W_I0 | M_I0_FS_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      M.I1.ALUOut,
      {M_I0_FS_M_I1, M_I0_FS_W_I0 | M_I0_FS_W_I1},
      M_I0_ForwardS
  );

  assign M_I0_FT_M_I1 = M.A & M.I1.WCtrl.RW & M.I0.RT == M.I1.RD;
  assign M_I0_FT_W_I0 = W.I0.WCtrl.RW & M.I0.RT == W.I0.RD;
  assign M_I0_FT_W_I1 = W.I1.WCtrl.RW & M.I0.RT == W.I1.RD;
  mux3 #(32) M_I0_ForwardT_mux (
      M.I0.T,
      (~M_I0_FT_W_I0 | M_I0_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      M.I1.ALUOut,
      {M_I0_FT_M_I1, M_I0_FT_W_I0 | M_I0_FT_W_I1},
      M_I0_ForwardT
  );

  assign M_I1_FT_M_I0 = ~M.A & M.I0.WCtrl.RW & M.I1.RT == M.I0.RD;
  assign M_I1_FT_W_I0 = W.I0.WCtrl.RW & M.I1.RT == W.I0.RD;
  assign M_I1_FT_W_I1 = W.I1.WCtrl.RW & M.I1.RT == W.I1.RD;
  mux3 #(32) M_I1_ForwardT_mux (
      M.I1.T,
      (~M_I1_FT_W_I0 | M_I1_FT_W_I1 & ~W.A) ? W.I1.RDataW : W.I0.RDataW,
      M.I0.ALUOut,
      {M_I1_FT_M_I0, M_I1_FT_W_I0 | M_I1_FT_W_I1},
      M_I1_ForwardT
  );

  //----------------------------------------------------------------------------//
  //                              Write-Back Stage                              //
  //----------------------------------------------------------------------------//

  // W.FF
  ffen #(1) W_A_ff (
      clk,
      M.A,
      W.en,
      W.A
  );
`ifdef SIMULATION_PC
  ffen #(64) W_I01_pc_ff (
      clk,
      {M.I0.pc, M.I1.pc},
      W.en,
      {W.I0.pc, W.I1.pc}
  );
`endif
  ffen #(32) W_I0_RDataW_ff (
      clk,
      M.I0.RDataW,
      W.en,
      W.I0.RDataW
  );
  ffenrc #(5 + 1) W_I0_WCtrl_ff (
      clk,
      rst,
      {M.I0.RD, M.I0.WCtrl},
      W.en,
      ~M_go | ~M_I0_go,
      {W.I0.RD, W.I0.WCtrl}
  );
  ffen #(32) W_I1_RDataW_ff (
      clk,
      M.I1.RDataW,
      W.en,
      W.I1.RDataW
  );
  ffenrc #(5 + 1) W_I1_WCtrl_ff (
      clk,
      rst,
      {M.I1.RD, M.I1.WCtrl},
      W.en,
      ~M_go | ~M_I1_go,
      {W.I1.RD, W.I1.WCtrl}
  );

  assign W.en = 1'b1;

endmodule
