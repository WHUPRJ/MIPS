module myBuffer #(
    parameter WIDTH = 8
) (
    input                    clk,
    input                    rst,
    input  logic             prev_valid,
    input  logic [WIDTH-1:0] prev_data,
    input  logic             next_en,
    output logic             next_valid,
    output logic [WIDTH-1:0] next_data
);

  logic             valid;
  logic [WIDTH-1:0] data;

  ffenr #(1) valid_ff (
      clk,
      rst,
      prev_valid,
      prev_valid ^ next_en,
      valid
  );
  ffen #(WIDTH) data_ff (
      clk,
      prev_data,
      prev_valid,
      data
  );

  assign next_valid = valid | prev_valid;
  assign next_data  = valid ? data : prev_data;
endmodule
