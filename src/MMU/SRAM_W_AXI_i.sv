`include "defines.svh"

// SRAM interface for DCache/MMU <-> AXI
interface SRAM_W_AXI_i;
  logic        req;
  word_t       addr;
  logic  [3:0] len;
  logic  [2:0] size;
  logic  [3:0] wstrb;
  word_t       wdata;
  logic        wvalid;
  logic        wlast;
  logic        addr_ok;
  logic        data_ok; // 全部写完的响应信号
  logic        wready;// 一次写

  modport master(output req, addr, len, size, wstrb, wdata, wvalid, wlast, input addr_ok, data_ok, wready);
  modport slave(input req, addr, len, size, wstrb, wdata, wvalid, wlast, output addr_ok, data_ok, wready);

endinterface
