`include "defines.svh"

interface sram_i ();
  logic        req;
  logic        wr;
  word_t       addr;
  logic  [1:0] size;
  logic  [3:0] wstrb;
  word_t       wdata;
  logic        addr_ok;
  logic        data_ok;
  word_t       rdata;

  modport master(output req, wr, addr, size, wstrb, wdata, input addr_ok, data_ok, rdata);
  modport slave(input req, wr, addr, size, wstrb, wdata, output addr_ok, data_ok, rdata);

endinterface
