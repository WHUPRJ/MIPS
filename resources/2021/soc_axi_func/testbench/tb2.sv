`timescale 1ns / 1ps

`define SIMULATION_PC
`define TRACE_REF_FILE "../../../../../../../cpu132_gettrace/golden_trace.txt"
`define CONFREG_NUM_REG soc_lite.u_confreg.num_data
//`define CONFREG_OPEN_TRACE soc_lite.u_confreg.open_trace
`define CONFREG_OPEN_TRACE 1'b0
`define CONFREG_NUM_MONITOR soc_lite.u_confreg.num_monitor
`define CONFREG_UART_DISPLAY soc_lite.u_confreg.write_uart_valid
`define CONFREG_UART_DATA soc_lite.u_confreg.write_uart_data
`define END_PC 32'hbfc00100

module tb2_top ();
  logic resetn;
  logic clk;

  //goio
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
    // $dumpfile("dump.vcd");
    // $dumpvars();

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
  assign debug_wb1_pc       = soc_lite.u_cpu.debug_wb1_pc;
  assign debug_wb1_rf_wen   = soc_lite.u_cpu.debug_wb1_rf_wen;
  assign debug_wb1_rf_wnum  = soc_lite.u_cpu.debug_wb1_rf_wnum;
  assign debug_wb1_rf_wdata = soc_lite.u_cpu.debug_wb1_rf_wdata;
  assign debug_wb_pc_A      = soc_lite.u_cpu.debug_wb_pc_A;

  // open the trace file;
  integer trace_ref;
  initial begin
    trace_ref = $fopen(`TRACE_REF_FILE, "r");
  end

  //get reference result in falling edge
  logic debug_end;

  logic trace_cmp_flag;
  logic [31:0] ref_wb_pc;
  logic [4:0] ref_wb_rf_wnum;
  logic [31:0] ref_wb_rf_wdata;

  typedef struct packed {
    logic trace_cmp_flag;
    logic [31:0] ref_wb_pc;
    logic [4:0] ref_wb_rf_wnum;
    logic [31:0] ref_wb_rf_wdata;
    logic [31:0] lineno;
  } TRACE_INFO;

  TRACE_INFO ref_trace[$];
  logic [31:0] lineno;

  initial begin
    lineno = 0;
    while (!$feof(
        trace_ref
    )) begin
      lineno = lineno + 1;
      $fscanf(trace_ref, "%h %h %h %h", trace_cmp_flag, ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
      if (trace_cmp_flag == 1) begin
        ref_trace.push_back({trace_cmp_flag, ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, lineno});
      end
    end
  end

  //compare result in rsing edge 
  logic        debug_wb_err;

  logic        dbg_0_rf_wen;
  logic [31:0] dbg_0_pc;
  logic [ 4:0] dbg_0_rf_wnum;
  logic [31:0] dbg_0_rf_wdata;

  logic        dbg_1_rf_wen;
  logic [31:0] dbg_1_pc;
  logic [ 4:0] dbg_1_rf_wnum;
  logic [31:0] dbg_1_rf_wdata;

  always @(posedge cpu_clk) begin
    #2;
    if (!resetn) begin
      debug_wb_err <= 1'b0;
    end else if (!debug_end) begin
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

      if (|dbg_0_rf_wen && `CONFREG_OPEN_TRACE) begin
        $display("mycpu0   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, wen= %d",
                 dbg_0_pc, dbg_0_rf_wnum, dbg_0_rf_wdata, |dbg_0_rf_wen);
      end
      if (|dbg_1_rf_wen && `CONFREG_OPEN_TRACE) begin
        $display("mycpu1   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, wen= %d",
                 dbg_1_pc, dbg_1_rf_wnum, dbg_1_rf_wdata, |dbg_1_rf_wen);
      end

      if (|dbg_0_rf_wen && dbg_0_rf_wnum != 5'd0 && `CONFREG_OPEN_TRACE) begin
        if (    (dbg_0_pc      !== ref_trace[0].ref_wb_pc      ) 
            || (dbg_0_rf_wnum  !== ref_trace[0].ref_wb_rf_wnum )
            || (dbg_0_rf_wdata !== ref_trace[0].ref_wb_rf_wdata) 
          )
          begin
          $display("--------------------------------------------------------------");
          $display("[%t] Error!!!", $time);
          $display("    reference: PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, lineno = %d",
                   ref_trace[0].ref_wb_pc, ref_trace[0].ref_wb_rf_wnum,
                   ref_trace[0].ref_wb_rf_wdata, ref_trace[0].lineno);
          $display("    mycpu0   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h", dbg_0_pc,
                   dbg_0_rf_wnum, dbg_0_rf_wdata);
          $display("    mycpu1   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h", dbg_1_pc,
                   dbg_1_rf_wnum, dbg_1_rf_wdata);
          $display("--------------------------------------------------------------");
          debug_wb_err <= 1'b1;
          #40;
          $finish;
        end else ref_trace.pop_front();
      end
      if (|dbg_1_rf_wen && dbg_1_rf_wnum != 5'd0 && `CONFREG_OPEN_TRACE) begin
        if (    (dbg_1_pc      !== ref_trace[0].ref_wb_pc      ) 
            || (dbg_1_rf_wnum  !== ref_trace[0].ref_wb_rf_wnum )
            || (dbg_1_rf_wdata !== ref_trace[0].ref_wb_rf_wdata) 
          )
          begin
          $display("--------------------------------------------------------------");
          $display("[%t] Error!!!", $time);
          $display("    reference: PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h, lineno = %d",
                   ref_trace[0].ref_wb_pc, ref_trace[0].ref_wb_rf_wnum, 
                   ref_trace[0].ref_wb_rf_wdata, ref_trace[0].lineno);
          $display("    mycpu0   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h", dbg_0_pc,
                   dbg_0_rf_wnum, dbg_0_rf_wdata);
          $display("    mycpu1   : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h", dbg_1_pc,
                   dbg_1_rf_wnum, dbg_1_rf_wdata);
          $display("--------------------------------------------------------------");
          debug_wb_err <= 1'b1;
          #40;
          $finish;
        end else ref_trace.pop_front();
      end
    end
  end

  //monitor numeric display
  logic [ 7:0] err_count;
  wire  [31:0] confreg_num_reg = `CONFREG_NUM_REG;
  logic [31:0] confreg_num_reg_r;
  always_ff @(posedge sys_clk) begin
    confreg_num_reg_r <= confreg_num_reg;
    if (!resetn) begin
      err_count <= 8'd0;
    end else if (confreg_num_reg_r != confreg_num_reg && `CONFREG_NUM_MONITOR) begin
      if (confreg_num_reg[7:0] != confreg_num_reg_r[7:0] + 1'b1) begin
        $display("--------------------------------------------------------------");
        $display("[%t] Error(%d)!!! Occurred in number 8'd%02d Functional Test Point!", $time,
                 err_count, confreg_num_reg[31:24]);
        $display("--------------------------------------------------------------");
        err_count <= err_count + 1'b1;
        $finish;
      end else if (confreg_num_reg[31:24] != confreg_num_reg_r[31:24] + 1'b1) begin
        $display("--------------------------------------------------------------");
        $display("[%t] Error(%d)!!! Unknown, Functional Test Point numbers are unequal!", $time,
                 err_count);
        $display("--------------------------------------------------------------");
        $display("==============================================================");
        err_count <= err_count + 1'b1;
        $finish;
      end else begin
        $display("----[%t] Number 8'd%02d Functional Test Point PASS!!!", $time,
                 confreg_num_reg[31:24]);
      end
    end
  end

  //monitor test
  initial begin
    $timeformat(-9, 0, " ns", 10);
    while (!resetn) #5;
    $display("==============================================================");
    $display("Test begin!");

    #10000;
    while (`CONFREG_NUM_MONITOR) begin
      #10000;
      $display("        [%t] Test is running, dbg_0_pc = 0x%8h, dbg_1_pc = 0x%8h", $time, dbg_0_pc,
               dbg_1_pc);
    end
  end

  // Uart Display
  logic uart_display;
  logic [7:0] uart_data;
  assign uart_display = `CONFREG_UART_DISPLAY;
  assign uart_data    = `CONFREG_UART_DATA;

  always_ff @(posedge sys_clk) begin
    if (uart_display) begin
      if (uart_data == 8'hff) begin
        ;  //$finish;
      end else begin
        $write("%c", uart_data);
      end
    end
  end

  //test end
  wire global_err = debug_wb_err || (err_count != 8'd0);
  wire test_end = (dbg_0_pc == `END_PC) || (dbg_1_pc == `END_PC) || (uart_display && uart_data == 8'hff);
  always @(posedge cpu_clk) begin
    if (!resetn) begin
      debug_end <= 1'b0;
    end else if (test_end && !debug_end) begin
      debug_end <= 1'b1;
      $display("==============================================================");
      $display("Test end!");
      #40;
      $fclose(trace_ref);
      if (global_err) begin
        $display("Fail!!!Total %d errors!", err_count);
      end else begin
        $display("----PASS!!!");
      end
      $finish;
    end
  end
endmodule
