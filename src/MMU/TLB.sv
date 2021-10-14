`include "defines.svh"
`include "TLB.svh"

module TLB (
    input             clk,
    input             rst,

    // CP0
    input logic [2:0] K0,
    input logic       tlbw,         // TLBWI + TLBWR
    input logic       tlbp,         // TLBP
    input logic [2:0] c0_Index,     // TLBWR + TLBWI + TLBR

    input EntryHi_t   c0_EntryHi,   // TLBWI + F/M(ASID)
    // input PageMask_t  c0_PageMask,  // TLBWI
    input EntryLo_t   c0_EntryLo1,  // TLBWI
    input EntryLo_t   c0_EntryLo0,  // TLBWI

    output EntryHi_t  EntryHi,      // TLBR
    // output PageMask_t PageMask,     // TLBR
    output EntryLo_t  EntryLo1,     // TLBR
    output EntryLo_t  EntryLo0,     // TLBR
    output Index_t    Index,        // TLBP

    // MMU
    input  word_t     iVAddr,
    output word_t     iPAddr,
    output logic      iHit,         // TLB Refill
    output logic      iCached,
    output logic      iValid,       // TLB Invalid
    output logic      iUser,        // Privilege

    input  word_t     dVAddr,
    output word_t     dPAddr,
    output logic      dHit,         // TLB Refill
    output logic      dCached,
    output logic      dDirty,       // TLB Modified
    output logic      dValid,       // TLB Invalid
    output logic      dUser         // Privilege
);

  word_t        fVAddr,  fVAddr1;
  logic  [19:0] fPAddr,  fPAddr1;
  logic         fHit,    fHit1;
  logic         fCached, fCached1;
  logic         fValid,  fValid1;

  word_t        mVAddr,  mVAddr1;
  logic  [19:0] mPAddr,  mPAddr1;
  logic         mHit,    mHit1;
  logic         mCached, mCached1;
  logic         mDirty,  mDirty1;
  logic         mValid,  mValid1;

  Index_t       Index0;

  TLB_t [7:0] TLB_entries;
  TLB_t entry;

  // CP0(TLBWI) EntryHi /*PageMask*/ EntryLo0 EntryLo1 -> TLB[Index]
  always_ff @(posedge clk) begin
    if (rst) begin
      TLB_entries <= 624'b0;
    end else if (tlbw)
      TLB_entries[c0_Index] <= {c0_EntryHi.VPN2, c0_EntryHi.ASID,
                                      // c0_PageMask.Mask,
                                      c0_EntryLo0.G & c0_EntryLo1.G,
                                      c0_EntryLo0.PFN, c0_EntryLo0.C, c0_EntryLo0.D, c0_EntryLo0.V,
                                      c0_EntryLo1.PFN, c0_EntryLo1.C, c0_EntryLo1.D, c0_EntryLo1.V};
  end
  // CP0(TLBR) Index -> EntryHi /*PageMask*/ EntryLo0 EntryLo1
  assign entry = TLB_entries[c0_Index];

  assign EntryHi.zero   = 5'b0;
  assign EntryHi.VPN2   = entry.VPN2;
  assign EntryHi.ASID   = entry.ASID;

  // assign PageMask.zero1 = 7'b0;
  // assign PageMask.Mask  = entry.PageMask;
  // assign PageMask.zero2 = 13'b0;

  assign EntryLo0.zero  = 6'b0;
  assign EntryLo0.PFN   = entry.PFN0;
  assign EntryLo0.C     = entry.C0;
  assign EntryLo0.D     = entry.D0;
  assign EntryLo0.V     = entry.V0;
  assign EntryLo0.G     = entry.G;

  assign EntryLo1.zero  = 6'b0;
  assign EntryLo1.PFN   = entry.PFN1;
  assign EntryLo1.C     = entry.C1;
  assign EntryLo1.D     = entry.D1;
  assign EntryLo1.V     = entry.V1;
  assign EntryLo1.G     = entry.G;

  // CP0(TLBP) EntryHi VPN2+ASID -> Index
  // MEM       vaddr             -> paddr
  mux2 #(20) M_VPN_mux (
      dVAddr[31:12],
      {c0_EntryHi.VPN2, 1'b0},
      tlbp,
      mVAddr[31:12]
  );
  assign mVAddr[11:0] = dVAddr[11:0];
  TLB_Lookup Lookup_M(
      .TLB_entries(TLB_entries),
      .VPN(mVAddr[31:12]),
      .ASID(c0_EntryHi.ASID),

      .PPN(mPAddr),
      .hit(mHit),
      .cached(mCached),
      .dirty(mDirty),
      .valid(mValid),
      .index(Index0)
  );
  ffen #(32) Index_ff(clk, Index0, tlbp, Index);

  // IF  vaddr -> paddr
  assign fVAddr = iVAddr;
  /* verilator lint_off PINCONNECTEMPTY */
  TLB_Lookup Lookup_F (
      .TLB_entries(TLB_entries),
      .VPN(fVAddr[31:12]),
      .ASID(c0_EntryHi.ASID),

      .PPN(fPAddr),
      .hit(fHit),
      .cached(fCached),
      .dirty(),
      .valid(fValid),
      .index()
  );
  /* verilator lint_on PINCONNECTEMPTY */

  // Output
  ffenr #(55) inst_ff(
      clk, rst,
      {fVAddr,  fPAddr,  fHit,  fCached,  fValid},
      1'b1,
      {fVAddr1, fPAddr1, fHit1, fCached1, fValid1}
  );
  always_comb begin
    if (fVAddr1 > 32'hBFFF_FFFF || fVAddr1 <= 32'h7FFF_FFFF) begin
      // kseg2 + kseg3 + kuseg -> tlb
      iPAddr  = {fPAddr1, fVAddr1[11:0]};
      iHit    = fHit1;
      iCached = fCached1;
      iValid  = fValid1;
      iUser   = ~fVAddr1[31];
    end else if (fVAddr1 > 32'h9FFF_FFFF) begin
      // kseg1 uncached
      iPAddr  = fVAddr1 & 32'h1FFF_FFFF;
      iHit    = 1'b1;
      iCached = 1'b0;
      iValid  = 1'b1;
      iUser   = 1'b0;
    end else begin
      // kseg0 -> CP0.K0
      iPAddr  = fVAddr1 & 32'h1FFF_FFFF;
      iHit    = 1'b1;
      iCached = K0[0];
      iValid  = 1'b1;
      iUser   = 1'b0;
    end
  end

  ffenr #(56) data_ff (
      clk, rst,
      {mVAddr,  mPAddr,  mHit,  mCached,  mValid,  mDirty},
      1'b1,
      {mVAddr1, mPAddr1, mHit1, mCached1, mValid1, mDirty1}
  );
  always_comb begin
    if (mVAddr1 > 32'hBFFF_FFFF || mVAddr1 <= 32'h7FFF_FFFF) begin
      // kseg2 + kseg3 + kuseg -> tlb
      dPAddr  = {mPAddr1, mVAddr1[11:0]};
      dHit    = mHit1;
      dCached = mCached1;
      dDirty  = mDirty1;
      dValid  = mValid1;
      dUser   = ~mVAddr1[31];
    end else if (mVAddr1 > 32'h9FFF_FFFF) begin
      // kseg1 uncached
      dPAddr  = mVAddr1 & 32'h1FFF_FFFF;
      dHit    = 1'b1;
      dCached = 1'b0;
      dDirty  = 1'b1;
      dValid  = 1'b1;
      dUser   = 1'b0;
    end else begin
      // kseg0 -> CP0.K0
      dPAddr  = mVAddr1 & 32'h1FFF_FFFF;
      dHit    = 1'b1;
      dCached = K0[0];
      dDirty  = 1'b1;
      dValid  = 1'b1;
      dUser   = 1'b0;
    end
  end

endmodule
