`include "ICache.svh"

interface ICache_i;
  logic      req;
  logic      valid;
  ICIndexL_t index;
  ICTagL_t   tag1;
  logic      hit;
  ICData_t   row;
  logic      rvalid;
  ICData_t   rdata;
  logic      clear;
  logic      clearIdx;

  modport cache(
    input  req,    valid,
    input  index,  tag1,
    output hit,    row,
    input  rvalid, rdata,
    input  clear,  clearIdx
  );
  modport mmu(
    output req,    valid,
    output index,  tag1,
    input  hit,    row,
    output rvalid, rdata,
    output clear,  clearIdx
  );
endinterface  //ICache_i
