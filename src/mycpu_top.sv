`include "defines.svh"

`include "AXI.svh"
`include "CP0.svh"
`include "DCache.svh"
`include "ICache.svh"

module mycpu_top (
    input wire [5:0] ext_int,  //high active

    input wire aclk,
    input wire aresetn, //low active

    output wire [ 3:0] arid,
    output wire [31:0] araddr,
    output wire [ 3:0] arlen,
    output wire [ 2:0] arsize,
    output wire [ 1:0] arburst,
    output wire [ 1:0] arlock,
    output wire [ 3:0] arcache,
    output wire [ 2:0] arprot,
    output wire        arvalid,
    input  wire        arready,

    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    output wire [ 3:0] awid,
    output wire [31:0] awaddr,
    output wire [ 3:0] awlen,
    output wire [ 2:0] awsize,
    output wire [ 1:0] awburst,
    output wire [ 1:0] awlock,
    output wire [ 3:0] awcache,
    output wire [ 2:0] awprot,
    output wire        awvalid,
    input  wire        awready,

    output wire [ 3:0] wid,
    output wire [31:0] wdata,
    output wire [ 3:0] wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    input  wire [3:0] bid,
    input  wire [1:0] bresp,
    input  wire       bvalid,
    output wire       bready,

    //debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,

    output wire [31:0] debug_wb1_pc,
    output wire [ 3:0] debug_wb1_rf_wen,
    output wire [ 4:0] debug_wb1_rf_wnum,
    output wire [31:0] debug_wb1_rf_wdata,

    output wire debug_wb_pc_A
);

  AXIRead_i  axi_read ();
  AXIWrite_i axi_write ();

  SRAM_RO_AXI_i inst_axi ();
  SRAM_RO_AXI_i rdata_axi ();
  SRAM_W_AXI_i  wdata_axi ();

  ICache_i icache ();
  DCache_i dcache ();

  sramro_i inst ();
  sram_i   data ();
  
  CacheOp_t cache_op;

  logic        C0_int;
  logic [4:0]  C0_addr;
  logic [2:0]  C0_sel;
  word_t       C0_rdata;
  logic        C0_we;
  word_t       C0_wdata;
  EXCEPTION_t  C0_exception;
  word_t       C0_ERETPC;
  logic        C0_Bev;
  logic [19:0] C0_EBase;
  logic [2:0]  K0;
  logic        in_kernel;
  Random_t     c0_Random;
  Index_t      c0_Index;
  EntryHi_t    c0_EntryHi;
  // PageMask_t   c0_PageMask;
  EntryLo_t    c0_EntryLo1;
  EntryLo_t    c0_EntryLo0;
  EntryHi_t    tlb_EntryHi;
  // PageMask_t   tlb_PageMask;
  EntryLo_t    tlb_EntryLo1;
  EntryLo_t    tlb_EntryLo0;
  Index_t      tlb_Index;

  logic iTLBRefill;
  logic iTLBInvalid;
  logic iAddressError;
  logic dTLBRefill;
  logic dTLBInvalid;
  logic dTLBModified;
  logic dAddressError;
  logic tlb_tlbwi;
  logic tlb_tlbwr;
  logic tlb_tlbp;
  logic c0_tlbr;
  logic c0_tlbp;


  AXI axi (
      .clk     (aclk),
      .rst     (~aresetn),
      .AXIRead (axi_read.master),
      .AXIWrite(axi_write.master),
      .inst    (inst_axi.slave),
      .rdata   (rdata_axi.slave),
      .wdata   (wdata_axi.slave)
  );

  MMU mmu (
      .clk          (aclk),
      .rst          (~aresetn),
      .ic           (icache.mmu),
      .dc           (dcache.mmu),
      .inst         (inst.slave),
      .data         (data.slave),
      .cacheOp      (cache_op),
      .inst_axi     (inst_axi.master),
      .rdata_axi    (rdata_axi.master),
      .wdata_axi    (wdata_axi.master),
      .K0           (K0),
      .in_kernel    (in_kernel),
      .tlbwi        (tlb_tlbwi),
      .tlbwr        (tlb_tlbwr),
      .tlbp         (tlb_tlbp),
      .c0_Random    (c0_Random),
      .c0_Index     (c0_Index),
      .c0_EntryHi   (c0_EntryHi),
      // .c0_PageMask (c0_PageMask),
      .c0_EntryLo1  (c0_EntryLo1),
      .c0_EntryLo0  (c0_EntryLo0),
      .EntryHi      (tlb_EntryHi),
      // .PageMask    (tlb_PageMask),
      .EntryLo1     (tlb_EntryLo1),
      .EntryLo0     (tlb_EntryLo0),
      .Index        (tlb_Index),
      .iTLBRefill   (iTLBRefill),
      .iTLBInvalid  (iTLBInvalid),
      .iAddressError(iAddressError),
      .dTLBRefill   (dTLBRefill),
      .dTLBInvalid  (dTLBInvalid),
      .dTLBModified (dTLBModified),
      .dAddressError(dAddressError)
  );

  ICache ICache (
      .clk (aclk),
      .rst (~aresetn),
      .port(icache.cache)
  );

  DCache DCache (
      .clk (aclk),
      .rst (~aresetn),
      .port(dcache.cache)
  );

  CP0 cp0 (
      .clk         (aclk),
      .rst         (~aresetn),
      .addr        (C0_addr),
      .sel         (C0_sel),
      .rdata       (C0_rdata),
      .en          (C0_we),
      .wdata       (C0_wdata),
      .exception   (C0_exception),
      .EPC         (C0_ERETPC),
      .Bev         (C0_Bev),
      .EBase       (C0_EBase),
      .ext_int     (ext_int),
      .interrupt   (C0_int),
      .tlbr        (c0_tlbr),
      .tlbp        (c0_tlbp),
      .K0          (K0),
      .in_kernel   (in_kernel),
      .Random      (c0_Random),
      .Index       (c0_Index),
      .EntryHi     (c0_EntryHi),
      // .PageMask    (c0_PageMask),
      .EntryLo1    (c0_EntryLo1),
      .EntryLo0    (c0_EntryLo0),
      .tlb_EntryHi (tlb_EntryHi),
      // .tlb_PageMask(tlb_PageMask),
      .tlb_EntryLo1(tlb_EntryLo1),
      .tlb_EntryLo0(tlb_EntryLo0),
      .tlb_Index   (tlb_Index)
  );

  Datapath datapath (
      .clk     (aclk),
      .rst     (~aresetn),
      .fetch_i (inst.master),
      .mem_i   (data.master),
      .cache_op(cache_op),

      .iTLBRefill   (iTLBRefill),
      .iTLBInvalid  (iTLBInvalid),
      .iAddressError(iAddressError),
      .dTLBRefill   (dTLBRefill),
      .dTLBInvalid  (dTLBInvalid),
      .dTLBModified (dTLBModified),
      .dAddressError(dAddressError),
      .tlb_tlbwi    (tlb_tlbwi),
      .tlb_tlbwr    (tlb_tlbwr),
      .tlb_tlbp     (tlb_tlbp),
      .c0_tlbr      (c0_tlbr),
      .c0_tlbp      (c0_tlbp),

      .C0_int      (C0_int),
      .C0_addr     (C0_addr),
      .C0_sel      (C0_sel),
      .C0_rdata    (C0_rdata),
      .C0_we       (C0_we),
      .C0_wdata    (C0_wdata),
      .C0_exception(C0_exception),
      .C0_ERETPC   (C0_ERETPC),
      .C0_Bev      (C0_Bev),
      .C0_EBase    (C0_EBase),
      .C0_kernel   (in_kernel),

      .debug_wb_pc       (debug_wb_pc),
      .debug_wb_rf_wen   (debug_wb_rf_wen),
      .debug_wb_rf_wnum  (debug_wb_rf_wnum),
      .debug_wb_rf_wdata (debug_wb_rf_wdata),
      .debug_wb1_pc      (debug_wb1_pc),
      .debug_wb1_rf_wen  (debug_wb1_rf_wen),
      .debug_wb1_rf_wnum (debug_wb1_rf_wnum),
      .debug_wb1_rf_wdata(debug_wb1_rf_wdata),
      .debug_wb_pc_A     (debug_wb_pc_A)
  );

  assign axi_read.AXIReadData.arready   = arready;
  assign axi_read.AXIReadData.rid       = rid;
  assign axi_read.AXIReadData.rdata     = rdata;
  assign axi_read.AXIReadData.rresp     = rresp;
  assign axi_read.AXIReadData.rlast     = rlast;
  assign axi_read.AXIReadData.rvalid    = rvalid;

  assign arid                           = axi_read.AXIReadAddr.arid;
  assign araddr                         = axi_read.AXIReadAddr.araddr;
  assign arlen                          = axi_read.AXIReadAddr.arlen;
  assign arsize                         = axi_read.AXIReadAddr.arsize;
  assign arburst                        = axi_read.AXIReadAddr.arburst;
  assign arlock                         = axi_read.AXIReadAddr.arlock;
  assign arcache                        = axi_read.AXIReadAddr.arcache;
  assign arprot                         = axi_read.AXIReadAddr.arprot;
  assign arvalid                        = axi_read.AXIReadAddr.arvalid;
  assign rready                         = axi_read.AXIReadAddr.rready;

  assign axi_write.AXIWriteData.awready = awready;
  assign axi_write.AXIWriteData.wready  = wready;
  assign axi_write.AXIWriteData.bid     = bid;
  assign axi_write.AXIWriteData.bresp   = bresp;
  assign axi_write.AXIWriteData.bvalid  = bvalid;

  assign awid                           = axi_write.AXIWriteAddr.awid;
  assign awaddr                         = axi_write.AXIWriteAddr.awaddr;
  assign awlen                          = axi_write.AXIWriteAddr.awlen;
  assign awsize                         = axi_write.AXIWriteAddr.awsize;
  assign awburst                        = axi_write.AXIWriteAddr.awburst;
  assign awlock                         = axi_write.AXIWriteAddr.awlock;
  assign awcache                        = axi_write.AXIWriteAddr.awcache;
  assign awprot                         = axi_write.AXIWriteAddr.awprot;
  assign awvalid                        = axi_write.AXIWriteAddr.awvalid;
  assign wid                            = axi_write.AXIWriteAddr.wid;
  assign wdata                          = axi_write.AXIWriteAddr.wdata;
  assign wstrb                          = axi_write.AXIWriteAddr.wstrb;
  assign wlast                          = axi_write.AXIWriteAddr.wlast;
  assign wvalid                         = axi_write.AXIWriteAddr.wvalid;
  assign bready                         = axi_write.AXIWriteAddr.bready;

endmodule
