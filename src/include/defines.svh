`ifndef DEFINES_SVH
`define DEFINES_SVH

`define PCRST 32'hBFC00000
`define Off_TRef 9'h000
`define Off_GExc 9'h180

// prio: int
//       fetch_addr
//       fetch_tlb_refill
//       fetch_tlb_invalid
//       ri
//       syscall, break, overflow, trap
//       mem_addr
//       mem_tlb_refill
//       mem_tlb_invalid
//       mem_tlb_dirty
`define EXCCODE_INT   5'h00
`define EXCCODE_MOD   5'h01
`define EXCCODE_TLBL  5'h02
`define EXCCODE_TLBS  5'h03
`define EXCCODE_ADEL  5'h04
`define EXCCODE_ADES  5'h05
`define EXCCODE_SYS   5'h08
`define EXCCODE_BP    5'h09
`define EXCCODE_RI    5'h0A
`define EXCCODE_CPU   5'h0B
`define EXCCODE_OV    5'h0C
`define EXCCODE_TR    5'h0D

typedef logic [31:0] word_t;

typedef struct packed {
  logic f_sl;
  logic f_sr;
  logic f_add;
  logic f_and;
  logic f_or;
  logic f_xor;
  logic f_slt;
  logic f_sltu;
  logic f_mova;
  logic alt;
} aluctrl_t;

typedef enum logic [1:0] {
  SA   = 2'b00,
  PC   = 2'b01,
  ZERO = 2'b10,
  RS   = 2'b11
} SA_t;

typedef enum logic [1:0] {
  RT    = 2'b00,
  EIGHT = 2'b01,
  IMM   = 2'b11   // 2'b1?
} SB_t;

typedef enum logic [2:0] {
  RS0_LO     = 3'b000,
  RS0_HI     = 3'b001,
  RS0_MUL    = 3'b010,
  RS0_C0     = 3'b011,
  RS0_ALUOut = 3'b100   // 3'b1??
} RS0_t;

typedef enum logic [2:0] {
  HLRS  = 3'b000,   // 3'b0??
  MULT  = 3'b100,
  MULTU = 3'b101,
  DIV   = 3'b110,
  DIVU  = 3'b111
} HLS_t;

typedef enum logic [1:0] {
  PASST = 2'b00, // Pass through
  MADD  = 2'b01, // MULT and ADD
  MSUB  = 2'b10  // MULT and SUB
} MAS_t;

typedef enum logic [1:0] {
  ALIGN  = 2'b00,
  ULEFT  = 2'b01,
  URIGHT = 2'b10
} ALR_t;

typedef enum logic [2:0] {
  CNOP  = 3'b000,
  IC_L  = 3'b001, // I-Cache Lookup
  IC_I  = 3'b011, // I-Cache Index
  DC_LB = 3'b100, // D-Cache Lookup writeBack
  DC_LO = 3'b101, // D-Cache Lookup writeOnly
  DC_IB = 3'b110, // D-Cache Index writeBack
  DC_IO = 3'b111  // D-Cache Index writeOnly
} CacheOp_t;

typedef enum logic [1:0] {
  GE = 2'b00,
  LT = 2'b01,
  EQ = 2'b10,
  NE = 2'b11
} TrapOp_t;

typedef struct packed {
  SA_t      SA;
  SB_t      SB;
  aluctrl_t OP;
} ECtrl_t;

typedef struct packed {
  RS0_t       RS0;    // critical
  logic       HW;     // critical
  logic       LW;     // critical
  logic [4:0] C0D;
  logic [2:0] SEL;
  logic       C0W;    // critical
  HLS_t       HLS;
  MAS_t       MAS;
} MCtrl0_t;

typedef struct packed {
  logic       MR;      // critical
  logic       MWR;     // critical
  logic       MX;
  ALR_t       ALR;     // critical
  logic [1:0] SZ;
  logic       TLBWI;   // critical
  logic       TLBWR;   // critical
  logic       TLBR;    // critical
  logic       TLBP;    // critical
  CacheOp_t   CACHE_OP; // critical
} MCtrl1_t;

typedef struct packed {
  logic    TEN; // critical
  TrapOp_t TP;
} Trap_t;

typedef struct packed {
  logic RW;           // critical
} WCtrl_t;

typedef struct packed {
  logic PRV;

  logic SYSCALL;
  logic BREAK;
  logic ERET;
  logic OFA;

  logic [4:0] RS;
  logic [4:0] RT;

  logic BJRJ;
  logic B;
  logic JR;
  logic J;
  logic BGO;
  logic DP0;
  logic DP1;
  logic DS;
  logic DT;
  logic ES;
  logic ET;

  ECtrl_t ECtrl;

  MCtrl0_t MCtrl0;
  MCtrl1_t MCtrl1;
  Trap_t   Trap;

  logic [4:0] RD;
  WCtrl_t     WCtrl;
} Ctrl_t;

typedef struct packed {word_t pc;} PF_t;

typedef struct packed {
  logic  en;
  word_t pc;
  logic  ExcValid;
} F_t;

typedef struct packed {
  logic  en0, en1;
  Ctrl_t IA,  IB;

  logic A;

  word_t      IA_pc;
  word_t      IA_inst;
  logic       IA_ExcValid;
  logic       IA_ERET;
  logic       IA_REFILL;
  logic [4:0] IA_ExcCode;
  logic       IA_Delay;
  word_t      IA_S;
  word_t      IA_T;
  word_t      IA_imm;
  logic [4:0] IA_sa;

  word_t      IB_pc;
  word_t      IB_inst;
  logic       IB_ExcValid;
  logic       IB_ERET;
  logic       IB_REFILL;
  logic [4:0] IB_ExcCode;
  logic       IB_Delay;
  word_t      IB_S;
  word_t      IB_T;
  word_t      IB_imm;
  logic [4:0] IB_sa;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    logic       Delay;
    logic       OFA;

    logic [4:0] RS;
    logic [4:0] RT;
    word_t      S;
    word_t      T;

    word_t      imm;
    logic [4:0] sa;

    ECtrl_t ECtrl;

    MCtrl0_t MCtrl;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I0;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    logic       Delay;
    logic       OFA;

    logic [4:0] RS;
    logic [4:0] RT;
    word_t      S;
    word_t      T;

    word_t      imm;
    logic [4:0] sa;

    ECtrl_t ECtrl;

    MCtrl1_t MCtrl;
    Trap_t   Trap;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I1;
} D_t;

typedef struct packed {
  logic en;
  logic A;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    logic       Delay;
    logic       OFA;

    logic [4:0] RS;
    logic [4:0] RT;
    word_t      S;
    word_t      T;

    word_t      imm;
    logic [4:0] sa;

    ECtrl_t ECtrl;
    word_t  ALUOut;

    MCtrl0_t MCtrl;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I0;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    word_t      BadVAddr;
    logic       Delay;
    logic       OFA;

    logic [4:0] RS;
    logic [4:0] RT;
    word_t      S;
    word_t      T;

    word_t      imm;
    logic [4:0] sa;

    ECtrl_t ECtrl;
    word_t  ALUOut;

    MCtrl1_t MCtrl;
    Trap_t   Trap;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I1;
} E_t;

typedef struct packed {
  logic en;
  logic A;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    word_t      BadVAddr;
    logic       Delay;

    logic [4:0] RS;
    logic [4:0] RT;
    word_t      S;
    word_t      T;

    word_t ALUOut;

    MCtrl0_t MCtrl;
    word_t   RDataW;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I0;

  struct packed {
    word_t pc;

    logic       ExcValid;
    logic       ERET;
    logic       REFILL;
    logic [4:0] ExcCode;
    word_t      BadVAddr;
    logic       Delay;

    logic [4:0] RT;
    word_t      T;

    word_t ALUOut;

    MCtrl1_t MCtrl;
    Trap_t   Trap;
    word_t   RDataW;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I1;
} M_t;

typedef struct packed {
  logic en;
  logic A;

  struct packed {
`ifdef SIMULATION_PC
    word_t pc;
`endif

    word_t RDataW;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I0;

  struct packed {
`ifdef SIMULATION_PC
    word_t pc;
`endif

    word_t RDataW;

    logic [4:0] RD;
    WCtrl_t     WCtrl;
  } I1;
} W_t;

`endif
