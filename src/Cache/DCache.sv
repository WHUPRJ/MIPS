`include "defines.svh"
`include "DCache.svh"
`include "AXI.svh"

module DCache (
    input clk,
    rst,
    DCache_i.cache port
);

  /*
    read hit            => Lookup Only
    read ~hit + ~dirty  => Lookup + AXI Read
    read ~hit + dirty   => Lookup + AXI Write + AXI Read

    write hit           => Lookup Only
    write ~hit + ~dirty => Lookup + AXI Read
    write ~hit + dirty  => Lookup + AXI Write + AXI Read
  */

  // ==============================
  // ============ Vars ============
  // ==============================

  // Four way assoc bram controller:
  DCTagRAM_t  TagRAM0, TagRAM1, TagRAM2, TagRAM3;
  DCDataRAM_t DataRAM0, DataRAM1, DataRAM2, DataRAM3;

  logic [3:0] LRU[128];
  logic [3:0] nextLRU;
  logic [3:0] nowLRU;

  DCTag_t     tagOut[4];
  DCData_t    dataOut[4];
  logic [3:0] tagV;

  DCIndexL_t index1;

  logic       hit;
  logic [3:0] hitWay;
  DCData_t    cacheLine;

  logic [3:0] victim;
  logic [3:0] wen;
  logic [3:0] wen2;

  logic en2;  // en2: Lookup->Rep

  DCIndexL_t baddr;
  logic bwe1, bwe2;  // bwe1: Lookup -> Write, bwe2: Replace -> Lookup

  DCData_t wdata1[4], wdata2[4];

  logic clear;

  // ===========================
  // ======== Flip-Flop ========
  // ===========================

  ffen #(`DC_TAGL-`DC_INDEXL) index_ff (clk, port.index,   port.req, index1);
  ffen #(4)                   wen_ff   (clk, wen,          en2,      wen2);
  ffen #(1)                   clear_ff (clk, port.clearWb, en2,      clear);

  // ===============================
  // ======== State Machine ========
  // ===============================

  enum bit [1:0] { IDLE, LOOKUP, REPLACE } state, nextState;

  always_ff @(posedge clk) begin
    if (rst) state <= IDLE;
    else state <= nextState;
  end

  always_comb begin
    en2       = 1'b0;
    bwe1      = 1'b0;  // Lookup  -> Write
    bwe2      = 1'b0;  // Replace -> Lookup
    nextState = state;
    case (state)
      IDLE: begin
        if (port.req) begin
          nextState = LOOKUP;
        end
      end
      LOOKUP: begin
        if (~port.valid & ~port.clearWb) begin
          if (~port.req) begin
            nextState = IDLE;
          end
        end else begin
          if (hit & ~port.clearWb | port.clear & ~port.clearWb) begin
            if (port.wvalid) begin
              bwe1 = 1'b1;
              nextState = IDLE;
            end else begin
              if (~port.req) begin
                nextState = IDLE;
              end
            end
          end else begin
            en2 = 1'b1;
            nextState = REPLACE;
          end
        end
      end
      REPLACE: begin
        if (port.rvalid) begin
          bwe2 = 1'b1;
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
  // 在 clearWb状态下确保命中
  assign hit = |{hitWay} | port.clear & port.clearWb;

  assign cacheLine = (hitWay[0] ? dataOut[0] : `DC_DATA_LENGTH'b0)
                   | (hitWay[1] ? dataOut[1] : `DC_DATA_LENGTH'b0)
                   | (hitWay[2] ? dataOut[2] : `DC_DATA_LENGTH'b0)
                   | (hitWay[3] ? dataOut[3] : `DC_DATA_LENGTH'b0);

  assign port.hit = hit;
  assign port.row = cacheLine;

  // ==============================
  // ========== Replace ===========
  // ==============================

  // Choose Victim
  assign victim = port.clear & port.clearWb & ~port.clearIdx ? hitWay // Hit Address Writeback -> hitWay
                // Hit Index Writeback -> clear valid + dirty way
                : port.clear & port.clearWb &  port.clearIdx & tagV[0] & tagOut[0].dirty ? 4'b0001
                : port.clear & port.clearWb &  port.clearIdx & tagV[1] & tagOut[1].dirty ? 4'b0010
                : port.clear & port.clearWb &  port.clearIdx & tagV[2] & tagOut[2].dirty ? 4'b0100
                : port.clear & port.clearWb &  port.clearIdx & tagV[3] & tagOut[3].dirty ? 4'b1000
                // Normal mode
                : tagV[0]   == 0                    ? 4'b0001
                : tagV[1]   == 0                    ? 4'b0010
                : tagV[2]   == 0                    ? 4'b0100
                : tagV[3]   == 0                    ? 4'b1000
                : nowLRU[0] == 0 & ~tagOut[0].dirty ? 4'b0001
                : nowLRU[1] == 0 & ~tagOut[1].dirty ? 4'b0010
                : nowLRU[2] == 0 & ~tagOut[2].dirty ? 4'b0100
                : nowLRU[3] == 0 & ~tagOut[3].dirty ? 4'b1000
                : nowLRU[0] == 0                    ? 4'b0001
                : nowLRU[1] == 0                    ? 4'b0010
                : nowLRU[2] == 0                    ? 4'b0100
                : 4'b1000;

  assign wen = port.clear &  port.clearIdx & ~port.clearWb ? 4'b1111 // Index Invalidate
             : port.clear & ~port.clearIdx & ~port.clearWb ? hitWay  // Hit Invalidate
             : port.clear &  port.clearWb                  ? victim  // Writeback Invalidate
             : hit ? hitWay : victim;

  assign port.dirt_valid = (state == LOOKUP)
                         & |{tagV & {tagOut[3].dirty, tagOut[2].dirty, tagOut[1].dirty, tagOut[0].dirty} & victim};
  assign port.dirt_addr = {
      (victim[0] ? tagOut[0].tag : {(32-`DC_TAGL){1'b0}})
    | (victim[1] ? tagOut[1].tag : {(32-`DC_TAGL){1'b0}})
    | (victim[2] ? tagOut[2].tag : {(32-`DC_TAGL){1'b0}})
    | (victim[3] ? tagOut[3].tag : {(32-`DC_TAGL){1'b0}}),
    index1, 4'b0
  };
  assign port.dirt_data = (victim[0] ? dataOut[0] : `DC_DATA_LENGTH'b0)
                        | (victim[1] ? dataOut[1] : `DC_DATA_LENGTH'b0)
                        | (victim[2] ? dataOut[2] : `DC_DATA_LENGTH'b0)
                        | (victim[3] ? dataOut[3] : `DC_DATA_LENGTH'b0);

  // Update LRU
  assign nextLRU = port.clear & port.clearIdx ? nowLRU :
  {
    wen[3] | nowLRU[3] & ~&{nowLRU | wen},
    wen[2] | nowLRU[2] & ~&{nowLRU | wen},
    wen[1] | nowLRU[1] & ~&{nowLRU | wen},
    wen[0] | nowLRU[0] & ~&{nowLRU | wen}
  };

  always_ff @(posedge clk) begin
    if (rst) begin
      for (integer i = 0; i < 128; i++)
`ifndef VERILATOR
        LRU[i] <= 4'b0;
`else
        LRU[i] = 4'b0;
`endif
    end else begin
      if (port.req) begin
        if (state != IDLE)
          LRU[index1] <= nextLRU;
        nowLRU <= LRU[port.index];
      end
    end
  end

  // ==============================
  // ========= Block RAM ==========
  // ==============================

  mux2 #(`DC_TAGL-`DC_INDEXL) index_mux (
      index1,
      port.index,
      port.req,
      baddr
  );

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
  assign TagRAM0.wen  = (bwe1 & wen[0]) | (bwe2 & wen2[0]);
  assign TagRAM1.wen  = (bwe1 & wen[1]) | (bwe2 & wen2[1]);
  assign TagRAM2.wen  = (bwe1 & wen[2]) | (bwe2 & wen2[2]);
  assign TagRAM3.wen  = (bwe1 & wen[3]) | (bwe2 & wen2[3]);
  assign DataRAM0.wen = (bwe1 & wen[0]) | (bwe2 & wen2[0]);
  assign DataRAM1.wen = (bwe1 & wen[1]) | (bwe2 & wen2[1]);
  assign DataRAM2.wen = (bwe1 & wen[2]) | (bwe2 & wen2[2]);
  assign DataRAM3.wen = (bwe1 & wen[3]) | (bwe2 & wen2[3]);
  // 写数据
  assign TagRAM0.wdata = {port.tag1, port.wvalid, ~(port.clear | bwe2 & clear)};
  assign TagRAM1.wdata = {port.tag1, port.wvalid, ~(port.clear | bwe2 & clear)};
  assign TagRAM2.wdata = {port.tag1, port.wvalid, ~(port.clear | bwe2 & clear)};
  assign TagRAM3.wdata = {port.tag1, port.wvalid, ~(port.clear | bwe2 & clear)};

  assign DataRAM0.wdata = state == LOOKUP ? wdata1[0] : wdata2[0];
  assign DataRAM1.wdata = state == LOOKUP ? wdata1[1] : wdata2[1];
  assign DataRAM2.wdata = state == LOOKUP ? wdata1[2] : wdata2[2];
  assign DataRAM3.wdata = state == LOOKUP ? wdata1[3] : wdata2[3];

  generate
  for (genvar i = 0; i < 4; i++) begin
    always_comb begin  // wdata_x1 -> hit write, wdata_x2 -> ~hit replace write
      wdata1[i] = dataOut[i];
      wdata2[i] = port.rdata;

      if (port.wvalid) begin
        case (port.sel1)
          2'b11: begin
            if (port.wstrb[3]) wdata1[i][127:120] = port.wdata[31:24];
            if (port.wstrb[2]) wdata1[i][119:112] = port.wdata[23:16];
            if (port.wstrb[1]) wdata1[i][111:104] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata1[i][103: 96] = port.wdata[ 7: 0];
          end
          2'b10: begin
            if (port.wstrb[3]) wdata1[i][95:88] = port.wdata[31:24];
            if (port.wstrb[2]) wdata1[i][87:80] = port.wdata[23:16];
            if (port.wstrb[1]) wdata1[i][79:72] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata1[i][71:64] = port.wdata[ 7: 0];
          end
          2'b01: begin
            if (port.wstrb[3]) wdata1[i][63:56] = port.wdata[31:24];
            if (port.wstrb[2]) wdata1[i][55:48] = port.wdata[23:16];
            if (port.wstrb[1]) wdata1[i][47:40] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata1[i][39:32] = port.wdata[ 7: 0];
          end
          2'b00: begin
            if (port.wstrb[3]) wdata1[i][31:24] = port.wdata[31:24];
            if (port.wstrb[2]) wdata1[i][23:16] = port.wdata[23:16];
            if (port.wstrb[1]) wdata1[i][15: 8] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata1[i][ 7: 0] = port.wdata[ 7: 0];
          end
          default: begin end
        endcase
        case (port.sel1)
          2'b11: begin
            if (port.wstrb[3]) wdata2[i][127:120] = port.wdata[31:24];
            if (port.wstrb[2]) wdata2[i][119:112] = port.wdata[23:16];
            if (port.wstrb[1]) wdata2[i][111:104] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata2[i][103: 96] = port.wdata[ 7: 0];
          end
          2'b10: begin
            if (port.wstrb[3]) wdata2[i][95:88] = port.wdata[31:24];
            if (port.wstrb[2]) wdata2[i][87:80] = port.wdata[23:16];
            if (port.wstrb[1]) wdata2[i][79:72] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata2[i][71:64] = port.wdata[ 7: 0];
          end
          2'b01: begin
            if (port.wstrb[3]) wdata2[i][63:56] = port.wdata[31:24];
            if (port.wstrb[2]) wdata2[i][55:48] = port.wdata[23:16];
            if (port.wstrb[1]) wdata2[i][47:40] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata2[i][39:32] = port.wdata[ 7: 0];
          end
          2'b00: begin
            if (port.wstrb[3]) wdata2[i][31:24] = port.wdata[31:24];
            if (port.wstrb[2]) wdata2[i][23:16] = port.wdata[23:16];
            if (port.wstrb[1]) wdata2[i][15: 8] = port.wdata[15: 8];
            if (port.wstrb[0]) wdata2[i][ 7: 0] = port.wdata[ 7: 0];
          end
          default: begin end
        endcase
      end
    end
  end
  endgenerate

  DCIndexL_t rst_index;

  always_ff @(posedge clk) begin
    rst_index <= rst_index + 1;
  end

  DCTag_bram tag_ram0 (
      .addra(rst ? rst_index : TagRAM0.addr),
      .clka (clk),
      .dina (rst ? `DC_TAG_LENGTH'h0 : TagRAM0.wdata),
      .douta(TagRAM0.rdata),
      .wea  (rst | TagRAM0.wen)
  );
  DCTag_bram tag_ram1 (
      .addra(rst ? rst_index : TagRAM1.addr),
      .clka (clk),
      .dina (rst ? `DC_TAG_LENGTH'h0 : TagRAM1.wdata),
      .douta(TagRAM1.rdata),
      .wea  (rst | TagRAM1.wen)
  );
  DCTag_bram tag_ram2 (
      .addra(rst ? rst_index : TagRAM2.addr),
      .clka (clk),
      .dina (rst ? `DC_TAG_LENGTH'h0 : TagRAM2.wdata),
      .douta(TagRAM2.rdata),
      .wea  (rst | TagRAM2.wen)
  );
  DCTag_bram tag_ram3 (
      .addra(rst ? rst_index : TagRAM3.addr),
      .clka (clk),
      .dina (rst ? `DC_TAG_LENGTH'h0 : TagRAM3.wdata),
      .douta(TagRAM3.rdata),
      .wea  (rst | TagRAM3.wen)
  );

  DCData_bram data_ram0 (
      .addra(DataRAM0.addr),
      .clka (clk),
      .dina (DataRAM0.wdata),
      .douta(DataRAM0.rdata),
      .wea  (DataRAM0.wen)
  );
  DCData_bram data_ram1 (
      .addra(DataRAM1.addr),
      .clka (clk),
      .dina (DataRAM1.wdata),
      .douta(DataRAM1.rdata),
      .wea  (DataRAM1.wen)
  );
  DCData_bram data_ram2 (
      .addra(DataRAM2.addr),
      .clka (clk),
      .dina (DataRAM2.wdata),
      .douta(DataRAM2.rdata),
      .wea  (DataRAM2.wen)
  );
  DCData_bram data_ram3 (
      .addra(DataRAM3.addr),
      .clka (clk),
      .dina (DataRAM3.wdata),
      .douta(DataRAM3.rdata),
      .wea  (DataRAM3.wen)
  );


endmodule

