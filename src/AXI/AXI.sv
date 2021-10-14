`include "AXI.svh"

module AXI (
    input clk,
    input rst,

    // AXI Read
    AXIRead_i.master AXIRead,

    // AXI Write
    AXIWrite_i.master AXIWrite,

    // ICache
    SRAM_RO_AXI_i.slave inst,

    // DCache Read
    SRAM_RO_AXI_i.slave rdata,

    // DCache Write
    SRAM_W_AXI_i.slave wdata
);

  // ==============================
  // ======= Read Response ========
  // ==============================

  always_comb begin
    inst.rdata  = AXIRead.AXIReadData.rdata;
    rdata.rdata = AXIRead.AXIReadData.rdata;

    if (AXIRead.AXIReadData.rid == 0) begin
      inst.rvalid   = AXIRead.AXIReadData.rvalid;
      inst.data_ok  = AXIRead.AXIReadData.rlast;
      rdata.rvalid  = 1'b0;
      rdata.data_ok = 1'b0;
    end else begin
      rdata.rvalid  = AXIRead.AXIReadData.rvalid;
      rdata.data_ok = AXIRead.AXIReadData.rlast;
      inst.rvalid   = 1'b0;
      inst.data_ok  = 1'b0;
    end
  end

  // ==============================
  // ======== Read Request ========
  // ==============================

  always_comb begin
    // Constants
    AXIRead.AXIReadAddr.arcache = 4'b0;
    AXIRead.AXIReadAddr.arlock  = 2'b0;
    AXIRead.AXIReadAddr.rready  = 1'b1;

    // Burst
    AXIRead.AXIReadAddr.arburst = 2'b10;  // Wrap

    AXIRead.AXIReadAddr.arvalid = rdata.req | inst.req;
    rdata.addr_ok               = AXIRead.AXIReadData.arready;
    if (rdata.req) begin
      AXIRead.AXIReadAddr.arid    = 4'b0001;
      AXIRead.AXIReadAddr.arprot  = 3'b001;
      AXIRead.AXIReadAddr.araddr  = rdata.addr;
      AXIRead.AXIReadAddr.arlen   = rdata.len;
      AXIRead.AXIReadAddr.arsize  = rdata.size;
      inst.addr_ok                = 1'b0;
    end else begin
      AXIRead.AXIReadAddr.arid    = 4'b0000;
      AXIRead.AXIReadAddr.arprot  = 3'b101;
      AXIRead.AXIReadAddr.araddr  = inst.addr;
      AXIRead.AXIReadAddr.arlen   = inst.len;
      AXIRead.AXIReadAddr.arsize  = inst.size;
      inst.addr_ok                = AXIRead.AXIReadData.arready;
    end

  end

  // ==============================
  // ======= Write Request ========
  // ==============================

  assign wdata.data_ok = AXIWrite.AXIWriteData.bvalid;
  assign wdata.wready  = AXIWrite.AXIWriteData.wready;

  always_comb begin
    AXIWrite.AXIWriteAddr.wid    = 4'b1;
    AXIWrite.AXIWriteAddr.wdata  = wdata.wdata;
    AXIWrite.AXIWriteAddr.wstrb  = wdata.wstrb;
    AXIWrite.AXIWriteAddr.wlast  = wdata.wlast;
    AXIWrite.AXIWriteAddr.wvalid = wdata.wvalid;
  end

  always_comb begin
    // Constants
    AXIWrite.AXIWriteAddr.awcache = 4'b0;
    AXIWrite.AXIWriteAddr.awlock  = 2'b0;
    AXIWrite.AXIWriteAddr.bready  = 1'b1;

    // Burst
    AXIWrite.AXIWriteAddr.awburst = 2'b01;  // Incr

    AXIWrite.AXIWriteAddr.awid    = 4'b1;
    AXIWrite.AXIWriteAddr.awprot  = 3'b001;

    AXIWrite.AXIWriteAddr.awvalid = wdata.req;
    AXIWrite.AXIWriteAddr.awaddr  = wdata.addr;
    AXIWrite.AXIWriteAddr.awlen   = wdata.len;
    AXIWrite.AXIWriteAddr.awsize  = wdata.size;
    wdata.addr_ok                 = AXIWrite.AXIWriteData.awready;
  end


endmodule
