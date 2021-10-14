`ifndef ICACHE_SVH
`define ICACHE_SVH

`include "defines.svh"

// IC for I-Cache
`define IC_TAGL 11
`define IC_INDEXL 5
`define IC_TAG_LENGTH 22 // Tag + Valid
`define IC_DATA_LENGTH 256 // 32Bytes

typedef logic     [`IC_DATA_LENGTH-1:0] ICData_t;
typedef logic         [32-`IC_TAGL-1:0] ICTagL_t;
typedef logic [`IC_TAGL-`IC_INDEXL-1:0] ICIndexL_t;

typedef struct packed {
  ICTagL_t tag;
  logic    valid;
} ICTag_t;

typedef struct packed {
  logic      wen;
  ICIndexL_t addr;  // Index
  ICTag_t    wdata;
  ICTag_t    rdata;
} ICTagRAM_t;

typedef struct packed {
  logic      wen;
  ICIndexL_t addr;  // Index
  ICData_t   wdata;
  ICData_t   rdata;
} ICDataRAM_t;

`endif
