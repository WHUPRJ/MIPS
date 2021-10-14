`timescale 1ns / 1ps

`define CONFREG_NUM_REG soc_lite.u_confreg.num_data
`define CONFREG_NUM_MONITOR soc_lite.u_confreg.num_monitor

`define CONFREG_UART_DISPLAY soc_lite.u_confreg.write_uart_valid
`define CONFREG_UART_DATA soc_lite.u_confreg.write_uart_data

`define END_PC 32'hbfc00100

module testbench_top ();
  logic        resetn;
  logic        clk;

  //gpio
  logic [15:0] led;
  logic [ 1:0] led_rg0;
  logic [ 1:0] led_rg1;
  logic [ 7:0] num_csn;
  logic [ 6:0] num_a_g;
  logic [ 7:0] switch;
  logic [ 3:0] btn_key_col;
  logic [ 3:0] btn_key_row;
  logic [ 1:0] btn_step;

  logic        uart_display;
  logic [ 7:0] uart_data;
  logic [31:0] confreg_num_reg;
  logic [31:0] confreg_num_reg_r;

  assign switch          = 8'hff;
  assign btn_key_row     = 4'd0;
  assign btn_step        = 2'd3;
  assign uart_display    = `CONFREG_UART_DISPLAY;
  assign uart_data       = `CONFREG_UART_DATA;
  assign confreg_num_reg = `CONFREG_NUM_REG;

  // soc clk & debug info
  logic cpu_clk;
  logic sys_clk;
  logic [31:0] debug_wb_pc;
  logic [ 3:0] debug_wb_rf_wen;
  logic [ 4:0] debug_wb_rf_wnum;
  logic [31:0] debug_wb_rf_wdata;
  logic [31:0] debug_wb1_pc;
  logic [ 3:0] debug_wb1_rf_wen;
  logic [ 4:0] debug_wb1_rf_wnum;
  logic [31:0] debug_wb1_rf_wdata;
  logic        debug_wb_pc_A;
  logic        dbg_0_rf_wen;
  logic [31:0] dbg_0_pc;
  logic [ 4:0] dbg_0_rf_wnum;
  logic [31:0] dbg_0_rf_wdata;
  logic        dbg_1_rf_wen;
  logic [31:0] dbg_1_pc;
  logic [ 4:0] dbg_1_rf_wnum;
  logic [31:0] dbg_1_rf_wdata;
  assign cpu_clk            = soc_lite.cpu_clk;
  assign sys_clk            = soc_lite.sys_clk;
  assign debug_wb_pc        = soc_lite.debug_wb_pc;
  assign debug_wb_rf_wen    = soc_lite.debug_wb_rf_wen;
  assign debug_wb_rf_wnum   = soc_lite.debug_wb_rf_wnum;
  assign debug_wb_rf_wdata  = soc_lite.debug_wb_rf_wdata;
  assign debug_wb1_pc       = soc_lite.u_cpu.debug_wb1_pc;
  assign debug_wb1_rf_wen   = soc_lite.u_cpu.debug_wb1_rf_wen;
  assign debug_wb1_rf_wnum  = soc_lite.u_cpu.debug_wb1_rf_wnum;
  assign debug_wb1_rf_wdata = soc_lite.u_cpu.debug_wb1_rf_wdata;
  assign debug_wb_pc_A      = soc_lite.u_cpu.debug_wb_pc_A;

  always @(posedge cpu_clk) begin
    if (debug_wb_pc_A) begin
      dbg_0_rf_wen   <= debug_wb1_rf_wen;
      dbg_0_pc       <= debug_wb1_pc;
      dbg_0_rf_wnum  <= debug_wb1_rf_wnum;
      dbg_0_rf_wdata <= debug_wb1_rf_wdata;

      dbg_1_rf_wen   <= debug_wb_rf_wen;
      dbg_1_pc       <= debug_wb_pc;
      dbg_1_rf_wnum  <= debug_wb_rf_wnum;
      dbg_1_rf_wdata <= debug_wb_rf_wdata;
    end else begin
      dbg_1_rf_wen   <= debug_wb1_rf_wen;
      dbg_1_pc       <= debug_wb1_pc;
      dbg_1_rf_wnum  <= debug_wb1_rf_wnum;
      dbg_1_rf_wdata <= debug_wb1_rf_wdata;

      dbg_0_rf_wen   <= debug_wb_rf_wen;
      dbg_0_pc       <= debug_wb_pc;
      dbg_0_rf_wnum  <= debug_wb_rf_wnum;
      dbg_0_rf_wdata <= debug_wb_rf_wdata;
    end
    
    if (|dbg_0_rf_wen) begin
      $display("path0 : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, wen= %d",
               dbg_0_pc, dbg_0_rf_wnum, dbg_0_rf_wdata, |dbg_0_rf_wen);
    end
    if (|dbg_1_rf_wen) begin
      $display("path1 : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, wen= %d",
               dbg_1_pc, dbg_1_rf_wnum, dbg_1_rf_wdata, |dbg_1_rf_wen);
    end
  end

  // UART
  always @(posedge sys_clk) begin
    if (uart_display) begin
      if (uart_data == 8'hff) begin
        ;  //$finish;
      end else begin
        $write("%c", uart_data);
      end
    end
  end

  // Numeric Display
  logic [7:0] err_count;
  always_ff @(posedge sys_clk) begin
    confreg_num_reg_r <= confreg_num_reg;
    if (!resetn) begin
      err_count <= 8'd0;
    end else if (confreg_num_reg_r != confreg_num_reg && `CONFREG_NUM_MONITOR) begin
      if (confreg_num_reg[7:0] != confreg_num_reg_r[7:0] + 1'b1) begin
        $display("--------------------------------------------------------------");
        $display("[%t] Error(%d)! Occurred in number 8'd%02d Functional Test Point!", $time, err_count, confreg_num_reg[31:24]);
        $display("--------------------------------------------------------------");
        err_count <= err_count + 1'b1;
      end else if (confreg_num_reg[31:24] != confreg_num_reg_r[31:24] + 1'b1) begin
        $display("--------------------------------------------------------------");
        $display("[%t] Error(%d)! Unknown, Functional Test Point numbers are unequal!", $time, err_count);
        $display("--------------------------------------------------------------");
        err_count <= err_count + 1'b1;
      end else begin
        $display("----[%t] Number 8'd%02d Functional Test Point PASS!", $time, confreg_num_reg[31:24]);
      end
    end
  end

  //test end
  logic test_end;
  assign test_end = (dbg_0_pc == `END_PC) || (dbg_1_pc == `END_PC) || (uart_display && uart_data == 8'hff);
  always @(posedge cpu_clk)
    if (test_end) begin
      if (err_count != 0) begin
        $display("");
        $display("==============================================================");
        $display("Test end with ERROR!");
      end else begin
        $display("");
        $display("==============================================================");
        $display("Test end!");
      end
      $finish;
    end

  soc_axi_lite_top #(
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

  initial begin
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end


endmodule
