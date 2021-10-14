`ifndef CP0_SVH
`define CP0_SVH

`include "defines.svh"
`include "TLB.svh"

typedef enum bit [4:0] {
  C0_DESAVE    = 5'h1F,
  C0_ERROREPC  = 5'h1E,
  C0_TAGHI     = 5'h1D,
  C0_TAGLO     = 5'h1C,
  C0_CACHEERR  = 5'h1B,
  C0_ERRCTL    = 5'h1A,
  C0_PERFCNT   = 5'h19,
  C0_DEPC      = 5'h18,
  C0_DEBUG     = 5'h17,
  C0_UNUSED22  = 5'h16,
  C0_UNUSED21  = 5'h15,
  C0_UNUSED20  = 5'h14,
  C0_WATCHHI   = 5'h13,
  C0_WATCHLO   = 5'h12,
  C0_LLADDR    = 5'h11,
  C0_CONFIG    = 5'h10,
  C0_PRID      = 5'h0F,
  C0_EPC       = 5'h0E,
  C0_CAUSE     = 5'h0D,
  C0_STATUS    = 5'h0C,
  C0_COMPARE   = 5'h0B,
  C0_ENTRYHI   = 5'h0A,
  C0_COUNT     = 5'h09,
  C0_BADVADDR  = 5'h08,
  C0_HWRENA    = 5'h07,
  C0_WIRED     = 5'h06,
  C0_PAGEMASK  = 5'h05,
  C0_CONTEXT   = 5'h04,
  C0_ENTRYLO1  = 5'h03,
  C0_ENTRYLO0  = 5'h02,
  C0_RANDOM    = 5'h01,
  C0_INDEX     = 5'h00
} C0_REGS;

typedef struct packed {
  logic       ExcValid;
  logic       Delay;
  logic [4:0] ExcCode;
  word_t      BadVAddr;
  word_t      EPC;
  logic       ERET;
} EXCEPTION_t;

typedef struct packed {
  logic        M;
  logic [14:0] zero;
  logic        BE;
  logic [1:0]  AT;
  logic [2:0]  AR;
  logic [2:0]  MT;
  logic [3:0]  zero1;
  logic [2:0]  K0;
} CP0_REGS_CONFIG_t;

typedef struct packed {
  logic [8:0] zero1;
  logic       Bev;
  logic [5:0] zero2;
  logic [7:0] IM;
  logic [2:0] zero3;
  logic       UM;
  logic [1:0] zero4;
  logic       EXL;
  logic       IE;
} CP0_REGS_STATUS_t;

typedef struct packed {
  logic        BD;
  logic        TI;
  logic [13:0] zero1;
  logic [7:0]  IP;
  logic        zero2;
  logic [4:0]  ExcCode;
  logic [1:0]  zero3;
} CP0_REGS_CAUSE_t;

typedef struct packed {
  logic        one;
  logic        zero1;
  logic [17:0] EBase;
  logic [1:0]  zero2;
  logic [9:0]  CPUNum;
} CP0_REGS_EBASE_t;

typedef struct packed {
  // ==== sel0 ====
  // word_t DESAVE,
  // ErrorEPC,
  // TagHi
  // TagLo;
  // CacheErr,
  // Errctl,
  // PerfCnt,
  // DEPC,
  // Debug,
  // unused22,
  // unused21,
  // unused20,
  // WatchHi,
  // WatchLo,
  // LLAddr
  // ;
  CP0_REGS_CONFIG_t Config;
  word_t            PRId;
  word_t            EPC;
  CP0_REGS_CAUSE_t  Cause;
  CP0_REGS_STATUS_t Status;
  word_t            Compare;
  EntryHi_t         EntryHi;
  word_t            Count;
  word_t            BadVAddr;
  // HWREna
  Wired_t           Wired;
  // Context,
  // word_t            PageMask;
  EntryLo_t         EntryLo1;
  EntryLo_t         EntryLo0;
  Random_t          Random;
  Index_t           Index;

  // ==== sel1 ====
  word_t            Config1;
  CP0_REGS_EBASE_t  EBase;
} CP0_REGS_t;

`endif
