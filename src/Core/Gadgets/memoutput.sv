`include "defines.svh"

module memoutput (
    input  logic  [1:0] addr,
    input  word_t       data,
    input  logic  [1:0] size,
    input  ALR_t        alr,
    output word_t       wdata,
    output logic  [3:0] wstrb
);
  // TODO: wdata fill zero or replica
  always_comb
    casez (size)
      2'b11: begin
        wdata = data;
        wstrb = 4'b1111;
      end
      2'b10: begin
        wdata = data;
        case (addr)
          2'b11: begin
            wstrb = alr[0] ? 4'b1111 : 4'b1000;
            wdata = alr[0] ? data
                           : {data[7:0], data[31:8]};
          end
          2'b10: begin
            wstrb = alr[0] ? 4'b0111 : 4'b1100;
            wdata = alr[0] ? {data[7:0], data[31:8]}
                           : {data[15:0], data[31:16]};
          end
          2'b01: begin
            wstrb = alr[0] ? 4'b0011 : 4'b1110;
            wdata = alr[0] ? {data[15:0], data[31:16]}
                           : {data[23:0], data[31:24]};
          end
          2'b00: begin
            wstrb = alr[0] ? 4'b0001 : 4'b1111;
            wdata = alr[0] ? {data[23:0], data[31:24]}
                           : data;
          end
          default: begin wstrb = 4'b0000; end
        endcase
      end
      2'b01: begin
        wdata = {2{data[15:0]}};
        wstrb = addr[1] ? 4'b1100 : 4'b0011;
      end
      2'b00: begin
        wdata = {4{data[7:0]}};
        case (addr)
          2'b11:   wstrb = 4'b1000;
          2'b10:   wstrb = 4'b0100;
          2'b01:   wstrb = 4'b0010;
          2'b00:   wstrb = 4'b0001;
          default: wstrb = 4'b0000;
        endcase
      end
      default: begin wstrb = 4'b0000; end
    endcase
endmodule
