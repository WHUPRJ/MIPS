module UART2 #(parameter CLKS_PER_BIT = 217) (
    input        clk,rst,
    input        rx,
    output reg   tx,
	input        sel,
	input        en,
	input  [7:0] addr,
	input        wen,
	input  [7:0] wdata,
	output [7:0] rdata,
	output       uart_int
);
	// address:
	//   3'b000 RDATA                  (R)
	//   3'b000 WDATA                  (W)
	//   3'b101 {6'b0, R_BUSY, W_BUSY} (R)

    // ==========
    // ====RX====
    // ==========
    reg        rx_done;
	reg  [7:0] rx_data;
	wire       rx_done_w;
    wire [7:0] recv_data_w;
	wire       rx_trigger;

	assign rx_trigger = sel & en & ~wen & ~addr[2];
    assign uart_int   = rx_done; // TODO: Control Register ?
	
	always @(posedge clk) begin
        // 接收完毕
        if (rx_done_w) begin
            rx_data   = recv_data_w; // 只在收到数据的那一个周期内写入寄存器
            rx_done = rx_done_w;     // 阻塞rx_done信号 -> UART_RX的rx_dv只会持续1个周期
        end
        // 可以开始下一个接收了
        else if (rx_trigger | rst) begin
            rx_done = 0;
        end
    end

    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_Inst(
        .i_Rst_L(~rst | ~rx_done),
        .i_Clock(clk),
        .i_RX_Serial(rx),
        .o_RX_DV(rx_done_w),
        .o_RX_Byte(recv_data_w)
    );

    // ==========
    // ====TX====
    // ==========
	
	wire tx_trigger;
    wire tx_r;
	wire tx_busy;

    reg       tx_trigger_r; // one time trigger
    reg [7:0] tx_td;

	assign tx_trigger = sel & en & wen & ~addr[2];

    always @(posedge clk) begin
        tx = tx_r;
        if (rst)
            tx_trigger_r <= 0;
        else if (tx_trigger & ~tx_busy) begin
            tx_trigger_r <= 1;
            tx_td <= wdata;
        end
        else if (tx_busy)
            tx_trigger_r <= 0;
    end

    UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_Inst(
        .i_Rst_L(~rst),
        .i_Clock(clk),
        .i_TX_DV(tx_trigger_r),
        .i_TX_Byte(tx_td),
        .o_TX_Active(tx_busy),
        .o_TX_Serial(tx_r),
        .o_TX_Done()
    );
	
    // ==============
    // ====STATUS====
    // ==============
	wire status_en = sel & en & ~wen & addr[2];
	
	assign rdata = rx_trigger ? rx_data : status_en ? {2'b0, ~tx_busy, 4'b0, rx_done} : 8'b0;
	
endmodule