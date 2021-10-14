`include "defines.svh"

// SRAM interface for IDCache/MMU <-> AXI
interface SRAM_RO_AXI_i;
  logic        req;
  word_t       addr;
  logic  [3:0] len;
  logic  [2:0] size;
  logic        addr_ok;
  logic        data_ok;
  word_t       rdata;
  logic        rvalid;

  modport master(output req, addr, len, size, input addr_ok, data_ok, rdata, rvalid);
  modport slave(input req, addr, len, size, output addr_ok, data_ok, rdata, rvalid);

endinterface
