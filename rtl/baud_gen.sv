module baud_gen #(
  parameter int DIV_WIDTH = 16
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 enable,
  input  logic [DIV_WIDTH-1:0] baud_div,

  output logic                 baud_tick
);

  logic [DIV_WIDTH-1:0] count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count     <= '0;
      baud_tick <= 1'b0;
    end else begin
      baud_tick <= 1'b0;

      if (enable) begin
        if (count == baud_div) begin
          count     <= '0;
          baud_tick <= 1'b1;
        end else begin
          count <= count + 1'b1;
        end
      end else begin
        count <= '0;
      end
    end
  end

endmodule