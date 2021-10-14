`include "defines.svh"
`include "TLB.svh"

module TLB_Lookup (
    input  TLB_t     [ 7:0] TLB_entries,
    input  logic     [19:0] VPN,
    input  logic     [ 7:0] ASID,

    output logic     [19:0] PPN,
    output logic            hit,
    output logic            cached,
    output logic            dirty,
    output logic            valid,
    output Index_t          index
);

  logic [7:0] hitWay;
  for (genvar i = 0; i < 8; i++)
    // assign hitWay[i] =   ((TLB_entries[i].VPN2 & ~{7'b0, TLB_entries[i].PageMask})
    //                    == (VPN[19:1]           & ~{7'b0, TLB_entries[i].PageMask}))
    //                  & (TLB_entries[i].G | TLB_entries[i].ASID == ASID);
    assign hitWay[i] = (TLB_entries[i].VPN2 == VPN[19:1])
                     & (TLB_entries[i].G | TLB_entries[i].ASID == ASID);

  // assume: hit is unique
  assign hit        = |{hitWay};
  assign index.P    = ~hit;
  assign index.zero = 0;
  onehot_bin8 index_decoder(hitWay, index.Index);
  // always_comb for (int i = 0; i < 32; i++) index.Index |= hitWay[i] ? i : 0;

  TLB_t found;
  assign found = (hitWay[ 0] ? TLB_entries[ 0] : 78'b0)
               | (hitWay[ 1] ? TLB_entries[ 1] : 78'b0)
               | (hitWay[ 2] ? TLB_entries[ 2] : 78'b0)
               | (hitWay[ 3] ? TLB_entries[ 3] : 78'b0)
               | (hitWay[ 4] ? TLB_entries[ 4] : 78'b0)
               | (hitWay[ 5] ? TLB_entries[ 5] : 78'b0)
               | (hitWay[ 6] ? TLB_entries[ 6] : 78'b0)
               | (hitWay[ 7] ? TLB_entries[ 7] : 78'b0);

  logic parity;
  // assign parity = |{
  //   VPN[12]                       & found.PageMask[10],
  //   VPN[10] & ~found.PageMask[10] & found.PageMask[ 8],
  //   VPN[ 8] & ~found.PageMask[ 8] & found.PageMask[ 6],
  //   VPN[ 6] & ~found.PageMask[ 6] & found.PageMask[ 4],
  //   VPN[ 4] & ~found.PageMask[ 4] & found.PageMask[ 2],
  //   VPN[ 2] & ~found.PageMask[ 2] & found.PageMask[ 0],
  //   VPN[ 0] & ~found.PageMask[ 0]
  // };
  // assign parity = |{VPN & {7'b0, found.PageMask + 1'b1}};
  assign parity = VPN[0];

  logic [19:0] PFN;
  assign {PFN, cached, dirty, valid} = parity ? {found.PFN1, found.C1[0], found.D1, found.V1}
                                              : {found.PFN0, found.C0[0], found.D0, found.V0};
  // assign PPN = (VPN & {8'b0, found.PageMask}) | (PFN & ~{8'b0, found.PageMask});
  assign PPN = PFN;
endmodule
