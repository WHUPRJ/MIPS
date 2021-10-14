`ifndef TLB_SVH
`define TLB_SVH

typedef struct packed {
  logic [18:0] VPN2;
  logic [ 4:0] zero;
  logic [ 7:0] ASID;
} EntryHi_t;

// typedef struct packed {
//   logic [ 6:0] zero1;
//   logic [11:0] Mask;
//   logic [12:0] zero2;
// } PageMask_t;

typedef struct packed {
  logic [ 5:0] zero;
  logic [19:0] PFN;
  logic [ 2:0] C;
  logic        D;
  logic        V;
  logic        G;
} EntryLo_t;

typedef struct packed {
  logic        P;
  logic [27:0] zero;
  logic [ 2:0] Index;
} Index_t;

typedef struct packed {
  logic [28:0] zero;
  logic [ 2:0] Wired;
} Wired_t;

typedef struct packed {
  logic [28:0] zero;
  logic [ 2:0] Random;
} Random_t;

typedef struct packed {
  logic [18:0] VPN2;
  logic [ 7:0] ASID;
  // logic [11:0] PageMask;
  logic        G;
  logic [19:0] PFN0;
  logic [ 2:0] C0;
  logic        D0;
  logic        V0;
  logic [19:0] PFN1;
  logic [ 2:0] C1;
  logic        D1;
  logic        V1;
} TLB_t;

`endif
