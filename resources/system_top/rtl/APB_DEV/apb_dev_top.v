/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`include "config.h"

module axi2apb_misc
(
clk,
rst_n,

axi_s_awid,
axi_s_awaddr,
axi_s_awlen,
axi_s_awsize,
axi_s_awburst,
axi_s_awlock,
axi_s_awcache,
axi_s_awprot,
axi_s_awvalid,
axi_s_awready,
axi_s_wid,
axi_s_wdata,
axi_s_wstrb,
axi_s_wlast,
axi_s_wvalid,
axi_s_wready,
axi_s_bid,
axi_s_bresp,
axi_s_bvalid,
axi_s_bready,
axi_s_arid,
axi_s_araddr,
axi_s_arlen,
axi_s_arsize,
axi_s_arburst,
axi_s_arlock,
axi_s_arcache,
axi_s_arprot,
axi_s_arvalid,
axi_s_arready,
axi_s_rid,
axi_s_rdata,
axi_s_rresp,
axi_s_rlast,
axi_s_rvalid,
axi_s_rready,

uart0_txd_i,
uart0_txd_o,
uart0_txd_oe,
uart0_rxd_i,
uart0_rxd_o,
uart0_rxd_oe,
uart0_rts_o,
uart0_dtr_o,
uart0_cts_i,
uart0_dsr_i,
uart0_dcd_i,
uart0_ri_i,

uart0_int,

uart1_rx,
uart1_tx,
uart1_int
);

parameter ADDR_APB = 20,
          DATA_APB = 8,
          L_ADDR = 64,
          L_ID   = 8,
          L_DATA = 128,
          L_MASK = 16;

input          clk;
input                  rst_n;

input  [`LID         -1 :0] axi_s_awid;
input  [`Lawaddr     -1 :0] axi_s_awaddr;
input  [`Lawlen      -1 :0] axi_s_awlen;
input  [`Lawsize     -1 :0] axi_s_awsize;
input  [`Lawburst    -1 :0] axi_s_awburst;
input  [`Lawlock     -1 :0] axi_s_awlock;
input  [`Lawcache    -1 :0] axi_s_awcache;
input  [`Lawprot     -1 :0] axi_s_awprot;
input                       axi_s_awvalid;
output                      axi_s_awready;
input  [`LID         -1 :0] axi_s_wid;
input  [`Lwdata      -1 :0] axi_s_wdata;
input  [`Lwstrb      -1 :0] axi_s_wstrb;
input                       axi_s_wlast;
input                       axi_s_wvalid;
output                      axi_s_wready;
output [`LID         -1 :0] axi_s_bid;
output [`Lbresp      -1 :0] axi_s_bresp;
output                      axi_s_bvalid;
input                       axi_s_bready;
input  [`LID         -1 :0] axi_s_arid;
input  [`Laraddr     -1 :0] axi_s_araddr;
input  [`Larlen      -1 :0] axi_s_arlen;
input  [`Larsize     -1 :0] axi_s_arsize;
input  [`Larburst    -1 :0] axi_s_arburst;
input  [`Larlock     -1 :0] axi_s_arlock;
input  [`Larcache    -1 :0] axi_s_arcache;
input  [`Larprot     -1 :0] axi_s_arprot;
input                       axi_s_arvalid;
output                      axi_s_arready;
output [`LID         -1 :0] axi_s_rid;
output [`Lrdata      -1 :0] axi_s_rdata;
output [`Lrresp      -1 :0] axi_s_rresp;
output                      axi_s_rlast;
output                      axi_s_rvalid;
input                       axi_s_rready;

input               uart0_txd_i;
output              uart0_txd_o;
output              uart0_txd_oe;
input               uart0_rxd_i;
output              uart0_rxd_o;
output              uart0_rxd_oe;
output              uart0_rts_o;
output              uart0_dtr_o;
input               uart0_cts_i;
input               uart0_dsr_i;
input               uart0_dcd_i;
input               uart0_ri_i;
output              uart0_int;

input               uart1_rx;
output              uart1_tx;
output              uart1_int;

wire                apb_ready_cpu;
wire                apb_rw_cpu;
wire                apb_psel_cpu;
wire                apb_enab_cpu;
wire [ADDR_APB-1:0] apb_addr_cpu;
wire [DATA_APB-1:0] apb_datai_cpu;
wire [DATA_APB-1:0] apb_datao_cpu;
wire                apb_clk_cpu;
wire                apb_reset_n_cpu; 
wire                apb_word_trans_cpu;
wire                apb_valid_cpu;
wire [23:0]         apb_high_24b_rd;
wire [23:0]         apb_high_24b_wr;

wire                 apb_uart0_req;
wire                 apb_uart0_ack;
wire                 apb_uart0_rw;
wire                 apb_uart0_enab;
wire                 apb_uart0_psel;
wire [ADDR_APB -1:0] apb_uart0_addr;
wire [DATA_APB -1:0] apb_uart0_datai;
wire [DATA_APB -1:0] apb_uart0_datao;

wire                 apb_uart1_req;
wire                 apb_uart1_ack;
wire                 apb_uart1_rw;
wire                 apb_uart1_enab;
wire                 apb_uart1_psel;
wire [ADDR_APB -1:0] apb_uart1_addr;
wire [DATA_APB -1:0] apb_uart1_datai;
wire [DATA_APB -1:0] apb_uart1_datao;

axi2apb_bridge AA_axi2apb_bridge_cpu 
(
.clk                (clk                ),
.rst_n              (rst_n              ),
.axi_s_awid         (axi_s_awid         ),
.axi_s_awaddr       (axi_s_awaddr       ),
.axi_s_awlen        (axi_s_awlen        ),
.axi_s_awsize       (axi_s_awsize       ),
.axi_s_awburst      (axi_s_awburst      ),
.axi_s_awlock       (axi_s_awlock       ),
.axi_s_awcache      (axi_s_awcache      ),
.axi_s_awprot       (axi_s_awprot       ),
.axi_s_awvalid      (axi_s_awvalid      ),
.axi_s_awready      (axi_s_awready      ),
.axi_s_wid          (axi_s_wid          ),
.axi_s_wdata        (axi_s_wdata        ),
.axi_s_wstrb        (axi_s_wstrb        ),
.axi_s_wlast        (axi_s_wlast        ),
.axi_s_wvalid       (axi_s_wvalid       ),
.axi_s_wready       (axi_s_wready       ),
.axi_s_bid          (axi_s_bid          ),
.axi_s_bresp        (axi_s_bresp        ),
.axi_s_bvalid       (axi_s_bvalid       ),
.axi_s_bready       (axi_s_bready       ),
.axi_s_arid         (axi_s_arid         ),
.axi_s_araddr       (axi_s_araddr       ),
.axi_s_arlen        (axi_s_arlen        ),
.axi_s_arsize       (axi_s_arsize       ),
.axi_s_arburst      (axi_s_arburst      ),
.axi_s_arlock       (axi_s_arlock       ),
.axi_s_arcache      (axi_s_arcache      ),
.axi_s_arprot       (axi_s_arprot       ),
.axi_s_arvalid      (axi_s_arvalid      ),
.axi_s_arready      (axi_s_arready      ),
.axi_s_rid          (axi_s_rid          ),
.axi_s_rdata        (axi_s_rdata        ),
.axi_s_rresp        (axi_s_rresp        ),
.axi_s_rlast        (axi_s_rlast        ),
.axi_s_rvalid       (axi_s_rvalid       ),
.axi_s_rready       (axi_s_rready       ),

.apb_word_trans     (1'b1               ),
.apb_high_24b_rd    (24'd0              ),
.apb_high_24b_wr    (                   ),
.apb_valid_cpu      (                   ),
.cpu_grant          (1'b1               ),

.apb_clk            (apb_clk_cpu        ),
.apb_reset_n        (apb_reset_n_cpu    ),
.reg_psel           (apb_psel_cpu       ),
.reg_enable         (apb_enab_cpu       ),
.reg_rw             (apb_rw_cpu         ),
.reg_addr           (apb_addr_cpu       ),
.reg_datai          (apb_datai_cpu      ),
.reg_datao          (apb_datao_cpu      ),
.reg_ready_1        (apb_ready_cpu      )
);

apb_mux2 AA_apb_mux16
(
.clk                (clk                ),
.rst_n              (rst_n              ),
.apb_ready_dma      (                   ),
.apb_rw_dma         (                   ),
.apb_addr_dma       (                   ),
.apb_psel_dma       (                   ),
.apb_enab_dma       (                   ),
.apb_wdata_dma      (                   ),
.apb_rdata_dma      (                   ),
.apb_valid_dma      (1'b0               ),
.apb_valid_cpu      (1'b1               ),
.dma_grant          (                   ),

.apb_ack_cpu        (apb_ready_cpu      ),
.apb_rw_cpu         (apb_rw_cpu         ),
.apb_addr_cpu       (apb_addr_cpu       ),
.apb_psel_cpu       (apb_psel_cpu       ),
.apb_enab_cpu       (apb_enab_cpu       ),
.apb_datai_cpu      (apb_datai_cpu      ),
.apb_datao_cpu      (apb_datao_cpu      ),
.apb_high_24b_rd    (                   ),
.apb_high_24b_wr    (                   ),
.apb_word_trans_cpu (                   ),

.apb0_req           (apb_uart0_req      ),
.apb0_ack           (apb_uart0_ack      ),
.apb0_rw            (apb_uart0_rw       ),
.apb0_psel          (apb_uart0_psel     ),
.apb0_enab          (apb_uart0_enab     ),
.apb0_addr          (apb_uart0_addr     ),
.apb0_datai         (apb_uart0_datai    ),
.apb0_datao         (apb_uart0_datao    ),
                                        
.apb1_req           (apb_uart1_req       ),
.apb1_ack           (apb_uart1_ack       ),
.apb1_rw            (apb_uart1_rw        ),
.apb1_enab          (apb_uart1_enab      ),
.apb1_psel          (apb_uart1_psel      ),
.apb1_addr          (apb_uart1_addr      ),
.apb1_datai         (apb_uart1_datai     ),
.apb1_datao         (apb_uart1_datao     )
                                        
);

//uart0
assign apb_uart0_ack = apb_uart0_enab;
UART_TOP uart0
(
.PCLK              (clk                ),
.clk_carrier       (1'b0               ),
.PRST_             (rst_n              ),
.PSEL              (apb_uart0_psel     ),
.PENABLE           (apb_uart0_enab     ),
.PADDR             (apb_uart0_addr[7:0]),
.PWRITE            (apb_uart0_rw       ),
.PWDATA            (apb_uart0_datai    ),
.URT_PRDATA        (apb_uart0_datao    ),
.INT               (uart0_int          ),
.TXD_o             (uart0_txd_o        ),
.TXD_i             (uart0_txd_i        ),
.TXD_oe            (uart0_txd_oe       ),
.RXD_o             (uart0_rxd_o        ),
.RXD_i             (uart0_rxd_i        ),
.RXD_oe            (uart0_rxd_oe       ),
.RTS               (uart0_rts_o        ),
.CTS               (uart0_cts_i        ),
.DSR               (uart0_dsr_i        ),
.DCD               (uart0_dcd_i        ),
.DTR               (uart0_dtr_o        ),
.RI                (uart0_ri_i         )
);

// uart1
assign apb_uart1_ack = apb_uart1_enab;
UART2 #(.CLKS_PER_BIT(432)) uart1(
	.clk     (clk),
	.rst     (~rst_n),
	.rx      (uart1_rx),
	.tx      (uart1_tx),
	.sel     (apb_uart1_psel),
	.en      (apb_uart1_enab),
	.addr    (apb_uart1_addr[7:0]),
	.wen     (apb_uart1_rw),
	.wdata   (apb_uart1_datai),
	.rdata   (apb_uart1_datao),
	.uart_int(uart1_int)
);


endmodule


