module myBuffer0 #(
    parameter WIDTH = 8
) (
    input                    clk,
    input                    rst,
    input  logic [WIDTH-1:0] data,
    input  logic             en,
    output logic [WIDTH-1:0] bdata
);
  logic [WIDTH-1:0] data1;
  
  ffenr #(WIDTH) data_ff (clk, rst, data, en, data1);
  
  assign bdata = en ? data : data1;
endmodule
