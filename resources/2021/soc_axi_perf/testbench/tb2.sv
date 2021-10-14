`timescale 1ns / 1ps

`define CONFREG_OPEN_TRACE 1'b0
`define CONFREG_UART_DISPLAY soc_lite.u_confreg.write_uart_valid
`define CONFREG_UART_DATA soc_lite.u_confreg.write_uart_data
`define END_PC 32'hbfc00100

module tb2_top ();
  logic resetn;
  logic clk;

  //gpio
  logic [15:0] led;
  logic [1:0] led_rg0;
  logic [1:0] led_rg1;
  logic [7:0] num_csn;
  logic [6:0] num_a_g;
  logic [7:0] switch;
  logic [3:0] btn_key_col;
  logic [3:0] btn_key_row;
  logic [1:0] btn_step;
  assign switch      = 8'hff;
  assign btn_key_row = 4'd0;
  assign btn_step    = 2'd3;

  initial begin
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
  end

  initial begin
    clk = 1'b0;
    forever begin
      #5 clk = ~clk;
    end
  end

  soc_axi_lite_top2 #(
      .SIMULATION(1'b1)
  ) soc_lite (
      .resetn(resetn),
      .clk   (clk),

      //------gpio-------
      .num_csn    (num_csn),
      .num_a_g    (num_a_g),
      .led        (led),
      .led_rg0    (led_rg0),
      .led_rg1    (led_rg1),
      .switch     (switch),
      .btn_key_col(btn_key_col),
      .btn_key_row(btn_key_row),
      .btn_step   (btn_step)
  );

  //"cpu_clk" means cpu core clk
  //"sys_clk" means system clk
  //"wb" means write-back stage in pipeline
  //"rf" means regfiles in cpu
  //"w" in "wen/wnum/wdata" means writing
  logic cpu_clk;
  logic sys_clk;
  logic [31:0] debug_wb_pc;
  logic [3:0] debug_wb_rf_wen;
  logic [4:0] debug_wb_rf_wnum;
  logic [31:0] debug_wb_rf_wdata;
  logic [31:0] debug_wb1_pc;
  logic [3:0] debug_wb1_rf_wen;
  logic [4:0] debug_wb1_rf_wnum;
  logic [31:0] debug_wb1_rf_wdata;
  logic debug_wb_pc_A;

  assign cpu_clk            = soc_lite.cpu_clk;
  assign sys_clk            = soc_lite.sys_clk;
  assign debug_wb_pc        = soc_lite.debug_wb_pc;
  assign debug_wb_rf_wen    = soc_lite.debug_wb_rf_wen;
  assign debug_wb_rf_wnum   = soc_lite.debug_wb_rf_wnum;
  assign debug_wb_rf_wdata  = soc_lite.debug_wb_rf_wdata;
  assign debug_wb1_pc       = soc_lite.debug_wb1_pc;
  assign debug_wb1_rf_wen   = soc_lite.debug_wb1_rf_wen;
  assign debug_wb1_rf_wnum  = soc_lite.debug_wb1_rf_wnum;
  assign debug_wb1_rf_wdata = soc_lite.debug_wb1_rf_wdata;
  assign debug_wb_pc_A      = soc_lite.debug_wb_pc_A;

  // debug
  logic        dbg_0_rf_wen;
  logic [31:0] dbg_0_pc;
  logic [ 4:0] dbg_0_rf_wnum;
  logic [31:0] dbg_0_rf_wdata;

  logic        dbg_1_rf_wen;
  logic [31:0] dbg_1_pc;
  logic [ 4:0] dbg_1_rf_wnum;
  logic [31:0] dbg_1_rf_wdata;

  assign dbg_0_rf_wen   = debug_wb_pc_A ? debug_wb1_rf_wen : debug_wb_rf_wen;
  assign dbg_0_pc       = debug_wb_pc_A ? debug_wb1_pc : debug_wb_pc;
  assign dbg_0_rf_wnum  = debug_wb_pc_A ? debug_wb1_rf_wnum : debug_wb_rf_wnum;
  assign dbg_0_rf_wdata = debug_wb_pc_A ? debug_wb1_rf_wdata : debug_wb_rf_wdata;
  assign dbg_1_rf_wen   = debug_wb_pc_A ? debug_wb_rf_wen : debug_wb1_rf_wen;
  assign dbg_1_pc       = debug_wb_pc_A ? debug_wb_pc : debug_wb1_pc;
  assign dbg_1_rf_wnum  = debug_wb_pc_A ? debug_wb_rf_wnum : debug_wb1_rf_wnum;
  assign dbg_1_rf_wdata = debug_wb_pc_A ? debug_wb_rf_wdata : debug_wb1_rf_wdata;

  wire uart_display;
  wire [7:0] uart_data;
  assign uart_display = `CONFREG_UART_DISPLAY;
  assign uart_data    = `CONFREG_UART_DATA;

  always @(posedge sys_clk) begin
    if (uart_display) begin
      if (uart_data == 8'hff) begin
        ;  //$finish;
      end else begin
        $write("%c", uart_data);
      end
    end
  end

  //test end
  wire test_end = (dbg_0_pc == `END_PC) || (dbg_1_pc == `END_PC) || (uart_display && uart_data == 8'hff);
  always @(posedge cpu_clk)
    if (test_end) begin
      $display("");
      $display("==============================================================");
      $display("Test end!");
      $finish;
    end

endmodule
