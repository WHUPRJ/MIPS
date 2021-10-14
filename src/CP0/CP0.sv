`include "defines.svh"
`include "CP0.svh"

module CP0 (
    input  logic        clk,
    input  logic        rst,
    input  logic  [4:0] addr,
    input  logic  [2:0] sel,
    output word_t       rdata,
    input  logic        en,
    input  word_t       wdata,

    // exception
    input  EXCEPTION_t  exception,
    output word_t       EPC,
    output logic        Bev,
    output logic [19:0] EBase,

    // int
    input  logic [5:0] ext_int,
    output logic       interrupt,

    // MMU
    input  logic       tlbr,
    input  logic       tlbp,
    output logic [2:0] K0,
    output logic       in_kernel,
    output Random_t    Random,
    output Index_t     Index,
    output EntryHi_t   EntryHi,
    output EntryLo_t   EntryLo1,
    output EntryLo_t   EntryLo0,
    input  EntryHi_t   tlb_EntryHi,
    input  EntryLo_t   tlb_EntryLo1,
    input  EntryLo_t   tlb_EntryLo0,
    input  Index_t     tlb_Index
);

  CP0_REGS_t rf_cp0;
  logic      count_lo;

  // int comb logic
  assign interrupt = (rf_cp0.Status.EXL == 1'b0)
                   & rf_cp0.Status.IE
                   & |{rf_cp0.Cause.IP & rf_cp0.Status.IM,
                       rf_cp0.Cause.TI & rf_cp0.Status.IM[7]};

  assign rf_cp0.Config.M       = 1'b1;
  assign rf_cp0.Config.zero    = 15'b0;
  assign rf_cp0.Config.BE      = 1'b0;
  assign rf_cp0.Config.AT      = 2'b0;
  assign rf_cp0.Config.AR      = 3'b0;
  assign rf_cp0.Config.MT      = 3'b001;
  assign rf_cp0.Config.zero1   = 4'b0;
  assign rf_cp0.Cause.zero1    = 14'b0;
  assign rf_cp0.Cause.IP[7:2]  = {rf_cp0.Cause.TI | ext_int[5], ext_int[4:0]};
  assign rf_cp0.Cause.zero2    = 1'b0;
  assign rf_cp0.Cause.zero3    = 2'b00;
  assign rf_cp0.Status.zero1   = 9'b0;
  assign rf_cp0.Status.zero2   = 6'b0;
  assign rf_cp0.Status.zero3   = 3'b0;
  assign rf_cp0.Status.zero4   = 2'b0;
  assign rf_cp0.EntryHi.zero   = 5'b0;
  assign rf_cp0.Wired.zero     = 29'b0;
  assign rf_cp0.EntryLo1.zero  = 6'b0;
  assign rf_cp0.EntryLo0.zero  = 6'b0;
  assign rf_cp0.Random.zero    = 29'b0;
  assign rf_cp0.Index.zero     = 28'b0;

  // Vol III Figure 9-1
  // |      31 |  30...25 |             24...22 |          21...19 |              18...16 |
  // | Config2 | MMU SIZE | iCache sets per way | iCache line size | iCache associativity |
  // |             15...13 |          12...10 |                9...7 |
  // | dCache sets per way | dCache line size | dCache associativity |
  // |                         6 |  5 |                             4 |
  // | Coprocessor 2 implemented | MD | Performance Counter registers |
  // |                           3 |                            2 |
  // | Watch registers implemented | Code compression implemented |
  // |                 1 |               0 |
  // | EJTAG implemented | FPU implemented |
  assign rf_cp0.Config1        = 32'b0_000111_000_100_011_001_011_011_0_0_0_0_0_0_0;
  assign rf_cp0.EBase.one      = 1'b1;
  assign rf_cp0.EBase.zero1    = 1'b0;
  assign rf_cp0.EBase.zero2    = 2'b0;
  assign rf_cp0.EBase.CPUNum   = 10'b0;
  assign rf_cp0.PRId           = 32'h00004220;

  always_ff @(posedge clk)
    if (rst) begin
      rf_cp0.Config.K0     = 3'b011;
      rf_cp0.EPC           = 32'h0;
      rf_cp0.Cause.BD      = 1'b0;
      rf_cp0.Cause.TI      = 1'b0;
      rf_cp0.Cause.IP[1:0] = 2'b0;
      rf_cp0.Cause.ExcCode = 5'b0;
      rf_cp0.Status.Bev    = 1'b1;
      rf_cp0.Status.IM     = 8'b0;
      rf_cp0.Status.UM     = 1'b0;
      rf_cp0.Status.EXL    = 1'b0;
      rf_cp0.Status.IE     = 1'b0;
      rf_cp0.Compare       = 32'hFFFF_FFFF;
      rf_cp0.EntryHi.VPN2  = 19'b0;
      rf_cp0.EntryHi.ASID  = 8'b0;
      rf_cp0.Count         = 32'h0;
      rf_cp0.BadVAddr      = 32'h0;
      rf_cp0.Wired.Wired   = 3'b0;
      rf_cp0.EntryLo1.PFN  = 20'b0;
      rf_cp0.EntryLo1.C    = 3'b0;
      rf_cp0.EntryLo1.D    = 1'b0;
      rf_cp0.EntryLo1.V    = 1'b0;
      rf_cp0.EntryLo1.G    = 1'b0;
      rf_cp0.EntryLo0.PFN  = 20'b0;
      rf_cp0.EntryLo0.C    = 3'b0;
      rf_cp0.EntryLo0.D    = 1'b0;
      rf_cp0.EntryLo0.V    = 1'b0;
      rf_cp0.EntryLo0.G    = 1'b0;
      rf_cp0.Index.P       = 1'b0;
      rf_cp0.Index.Index   = 3'b0;
      rf_cp0.Random.Random = 3'b111;

      rf_cp0.EBase.EBase   = 18'b0;

      count_lo             = 0;
    end else begin
      // count
      count_lo = ~count_lo;
      if (count_lo == 1) rf_cp0.Count = rf_cp0.Count + 1;

      if (en) begin
        case (addr)
          // 31: rf_cp0.DESAVE = wdata;
          // 30: rf_cp0.ErrorEPC = wdata;
          // 29: rf_cp0.TagHi = wdata;
          // 28: rf_cp0.TagLo = wdata;
          // 27: rf_cp0.CacheErr = wdata;
          // 26: rf_cp0.Errctl = wdata;
          // 25: rf_cp0.PerfCnt = wdata;
          // 24: rf_cp0.DEPC = wdata;
          // 23: rf_cp0.Debug = wdata;
          // 22: rf_cp0.unused22 = wdata;
          // 21: rf_cp0.unused21 = wdata;
          // 20: rf_cp0.unused20 = wdata;
          // 19: rf_cp0.WatchHi = wdata;
          // 18: rf_cp0.WatchLo = wdata;
          // 17: rf_cp0.LLAddr = wdata;
          16: rf_cp0.Config.K0 = wdata[2:0];
          // 15: rf_cp0.PRId = wdata;
          15: rf_cp0.EBase.EBase   = wdata[29:12];
          14: rf_cp0.EPC           = wdata;
          13: rf_cp0.Cause.IP[1:0] = wdata[9:8];
          12: begin
            rf_cp0.Status.Bev = wdata[22];
            rf_cp0.Status.IM  = wdata[15:8];
            rf_cp0.Status.UM  = wdata[4];
            rf_cp0.Status.EXL = wdata[1];
            rf_cp0.Status.IE  = wdata[0];
          end
          11: begin
            rf_cp0.Cause.TI = 0;
            rf_cp0.Compare  = wdata;
          end
          10: begin
            rf_cp0.EntryHi.VPN2 = wdata[31:13];
            rf_cp0.EntryHi.ASID = wdata[7:0];
          end
          9:  rf_cp0.Count    = wdata;
          8:  rf_cp0.BadVAddr = wdata;
          // 7:  rf_cp0.HWREna = wdata;
          6:  rf_cp0.Wired.Wired = wdata[2:0];
          // 5:  rf_cp0.PageMask.Mask = wdata[24:13];
          // 4:  rf_cp0.Context = wdata;
          3: begin
            rf_cp0.EntryLo1.PFN = wdata[25:6];
            rf_cp0.EntryLo1.C   = wdata[5:3];
            rf_cp0.EntryLo1.D   = wdata[2];
            rf_cp0.EntryLo1.V   = wdata[1];
            rf_cp0.EntryLo1.G   = wdata[0];
          end
          2: begin
            rf_cp0.EntryLo0.PFN = wdata[25:6];
            rf_cp0.EntryLo0.C   = wdata[5:3];
            rf_cp0.EntryLo0.D   = wdata[2];
            rf_cp0.EntryLo0.V   = wdata[1];
            rf_cp0.EntryLo0.G   = wdata[0];
          end
          // 1:  rf_cp0.Random = wdata;
          0: begin
            rf_cp0.Index.Index = wdata[2:0];
          end
          default: begin
          end
        endcase
      end

      if (tlbr) begin
        rf_cp0.EntryHi.VPN2  = tlb_EntryHi.VPN2;
        rf_cp0.EntryHi.ASID  = tlb_EntryHi.ASID;
        // rf_cp0.PageMask.Mask = tlb_PageMask.Mask;
        rf_cp0.EntryLo0.PFN  = tlb_EntryLo0.PFN;
        rf_cp0.EntryLo0.C    = tlb_EntryLo0.C;
        rf_cp0.EntryLo0.D    = tlb_EntryLo0.D;
        rf_cp0.EntryLo0.V    = tlb_EntryLo0.V;
        rf_cp0.EntryLo0.G    = tlb_EntryLo0.G;
        rf_cp0.EntryLo1.PFN  = tlb_EntryLo1.PFN;
        rf_cp0.EntryLo1.C    = tlb_EntryLo1.C;
        rf_cp0.EntryLo1.D    = tlb_EntryLo1.D;
        rf_cp0.EntryLo1.V    = tlb_EntryLo1.V;
        rf_cp0.EntryLo1.G    = tlb_EntryLo1.G;
      end

      if (tlbp) begin
        rf_cp0.Index.P       = tlb_Index.P;
        rf_cp0.Index.Index   = tlb_Index.Index;
      end

      rf_cp0.Random.Random = &rf_cp0.Random.Random ? rf_cp0.Wired.Wired
                                                   : rf_cp0.Random.Random + 1'b1;

      if (rf_cp0.Count == rf_cp0.Compare) rf_cp0.Cause.TI = 1;

      if (exception.ERET) rf_cp0.Status.EXL = 1'b0;
      else begin
        if (exception.ExcValid && rf_cp0.Status.EXL == 1'b0) begin
          rf_cp0.EPC           = exception.Delay ? exception.EPC - 4 : exception.EPC;
          rf_cp0.Cause.BD      = exception.Delay;
          rf_cp0.Cause.ExcCode = exception.ExcCode;
          rf_cp0.Status.EXL    = 1'b1;

          if (  exception.ExcCode == `EXCCODE_MOD
              | exception.ExcCode == `EXCCODE_TLBL
              | exception.ExcCode == `EXCCODE_TLBS
              | exception.ExcCode == `EXCCODE_ADEL
              | exception.ExcCode == `EXCCODE_ADES) begin
            rf_cp0.BadVAddr = exception.BadVAddr;
          end

          if (  exception.ExcCode == `EXCCODE_MOD
              | exception.ExcCode == `EXCCODE_TLBL
              | exception.ExcCode == `EXCCODE_TLBS) begin
            rf_cp0.EntryHi.VPN2 = exception.BadVAddr[31:13];
          end

        end
      end
    end

  always_comb
    case (addr)
      // 31: rdata = rf_cp0.DESAVE;
      // 30: rdata = rf_cp0.ErrorEPC;
      // 29: rdata = rf_cp0.TagHi;
      // 28: rdata = rf_cp0.TagLo;
      // 27: rdata = rf_cp0.CacheErr;
      // 26: rdata = rf_cp0.Errctl;
      // 25: rdata = rf_cp0.PerfCnt;
      // 24: rdata = rf_cp0.DEPC;
      // 23: rdata = rf_cp0.Debug;
      // 22: rdata = rf_cp0.unused22;
      // 21: rdata = rf_cp0.unused21;
      // 20: rdata = rf_cp0.unused20;
      // 19: rdata = rf_cp0.WatchHi;
      // 18: rdata = rf_cp0.WatchLo;
      // 17: rdata = rf_cp0.LLAddr;
      16: rdata = sel[0] ? rf_cp0.Config1 : rf_cp0.Config;
      // 15: rdata = rf_cp0.PRId;
      15: rdata = sel[0] ? rf_cp0.EBase : rf_cp0.PRId;
      14: rdata = rf_cp0.EPC;
      13: rdata = rf_cp0.Cause;
      12: rdata = rf_cp0.Status;
      11: rdata = rf_cp0.Compare;
      10: rdata = rf_cp0.EntryHi;
      9:  rdata = rf_cp0.Count;
      8:  rdata = rf_cp0.BadVAddr;
      // 7:  rdata = rf_cp0.HWREna;
      6:  rdata = rf_cp0.Wired;
      // 5:  rdata = rf_cp0.PageMask;
      5:  rdata = 32'h0;
      // 4:  rdata = rf_cp0.Context;
      3:  rdata = rf_cp0.EntryLo1;
      2:  rdata = rf_cp0.EntryLo0;
      1:  rdata = rf_cp0.Random;
      0:  rdata = rf_cp0.Index;
      default: rdata = 32'h0;
    endcase

  assign EPC      = rf_cp0.EPC;
  assign Bev      = rf_cp0.Status.Bev;
  assign EBase    = rf_cp0.EBase[31:12];

  assign K0       = rf_cp0.Config.K0;
  assign Random   = rf_cp0.Random;
  assign Index    = rf_cp0.Index;
  assign EntryHi  = rf_cp0.EntryHi;
  // assign PageMask = rf_cp0.PageMask;
  assign EntryLo1 = rf_cp0.EntryLo1;
  assign EntryLo0 = rf_cp0.EntryLo0;

  assign in_kernel = ~rf_cp0.Status.UM | rf_cp0.Status.EXL; // currently no ERL

endmodule
