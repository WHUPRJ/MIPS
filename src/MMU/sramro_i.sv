`include "defines.svh"

// SRAM interface for MMU <-> ICache
interface sramro_i ();
  logic  req;
  word_t addr;
  logic  addr_ok;
  logic  data_ok;
  word_t rdata0;
  word_t rdata1;

  modport master(output req, addr, input addr_ok, data_ok, rdata0, rdata1);
  modport slave(input req, addr, output addr_ok, data_ok, rdata0, rdata1);

endinterface
