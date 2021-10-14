`include "defines.svh"
`include "ICache.svh"
`include "AXI.svh"

module ICache (
    input          clk,
    input          rst,
    ICache_i.cache port
);

  // ==============================
  // ============ Vars ============
  // ==============================

  // Four way assoc bram controller:
  ICTagRAM_t  TagRAM0, TagRAM1, TagRAM2, TagRAM3;
  ICDataRAM_t DataRAM0, DataRAM1, DataRAM2, DataRAM3;

  logic [3:0] LRU[64];
  logic [3:0] nextLRU;
  logic [3:0] nowLRU;

  ICTag_t     tagOut[4];
  ICData_t    dataOut[4];
  logic [3:0] tagV;

  ICIndexL_t index1;

  logic       hit;
  logic [3:0] hitWay;
  ICData_t    cacheLine;

  logic [3:0] victim;
  logic [3:0] wen;
  logic [3:0] wen2;

  logic en2; // en2: Lookup->Rep

  ICIndexL_t baddr;
  logic      bwe;

  // ===========================
  // ======== Flip-Flop ========
  // ===========================

  ffen#(`IC_TAGL-`IC_INDEXL) index_ff(clk, port.index, port.req, index1);
  ffen#(4) wen_ff(clk, wen, en2, wen2);

  // ===============================
  // ======== State Machine ========
  // ===============================

  enum bit [1:0] { IDLE, LOOKUP, REPLACE } state, nextState;

  always_ff @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= nextState;
  end

  always_comb begin
    en2 = 1'b0;
    nextState = state;
    case (state)
      IDLE: begin
        if (port.req) begin
          nextState = LOOKUP;
        end
      end
      LOOKUP: begin
        if (~port.valid | hit | port.clear) begin
          if (~port.req) begin
            nextState = IDLE;
          end
        end else begin
          en2 = 1'b1;
          nextState = REPLACE;
        end
      end
      REPLACE: begin
        if (port.rvalid) begin
          nextState = IDLE;
        end
      end
      default: begin nextState = IDLE; end
    endcase
  end

  // ==============================
  // =========== Lookup ===========
  // ==============================

  // BRAM Out
  assign tagOut[0] = TagRAM0.rdata;
  assign tagOut[1] = TagRAM1.rdata;
  assign tagOut[2] = TagRAM2.rdata;
  assign tagOut[3] = TagRAM3.rdata;

  assign dataOut[0] = DataRAM0.rdata;
  assign dataOut[1] = DataRAM1.rdata;
  assign dataOut[2] = DataRAM2.rdata;
  assign dataOut[3] = DataRAM3.rdata;

  assign tagV[0] = tagOut[0].valid;
  assign tagV[1] = tagOut[1].valid;
  assign tagV[2] = tagOut[2].valid;
  assign tagV[3] = tagOut[3].valid;

  // Hit Check
  assign hitWay[0] = tagV[0] & tagOut[0].tag == port.tag1;
  assign hitWay[1] = tagV[1] & tagOut[1].tag == port.tag1;
  assign hitWay[2] = tagV[2] & tagOut[2].tag == port.tag1;
  assign hitWay[3] = tagV[3] & tagOut[3].tag == port.tag1;
  assign hit = |{hitWay};

  assign cacheLine = (hitWay[0] ? dataOut[0] : `IC_DATA_LENGTH'b0)
                   | (hitWay[1] ? dataOut[1] : `IC_DATA_LENGTH'b0)
                   | (hitWay[2] ? dataOut[2] : `IC_DATA_LENGTH'b0)
                   | (hitWay[3] ? dataOut[3] : `IC_DATA_LENGTH'b0);

  assign port.hit = hit;
  assign port.row = cacheLine;

  // ==============================
  // ========== Replace ===========
  // ==============================

  // Choose Victim
  assign victim = tagV[0]   == 0 ? 4'b0001 :
                  tagV[1]   == 0 ? 4'b0010 :
                  tagV[2]   == 0 ? 4'b0100 :
                  tagV[3]   == 0 ? 4'b1000 :
                  nowLRU[0] == 0 ? 4'b0001 :
                  nowLRU[1] == 0 ? 4'b0010 :
                  nowLRU[2] == 0 ? 4'b0100 :
                  4'b1000;
  assign wen = (hit | port.clear) ? hitWay : victim;

  // Update LRU
  assign nextLRU = {
    wen[3] | nowLRU[3] & ~&{nowLRU | wen},
    wen[2] | nowLRU[2] & ~&{nowLRU | wen},
    wen[1] | nowLRU[1] & ~&{nowLRU | wen},
    wen[0] | nowLRU[0] & ~&{nowLRU | wen}
  };

  for (genvar i = 0; i < 64; i++)
    initial LRU[i] = 4'b0;

  always_ff @(posedge clk) begin
    if (port.req) begin
      if (state != IDLE)
        LRU[index1] <= nextLRU;
      nowLRU <= LRU[port.index];
    end
  end

  // ==============================
  // ========= Block RAM ==========
  // ==============================

  mux2 #(`IC_TAGL-`IC_INDEXL) index_mux (
      index1,
      port.index,
      port.req,
      baddr
  );
  assign bwe = state == REPLACE & port.rvalid;

  // 地址
  assign TagRAM0.addr  = baddr;
  assign TagRAM1.addr  = baddr;
  assign TagRAM2.addr  = baddr;
  assign TagRAM3.addr  = baddr;
  assign DataRAM0.addr = baddr;
  assign DataRAM1.addr = baddr;
  assign DataRAM2.addr = baddr;
  assign DataRAM3.addr = baddr;
  // 写使能
  assign TagRAM0.wen  = bwe & wen2[0] | port.clear & (wen[0] | port.clearIdx);
  assign TagRAM1.wen  = bwe & wen2[1] | port.clear & (wen[1] | port.clearIdx);
  assign TagRAM2.wen  = bwe & wen2[2] | port.clear & (wen[2] | port.clearIdx);
  assign TagRAM3.wen  = bwe & wen2[3] | port.clear & (wen[3] | port.clearIdx);
  assign DataRAM0.wen = bwe & wen2[0] | port.clear & (wen[0] | port.clearIdx);
  assign DataRAM1.wen = bwe & wen2[1] | port.clear & (wen[1] | port.clearIdx);
  assign DataRAM2.wen = bwe & wen2[2] | port.clear & (wen[2] | port.clearIdx);
  assign DataRAM3.wen = bwe & wen2[3] | port.clear & (wen[3] | port.clearIdx);
  // 写数据
  assign TagRAM0.wdata  = {port.tag1, ~port.clear};
  assign TagRAM1.wdata  = {port.tag1, ~port.clear};
  assign TagRAM2.wdata  = {port.tag1, ~port.clear};
  assign TagRAM3.wdata  = {port.tag1, ~port.clear};
  assign DataRAM0.wdata = port.rdata;
  assign DataRAM1.wdata = port.rdata;
  assign DataRAM2.wdata = port.rdata;
  assign DataRAM3.wdata = port.rdata;

  ICTag_bram tag_ram0 (
      .addra(TagRAM0.addr),
      .clka (clk),
      .dina (TagRAM0.wdata),
      .douta(TagRAM0.rdata),
      .wea  (TagRAM0.wen)
  );
  ICTag_bram tag_ram1 (
      .addra(TagRAM1.addr),
      .clka (clk),
      .dina (TagRAM1.wdata),
      .douta(TagRAM1.rdata),
      .wea  (TagRAM1.wen)
  );
  ICTag_bram tag_ram2 (
      .addra(TagRAM2.addr),
      .clka (clk),
      .dina (TagRAM2.wdata),
      .douta(TagRAM2.rdata),
      .wea  (TagRAM2.wen)
  );
  ICTag_bram tag_ram3 (
      .addra(TagRAM3.addr),
      .clka (clk),
      .dina (TagRAM3.wdata),
      .douta(TagRAM3.rdata),
      .wea  (TagRAM3.wen)
  );

  ICData_bram data_ram0 (
      .addra(DataRAM0.addr),
      .clka (clk),
      .dina (DataRAM0.wdata),
      .douta(DataRAM0.rdata),
      .wea  (DataRAM0.wen)
  );
  ICData_bram data_ram1 (
      .addra(DataRAM1.addr),
      .clka (clk),
      .dina (DataRAM1.wdata),
      .douta(DataRAM1.rdata),
      .wea  (DataRAM1.wen)
  );
  ICData_bram data_ram2 (
      .addra(DataRAM2.addr),
      .clka (clk),
      .dina (DataRAM2.wdata),
      .douta(DataRAM2.rdata),
      .wea  (DataRAM2.wen)
  );
  ICData_bram data_ram3 (
      .addra(DataRAM3.addr),
      .clka (clk),
      .dina (DataRAM3.wdata),
      .douta(DataRAM3.rdata),
      .wea  (DataRAM3.wen)
  );

endmodule
