`ifndef DCACHE_SVH
`define DCACHE_SVH

`include "defines.svh"

// DC for D-Cache
`define DC_TAGL 11
`define DC_INDEXL 4
`define DC_TAG_LENGTH 23 // Tag + Valid + Dirty
`define DC_DATA_LENGTH 128   // 16Bytes

typedef logic     [`DC_DATA_LENGTH-1:0] DCData_t;
typedef logic         [32-`DC_TAGL-1:0] DCTagL_t;
typedef logic [`DC_TAGL-`DC_INDEXL-1:0] DCIndexL_t;

typedef struct packed {
  DCTagL_t tag;
  logic    dirty;
  logic    valid;
} DCTag_t;

typedef struct packed {
  logic      wen;
  DCIndexL_t addr;  // Index
  DCTag_t    wdata;
  DCTag_t    rdata;
} DCTagRAM_t;

typedef struct packed {
  logic      wen;
  DCIndexL_t addr;  // Index
  DCData_t   wdata;
  DCData_t   rdata;
} DCDataRAM_t;

`endif
