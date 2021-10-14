`include "DCache.svh"

interface DCache_i;
  logic          req;
  logic          valid;
  DCIndexL_t     index;
  DCTagL_t       tag1;
  logic    [1:0] sel1;    // addr[3:2]
  logic          hit;
  logic          rvalid;  // MMU(AXI) -> DCache
  DCData_t       rdata;
  logic          wvalid;
  word_t         wdata;
  logic    [3:0] wstrb;
  logic          dirt_valid;
  word_t         dirt_addr;
  DCData_t       dirt_data;
  DCData_t       row;
  logic          clear;
  logic          clearIdx;
  logic          clearWb;

  modport cache(
    input  req, valid,
    input  index, tag1, sel1,
    input  rvalid, rdata, wvalid, wdata, wstrb,
    output hit, dirt_valid, dirt_addr, dirt_data, row,
    input  clear, clearIdx, clearWb
  );
  modport mmu(
    output req, valid,
    output index, tag1, sel1,
    output rvalid, rdata, wvalid, wdata, wstrb,
    input  hit, dirt_valid, dirt_addr, dirt_data, row,
    output clear, clearIdx, clearWb
  );
endinterface  //DCache_i
