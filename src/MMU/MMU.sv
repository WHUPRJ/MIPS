`include "defines.svh"
`include "ICache.svh"
`include "DCache.svh"
`include "TLB.svh"
`include "AXI.svh"

module MMU (
    input clk,
    input rst,

    ICache_i.mmu ic,
    DCache_i.mmu dc,

    sramro_i.slave  inst,
    sram_i.slave    data,
    input CacheOp_t cacheOp,

    SRAM_RO_AXI_i.master inst_axi,
    SRAM_RO_AXI_i.master rdata_axi,
    SRAM_W_AXI_i.master  wdata_axi,

    // CP0
    input  logic [2:0] K0,
    input  logic       in_kernel,
    input  logic       tlbwi,       // TLBWI -> Write TLB
    input  logic       tlbwr,       // TLBWR -> Write TLB
    input  logic       tlbp,        // TLBP  -> Write CP0 Index
    input  Random_t    c0_Random,   // TLBWR
    input  Index_t     c0_Index,    // TLBWI + TLBR
    input  EntryHi_t   c0_EntryHi,  // TLBWI + F/M(ASID)
    // input  PageMask_t  c0_PageMask, // TLBWI
    input  EntryLo_t   c0_EntryLo1, // TLBWI
    input  EntryLo_t   c0_EntryLo0, // TLBWI
    output EntryHi_t   EntryHi,     // TLBR
    // output PageMask_t  PageMask,    // TLBR
    output EntryLo_t   EntryLo1,    // TLBR
    output EntryLo_t   EntryLo0,    // TLBR
    output Index_t     Index,       // TLBP

    // Exceptions
    output logic       iTLBRefill,
    output logic       iTLBInvalid,
    output logic       iAddressError,
    output logic       dTLBRefill,
    output logic       dTLBInvalid,
    output logic       dTLBModified,
    output logic       dAddressError
);

  // ======================
  // ======== Defs ========
  // ======================

  typedef enum bit [3:0] {
    I_IDLE,
    I_WA,
    I_WD1, I_WD2, I_WD3, I_WD4, I_WD5, I_WD6, I_WD7, I_WD8,
    I_REFILL,
    I_CACHE, I_CACHE_DISPATCH, I_CACHE_REFILL
  } istate_t;

  typedef enum bit [3:0] {
    DR_IDLE,
    DR_WA,
    DR_WD1, DR_WD2, DR_WD3, DR_WD4,
    DR_REFILL,
    DR_ICACHE, DR_CACHE, DR_CACHE_REFILL, DR_CACHE_REQ
  } drstate_t;

  typedef enum bit [2:0] {
    DW_IDLE,
    DW_WD1, DW_WD2, DW_WD3, DW_WD4,
    DW_WB,
    DW_WAITR
  } dwstate_t;

  typedef enum bit {
    DWA_IDLE,
    DWA_WA
  } dwastate_t;

  // ==========================
  // ======== CacheVar ========
  // ==========================

  logic icReq;  // whether there is a i-cache request
  logic icvReq; // whether the i-cache req is valid (I_CACHE_DISPATCH)

  CacheOp_t cacheOp1; // cacheOp piped for a cycle
  word_t dVA1;

  // ======================
  // ======== iVar ========
  // ======================

  word_t iVA;

  logic  iEn, iEn2;
  logic  iReq1;
  logic  iHit1;
  logic  iCached1, iCached2;
  logic  iMValid1;
  logic  iValid1;
  logic  iUser1;
  word_t iPA1, iPA2;

  word_t iD1, iD2, iD3, iD4, iD5, iD6, iD7;

  // ================================
  // ======== iState Machine ========
  // ================================

  istate_t iState;
  istate_t iNextState;

  always_ff @(posedge clk) begin
    if (rst) iState <= I_IDLE;
    else iState <= iNextState;
  end

  always_comb begin
    iEn          = 0;
    iEn2         = 0;
    iNextState   = iState;
    inst.data_ok = 0;
    inst_axi.req = 0;
    ic.clear     = 0;
    ic.clearIdx  = 0;
    case (iState)
      I_IDLE: begin
        if (icReq & ~iReq1) begin
          /*
           * Try to strip TLB-related logic from the critical path
           * When there is a cache request, if the instruction queue
           * has been filled, directly handle the request to avoid
           * deadlock , or else the request will be handled when
           * current request is finished at I-REFILL or I-WD2
           */
          iNextState = I_CACHE;
        end else if (~iValid1) iEn = 1;
        else begin
          iEn2 = 1;
          if (iCached1 & ic.hit) begin
            iEn = 1;
            inst.data_ok = 1;
          end else begin
            inst_axi.req = 1;
            if (~inst_axi.addr_ok) iNextState = I_WA;
            else iNextState = I_WD1;
          end
        end
      end
      I_WA: begin
        inst_axi.req = 1;
        if (inst_axi.addr_ok) begin
          if (~inst_axi.rvalid) iNextState = I_WD1;
          else iNextState = I_WD2;
        end
      end
      I_WD1: begin
        if (inst_axi.rvalid) iNextState = I_WD2;
      end
      I_WD2: begin
        if (inst_axi.rvalid) begin
          inst.data_ok = 1;
          if (iCached2) iNextState = I_WD3;
          // make sure icReq is handled
          else if (icReq) iNextState = I_CACHE;
          else begin
            iEn = 1;
            iNextState = I_IDLE;
          end
        end
      end
      I_WD3: begin
        if (inst_axi.rvalid) iNextState = I_WD4;
      end
      I_WD4: begin
        if (inst_axi.rvalid) iNextState = I_WD5;
      end
      I_WD5: begin
        if (inst_axi.rvalid) iNextState = I_WD6;
      end
      I_WD6: begin
        if (inst_axi.rvalid) iNextState = I_WD7;
      end
      I_WD7: begin
        if (inst_axi.rvalid) iNextState = I_WD8;
      end
      I_WD8: begin
        if (inst_axi.rvalid) iNextState = I_REFILL;
      end
      I_REFILL: begin
        // make sure icReq is handled
        if (icReq) iNextState = I_CACHE;
        else begin
          iEn = 1;
          iNextState = I_IDLE;
        end
      end
      I_CACHE: begin
        /* For "I-Cache Hit Invalid":
         *   send TLB translation request here to reduce logic on critical path
         * For "I-Cache Index Invalid" or "I-Cache Index Store Tag":
         *   I-Cache's request is send here too to sync with Hit Invalid
         *
         * Critical Signals:
         *   1. ic.req = 1'b1
         *   2. iVA    = dVA1 (use a dedicated var?)
         */

        iNextState = I_CACHE_DISPATCH;
      end
      I_CACHE_DISPATCH: begin
        /*
         * State:
         *   1. I-Cache state == LOOKUP
         *   2. TLB iCached1 iHit1 iValid1 ... is valid
         *
         * Critical Signals:
         *   1. ic.req = 1'b0
         *   2. ic.tag1 -> iEn2 -> iPA1
         *   3. ic.clear & ic.clearIdx
         */

        if (icvReq) ic.clear = 1;

        ic.clearIdx = cacheOp1[1];
        iEn2        = 1; // use iPA1 as tag

        iNextState  = I_CACHE_REFILL;
      end
      I_CACHE_REFILL: begin
        iEn        = 1;
        iNextState = I_IDLE;
      end
      default: begin iNextState = I_IDLE; end
    endcase
  end

  // ============================
  // ======== iFlip-Flop ========
  // ============================

  ffenr #(1)  ivalid_ff  (clk, rst, inst.req, iEn,  iReq1);
  ffen  #(32) iPA_ff     (clk,      iPA1,     iEn2, iPA2);
  ffen  #(1)  iCached_ff (clk,      iCached1, iEn2, iCached2);

  ffen #(32) id1_ff (clk, inst_axi.rdata, iState == I_WA | iState == I_WD1, iD1);
  ffen #(32) id2_ff (clk, inst_axi.rdata, iState == I_WD2, iD2);
  ffen #(32) id3_ff (clk, inst_axi.rdata, iState == I_WD3, iD3);
  ffen #(32) id4_ff (clk, inst_axi.rdata, iState == I_WD4, iD4);
  ffen #(32) id5_ff (clk, inst_axi.rdata, iState == I_WD5, iD5);
  ffen #(32) id6_ff (clk, inst_axi.rdata, iState == I_WD6, iD6);
  ffen #(32) id7_ff (clk, inst_axi.rdata, iState == I_WD7, iD7);

  // ===============================
  // ========== iFunction ==========
  // ===============================

  // On I_CACHE:          sending cache request
  // On I_CACHE_DISPATCH: using the same addr to clear
  assign iVA     = (iState == I_CACHE | iState == I_CACHE_DISPATCH) ? dVA1 : inst.addr;
  assign iValid1 = iReq1 & iHit1 & iMValid1 & (in_kernel | iUser1);

  assign inst.addr_ok = iEn;
  mux5 #(64) inst_rdata_mux (
      ic.row[63:0],
      ic.row[127:64],
      ic.row[191:128],
      ic.row[255:192],
      {inst_axi.rdata, iD1},
      {iState == I_WD2, iPA1[4:3]},
      {inst.rdata1, inst.rdata0}
  );

  // I-Cache req on inst query or cache instruction
  assign ic.req    = iEn | iState == I_CACHE;
  assign ic.valid  = iValid1 & iCached1;
  assign ic.index  = iVA[`IC_TAGL-1:`IC_INDEXL];
  assign ic.tag1   = iEn2 ? iPA1[31:`IC_TAGL] : iPA2[31:`IC_TAGL];
  assign ic.rvalid = inst_axi.rvalid & inst_axi.data_ok;

  mux4 #(256) ic_rdata_mux (
      {inst_axi.rdata, iD7, iD6, iD5, iD4, iD3, iD2, iD1},
      {iD6, iD5, iD4, iD3, iD2, iD1, inst_axi.rdata, iD7},
      {iD4, iD3, iD2, iD1, inst_axi.rdata, iD7, iD6, iD5},
      {iD2, iD1, inst_axi.rdata, iD7, iD6, iD5, iD4, iD3},
      iPA2[4:3],
      ic.rdata
  );

  assign inst_axi.addr = iEn2 ? iPA1 : iPA2;
  assign inst_axi.len  = (iEn2 ? iCached1 : iCached2) ? 4'b0111 : 4'b0001;
  assign inst_axi.size = 3'b010;

  assign iTLBRefill    = (iState == I_IDLE & iReq1 | iState == I_CACHE_DISPATCH & ~cacheOp1[1]) & ~iHit1;
  assign iTLBInvalid   = (iState == I_IDLE & iReq1 | iState == I_CACHE_DISPATCH & ~cacheOp1[1]) & ~iMValid1;
  assign iAddressError = (iState == I_IDLE) & iReq1 & ~in_kernel & ~iUser1;

  // ======================
  // ======== dVar ========
  // ======================

  word_t dVA;

  logic  dEn;
  logic  dReq1, dcReq1;
  logic  dHit1;
  logic  dCached1, dCached2;
  logic  dDirty1;
  logic  dMValid1;
  logic  dValid1;
  logic  dUser1;
  word_t dPA1, dPA2;
  logic [1:0] dSize1;

  logic  dEn2;
  logic  dwr1;
  logic [3:0] dWstrb1;
  word_t dWdata1;

  word_t drD1, drD2, drD3;
  logic  wdata_ok;

  word_t ddAddr1;
  logic [127:0] ddData1;

  // D-Cache Clear
  logic dClrRv, dClrReq;
  logic dDirtValid;
  logic dCEn, dCClear, dCCached;

  // ============================
  // ======== dFlip-Flop ========
  // ============================

  ffenr #(1)  dvalid_ff    (clk, rst, data.req, dEn,  dReq1);
  ffen  #(2)  dsize_ff     (clk, data.size,     dEn,  dSize1);
  ffen  #(32) dPA_ff       (clk, dPA1,          dEn2, dPA2);
  ffen  #(1)  dCached_ff   (clk, dCached1,      dEn2, dCached2);
  ffen  #(1)  dwr_ff       (clk, data.wr,       dEn2, dwr1);
  ffen  #(4)  dwstrb_ff    (clk, data.wstrb,    dEn2, dWstrb1);
  ffen  #(32) dwdata_ff    (clk, data.wdata,    dEn2, dWdata1);

  ffen  #(1) dDirtValid_ff (clk, dc.dirt_valid, dEn2, dDirtValid);
  ffenr #(1) dCCached_ff   (clk, dCClear | rst, 1'b1, dCEn, dCCached);

  // =================================
  // ======== drState Machine ========
  // =================================

  drstate_t drState;
  drstate_t drNextState;

  always_ff @(posedge clk) begin
    if (rst) drState <= DR_IDLE;
    else drState <= drNextState;
  end

  always_comb begin
    dEn           = 0;
    dEn2          = 0;
    dCEn          = 0;
    dCClear       = 0;
    drNextState   = drState;
    data.data_ok  = 0;
    rdata_axi.req = 0;
    // D-Cache 清除功能 (与 req 一起发送)
    dc.clear      = 0;
    dc.clearIdx   = 0;
    dc.clearWb    = 0;
    // 直接发送 dc.rvalid
    dClrRv        = 0;
    // 直接发送 dc.req
    dClrReq       = 0;
    case (drState)
      DR_IDLE: begin
        if (icReq) drNextState = DR_ICACHE;
        else if (dReq1 & cacheOp1[2] & (dCached1 | dCCached | cacheOp1[1])) begin
          if (cacheOp1[0]) begin
            // 不需要写回的情况
            // D-Cache 状态机处于 Lookup 阶段
            dc.clear    = 1;               // 发送清除
            dc.clearIdx = cacheOp1[1];     // 清除时清除整行或者命中对象
            drNextState = DR_CACHE_REFILL; // 进入 REFILL 等候写入完成
          end else begin
            // 需要写回
            // 此时 D-Cache 状态机处于 Lookup 状态
            // 可能是: 1. CACHE 请求第一次发送
            //        2. Index Writeback 清除一路后返回
            dc.clear    = 1;           // 发送清除
            dc.clearIdx = cacheOp1[1]; // 清除时清除整行或者命中对象
            dc.clearWb  = 1;           // 需要写回的清除
            drNextState = DR_CACHE;    // 进入 DR_CACHE 等候写入完成
            dEn2        = 1;           // 二阶段
            dCEn        = 1;           // 缓存 dCached1
          end
        end else if (dReq1 & cacheOp1[2]) begin
          // avoid deadlock when address is uncached
          drNextState = DR_CACHE_REFILL;
        end else if (~dValid1) dEn = 1;
        else begin
          dEn2 = 1;
          if (data.wr) data.data_ok = 1;
          if (data.wr & (~dCached1 | dc.hit)) drNextState = DR_REFILL;
          else if (dCached1 & dc.hit) begin
            dEn = 1;
            data.data_ok = 1;
          end else begin
            rdata_axi.req = 1;
            if (~rdata_axi.addr_ok) drNextState = DR_WA;
            else drNextState = DR_WD1;
          end
        end
      end
      DR_WA: begin
        rdata_axi.req = 1;
        if (rdata_axi.addr_ok) begin
          if (~rdata_axi.rvalid) drNextState = DR_WD1;
          else begin
            if (dCached2) drNextState = DR_WD2;
            else begin
              dEn = 1;
              data.data_ok = 1;
              drNextState = DR_IDLE;
            end
          end
        end
      end
      DR_WD1: begin
        if (rdata_axi.rvalid) begin
          if (~dwr1) data.data_ok = 1;
          if (dCached2) drNextState = DR_WD2;
          else begin
            dEn = 1;
            drNextState = DR_IDLE;
          end
        end
      end
      DR_WD2: begin
        if (rdata_axi.rvalid) drNextState = DR_WD3;
      end
      DR_WD3: begin
        if (rdata_axi.rvalid) drNextState = DR_WD4;
      end
      DR_WD4: begin
        if (rdata_axi.rvalid) drNextState = DR_REFILL;
      end
      DR_REFILL: begin
        if (wdata_ok) begin
          dEn = 1;
          drNextState = DR_IDLE;
        end
      end
      DR_ICACHE: begin
        /*
         * 该状态是 I-CACHE 的清除指令
         *    当 iState == I_CACHE_REFILL 代表下一个周期恢复正常工作
         */
        if (iState == I_CACHE_REFILL) begin
          data.data_ok = 1;
          dEn          = 1;
          drNextState  = DR_IDLE;
        end
      end
      DR_CACHE: begin
        // WriteBack
        // D-Cache: state == REPLACE
        if (wdata_ok) begin
          dClrRv   = 1; // 直接发送 dc.rvalid 通知可写
          // Why cann't I send dc.clear HERE ???
          // dc.clear = 1;
          if (cacheOp1[1]) begin
            // Clear by Index
            if (dDirtValid)
              drNextState = DR_CACHE_REQ; // 重新进入准备其它路的清除
            else
              drNextState = DR_CACHE_REFILL; // 清除完了
          end else begin
            // Clear by Address
            drNextState = DR_CACHE_REFILL; // 进入 REFILL 等候写入完成
          end
        end
      end
      DR_CACHE_REFILL: begin
        dCClear      = 1;
        dEn          = 1;
        drNextState  = DR_IDLE;
        data.data_ok = 1;
      end
      DR_CACHE_REQ: begin
        dClrReq     = 1;
        drNextState = DR_IDLE;
      end
      default: begin drNextState = DR_IDLE; end
    endcase
  end

  // ================================
  // ========== dFunction ==========
  // ================================

  assign dVA     = data.addr;
  assign dcReq1  = dReq1 & (cacheOp1 == CNOP | cacheOp1[2]); // exclude I-Cache clear
  assign dValid1 = dReq1 & dHit1 & dMValid1 & (~data.wr | dDirty1) & (in_kernel | dUser1);

  assign dTLBRefill    = drState == DR_IDLE & dcReq1 & (cacheOp1 == CNOP | ~cacheOp1[1]) & ~dHit1;
  assign dTLBInvalid   = drState == DR_IDLE & dcReq1 & (cacheOp1 == CNOP | ~cacheOp1[1]) & ~dMValid1;
  assign dTLBModified  = drState == DR_IDLE & dReq1 & cacheOp1 == CNOP & data.wr & ~dDirty1;
  assign dAddressError = drState == DR_IDLE & dReq1 & cacheOp1 == CNOP & ~in_kernel & ~dUser1;

  // =============================
  // ======== drFlip-Flop ========
  // =============================

  ffen #(32) drd1_ff (
      clk,
      rdata_axi.rdata,
      drState == DR_WA | drState == DR_WD1,
      drD1
  );
  ffen #(32) drd2_ff (
      clk,
      rdata_axi.rdata,
      drState == DR_WD2,
      drD2
  );
  ffen #(32) drd3_ff (
      clk,
      rdata_axi.rdata,
      drState == DR_WD3,
      drD3
  );

  // ================================
  // ========== drFunction ==========
  // ================================

  assign data.addr_ok = dEn;
  mux5 #(32) data_rdata_mux (
      dc.row[ 31: 0],
      dc.row[ 63:32],
      dc.row[ 95:64],
      dc.row[127:96],
      rdata_axi.rdata,
      {rdata_axi.rvalid, dPA1[3:2]},
      data.rdata
  );

  // do not request when handling CACHE instruction on I-Cache
  assign dc.req    = dClrReq | dEn & (cacheOp[2] | ~|cacheOp[1:0]);
  assign dc.valid  = dValid1 & dCached1 | dc.clear;
  assign dc.index  = dEn  ? dVA[`DC_TAGL-1:`DC_INDEXL] : dVA1[`DC_TAGL-1:`DC_INDEXL];
  assign dc.tag1   = dEn2 ? dPA1[31:`DC_TAGL]          : dPA2[31:`DC_TAGL];
  assign dc.sel1   = dEn2 ? dPA1[3:2]                  : dPA2[3:2];
  assign dc.rvalid = dClrRv | rdata_axi.rvalid & rdata_axi.data_ok;
  mux4 #(128) dc_rdata_mux (
      {rdata_axi.rdata, drD3, drD2, drD1},
      {drD3, drD2, drD1, rdata_axi.rdata},
      {drD2, drD1, rdata_axi.rdata, drD3},
      {drD1, rdata_axi.rdata, drD3, drD2},
      dPA2[3:2],
      dc.rdata
  );

  assign rdata_axi.addr = dEn2 ? dPA1 : dPA2;
  assign rdata_axi.len  = (dEn2 ? dCached1 : dCached2) ? 4'b0011 : 4'b0000;
  assign rdata_axi.size = (dEn2 ? dCached1 : dCached2) ? 3'b010  : {1'b0, dSize1};

  // =================================
  // ======== dwState Machine ========
  // =================================

  dwstate_t dwState;
  dwstate_t dwNextState;

  always_ff @(posedge clk) begin
    if (rst) dwState <= DW_IDLE;
    else dwState <= dwNextState;
  end

  always_comb begin
    dwNextState      = dwState;

    wdata_axi.wdata  = 0;
    wdata_axi.wstrb  = 0;
    wdata_axi.wvalid = 0;
    wdata_axi.wlast  = 0;

    case (dwState)
      DW_IDLE: begin
        if (dEn2 & (~(dCached1 | dCEn) & data.wr
                   | (dCached1 | dCEn) & dc.dirt_valid
                                           & (~cacheOp1[2] | ~cacheOp1[0]) // WriteOnly 不允许写回
                                           & (~dc.hit | cacheOp1[2] & ~cacheOp1[0]) // Writeback 或一般情况
        )) begin
          if (dCached1 | dCEn) begin
            wdata_axi.wdata  = dc.dirt_data[31:0];
            wdata_axi.wstrb  = 4'b1111;
            wdata_axi.wvalid = 1'b1;
          end else begin
            wdata_axi.wdata  = data.wdata;
            wdata_axi.wstrb  = data.wstrb;
            wdata_axi.wvalid = 1'b1;
            wdata_axi.wlast  = 1'b1;
          end

          if (~wdata_axi.wready) dwNextState = DW_WD1;
          else begin
            if (dCached1 | dCEn) dwNextState = DW_WD2;
            else begin
              if (~wdata_axi.data_ok) dwNextState = DW_WB;
              else begin
                // fixme: AXI3 wait WA
                // if (drState == DR_REFILL) $error("drState == DR_REFILL");
                dwNextState = DW_WAITR;
              end
            end
          end
        end
      end
      DW_WD1: begin
        if (dCached2 | dCCached) begin
          wdata_axi.wdata  = ddData1[31:0];
          wdata_axi.wstrb  = 4'b1111;
          wdata_axi.wvalid = 1'b1;
        end else begin
          wdata_axi.wdata  = dWdata1;
          wdata_axi.wstrb  = dWstrb1;
          wdata_axi.wvalid = 1'b1;
          wdata_axi.wlast  = 1'b1;
        end

        if (wdata_axi.wready) begin
          if (dCached2 | dCCached) dwNextState = DW_WD2;
          else begin
            if (~wdata_axi.data_ok) dwNextState = DW_WB;
            else begin
              // fixme: AXI3 wait WA
              // if (drState != DR_REFILL) $error("drState != DR_REFILL");
              dwNextState = DW_IDLE;
            end
          end
        end
      end
      DW_WD2: begin
        wdata_axi.wdata  = ddData1[63:32];
        wdata_axi.wstrb  = 4'b1111;
        wdata_axi.wvalid = 1'b1;

        if (wdata_axi.wready) dwNextState = DW_WD3;
      end
      DW_WD3: begin
        wdata_axi.wdata  = ddData1[95:64];
        wdata_axi.wstrb  = 4'b1111;
        wdata_axi.wvalid = 1'b1;

        if (wdata_axi.wready) dwNextState = DW_WD4;
      end
      DW_WD4: begin
        wdata_axi.wdata  = ddData1[127:96];
        wdata_axi.wstrb  = 4'b1111;
        wdata_axi.wvalid = 1'b1;
        wdata_axi.wlast  = 1'b1;

        if (wdata_axi.wready) begin
          if (~wdata_axi.data_ok) dwNextState = DW_WB;
          else begin
            // fixme: AXI3 wait WA
            if (drState == DR_REFILL | drState == DR_CACHE_REFILL | drState == DR_CACHE_REQ) dwNextState = DW_IDLE;
            else dwNextState = DW_WAITR;
          end
        end
      end
      DW_WB: begin
        // TODO: goto IDLE on failure
        if (wdata_axi.data_ok) begin
          // fixme: AXI3 wait WA
          if (drState == DR_REFILL | drState == DR_CACHE_REFILL | drState == DR_CACHE_REQ) dwNextState = DW_IDLE;
          else dwNextState = DW_WAITR;
        end
      end
      DW_WAITR: begin
        if (drState == DR_REFILL | drState == DR_CACHE_REFILL | drState == DR_CACHE_REQ) dwNextState = DW_IDLE;
      end
      default: begin dwNextState = DW_IDLE; end
    endcase
  end

  assign wdata_ok = (dwNextState == DW_IDLE) | (dwNextState == DW_WAITR);

  dwastate_t dwaState;
  dwastate_t dwaNextState;

  always_ff @(posedge clk) begin
    if (rst) dwaState <= DWA_IDLE;
    else dwaState <= dwaNextState;
  end

  always_comb begin
    wdata_axi.req = 0;
    dwaNextState  = dwaState;

    case (dwaState)
      DWA_IDLE: begin
        if (dEn2 & (~(dCached1 | dCEn) & data.wr
                   | (dCached1 | dCEn) & dc.dirt_valid
                                       & (~cacheOp1[2] | ~cacheOp1[0]) // WriteOnly 不允许写回
                                       & (~dc.hit | cacheOp1[2] & ~cacheOp1[0]) // Writeback 或一般情况
        )) begin
          wdata_axi.req = 1'b1;
          if (~wdata_axi.addr_ok) dwaNextState = DWA_WA;
        end
      end
      DWA_WA: begin
        wdata_axi.req = 1'b1;
        if (wdata_axi.addr_ok) dwaNextState = DWA_IDLE;
      end
      default: begin dwaNextState = DWA_IDLE; end
    endcase
  end

  // =============================
  // ======== dwFlip-Flop ========
  // =============================

  ffen #(32) ddaddr_ff (
      clk,
      dc.dirt_addr,
      dc.dirt_valid,
      ddAddr1
  );
  ffen #(128) dddata_ff (
      clk,
      dc.dirt_data,
      dc.dirt_valid,
      ddData1
  );

  // ================================
  // ========== dwFunction ==========
  // ================================

  assign wdata_axi.addr = ((dEn2 ? dCached1 : dCached2) | dCEn) ? (dwaState == DWA_IDLE) ? dc.dirt_addr : ddAddr1 : dEn2 ? dPA1 : dPA2;
  assign wdata_axi.len  = ((dEn2 ? dCached1 : dCached2) | dCEn) ? 4'b0011 : 4'b0000;
  assign wdata_axi.size = ((dEn2 ? dCached1 : dCached2) | dCEn) ? 3'b010  : {1'b0, dSize1};
  assign dc.wvalid = dEn2 ? data.wr    : dwr1;
  assign dc.wdata  = dEn2 ? data.wdata : dWdata1;
  assign dc.wstrb  = dEn2 ? data.wstrb : dWstrb1;

  // ===============================
  // ========== CacheInst ==========
  // ===============================

  ffen #(3)  cache_op_ff (clk, cacheOp[2:0], dEn, cacheOp1[2:0]);
  ffen #(32) dVA1_ff     (clk, data.addr,    dEn, dVA1);


  assign icReq  = dReq1 & ~cacheOp1[2] & |cacheOp1[1:0];
  assign icvReq = ~iTLBRefill & ~iTLBInvalid & (iCached1 & ic.hit | cacheOp1[1]);


  // ==============================
  // ========== VA -> PA ==========
  // ==============================

  logic       tlbw;
  logic [2:0] c0_Index_u;

  assign tlbw       = tlbwi | tlbwr;
  assign c0_Index_u = tlbwr ? c0_Random[2:0] : c0_Index[2:0];

  TLB TLB (
      .clk(clk),
      .rst(rst),

      .K0         (K0),
      .tlbw       (tlbw),
      .tlbp       (tlbp),
      .c0_Index   (c0_Index_u),
      .c0_EntryHi (c0_EntryHi),
      // .c0_PageMask(c0_PageMask),
      .c0_EntryLo1(c0_EntryLo1),
      .c0_EntryLo0(c0_EntryLo0),

      .EntryHi (EntryHi),
      // .PageMask(PageMask),
      .EntryLo1(EntryLo1),
      .EntryLo0(EntryLo0),
      .Index   (Index),

      .iVAddr (iVA),
      .iPAddr (iPA1),
      .iHit   (iHit1),
      .iCached(iCached1),
      .iValid (iMValid1),
      .iUser  (iUser1),

      .dVAddr (dVA),
      .dPAddr (dPA1),
      .dHit   (dHit1),
      .dCached(dCached1),
      .dDirty (dDirty1),
      .dValid (dMValid1),
      .dUser  (dUser1)
  );

endmodule
