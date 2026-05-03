`timescale 1ns/1ps

module tb_sync_fifo;

  localparam int CLK_PERIOD_NS = 10;
  localparam int DATA_WIDTH    = 8;
  localparam int DEPTH         = 16;
  localparam int ADDR_WIDTH    = $clog2(DEPTH);

  logic clk;
  logic rst_n;

  logic                  wr_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic                  full;

  logic                  rd_en;
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  empty;

  logic [ADDR_WIDTH:0]   count;

  int errors;

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .wr_data (wr_data),
    .full    (full),
    .rd_en   (rd_en),
    .rd_data (rd_data),
    .empty   (empty),
    .count   (count)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  task automatic reset_dut();
    begin
      rst_n   = 1'b0;
      wr_en   = 1'b0;
      wr_data = '0;
      rd_en   = 1'b0;
      errors  = 0;

      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

    task automatic fifo_write(input logic [7:0] data);
  begin
    @(negedge clk);
    wr_en   = 1'b1;
    wr_data = data;
    rd_en   = 1'b0;

    @(negedge clk);
    wr_en   = 1'b0;
    wr_data = '0;

    #1;
  end
endtask

    task automatic fifo_read(output logic [7:0] data);
  begin
    @(negedge clk);
    rd_en = 1'b1;
    wr_en = 1'b0;

    @(negedge clk);
    rd_en = 1'b0;

    #1;
    data = rd_data;
  end
endtask

  task automatic expect_flag(
    input logic actual,
    input logic expected,
    input string name
  );
    begin
      if (actual !== expected) begin
        $display("[ERROR] %s expected=%0b actual=%0b time=%0t",
                 name, expected, actual, $time);
        errors++;
      end else begin
        $display("[PASS] %s=%0b time=%0t", name, actual, $time);
      end
    end
  endtask

  task automatic expect_count(input int expected);
    begin
      if (count !== expected) begin
        $display("[ERROR] count expected=%0d actual=%0d time=%0t",
                 expected, count, $time);
        errors++;
      end else begin
        $display("[PASS] count=%0d time=%0t", count, $time);
      end
    end
  endtask

  task automatic expect_read_data(
    input logic [7:0] actual,
    input logic [7:0] expected
  );
    begin
      if (actual !== expected) begin
        $display("[ERROR] read data expected=0x%02h actual=0x%02h time=%0t",
                 expected, actual, $time);
        errors++;
      end else begin
        $display("[PASS] read data=0x%02h time=%0t", actual, $time);
      end
    end
  endtask

  logic [7:0] rdata;

  initial begin
    $display("============================================================");
    $display("PHASE 3 SYNC FIFO TEST START");
    $display("============================================================");

    reset_dut();

    expect_flag(empty, 1'b1, "empty after reset");
    expect_flag(full,  1'b0, "full after reset");
    expect_count(0);

    // Single write/read test
    $display("------------------------------------------------------------");
    $display("Single write/read test");
    $display("------------------------------------------------------------");

    fifo_write(8'hA5);
    expect_flag(empty, 1'b0, "empty after one write");
    expect_flag(full,  1'b0, "full after one write");
    expect_count(1);

    fifo_read(rdata);
    expect_read_data(rdata, 8'hA5);
    expect_flag(empty, 1'b1, "empty after one read");
    expect_count(0);

    // Fill FIFO
    $display("------------------------------------------------------------");
    $display("Fill FIFO test");
    $display("------------------------------------------------------------");

    for (int i = 0; i < DEPTH; i++) begin
      fifo_write(i[7:0]);
    end

    expect_flag(full,  1'b1, "full after DEPTH writes");
    expect_flag(empty, 1'b0, "empty after DEPTH writes");
    expect_count(DEPTH);

    // Attempt overflow write
    $display("------------------------------------------------------------");
    $display("Overflow blocking test");
    $display("------------------------------------------------------------");

    fifo_write(8'hEE);
    expect_flag(full, 1'b1, "full after blocked overflow write");
    expect_count(DEPTH);

    // Drain FIFO and verify order
    $display("------------------------------------------------------------");
    $display("Drain FIFO order test");
    $display("------------------------------------------------------------");

    for (int i = 0; i < DEPTH; i++) begin
      fifo_read(rdata);
      expect_read_data(rdata, i[7:0]);
    end

    expect_flag(empty, 1'b1, "empty after drain");
    expect_flag(full,  1'b0, "full after drain");
    expect_count(0);

    // Attempt underflow read
    $display("------------------------------------------------------------");
    $display("Underflow blocking test");
    $display("------------------------------------------------------------");

    fifo_read(rdata);
    expect_flag(empty, 1'b1, "empty after blocked underflow read");
    expect_count(0);

    // Simultaneous read/write test
    $display("------------------------------------------------------------");
    $display("Simultaneous read/write test");
    $display("------------------------------------------------------------");

    fifo_write(8'h11);
    expect_count(1);

      @(negedge clk);
    wr_en   = 1'b1;
    wr_data = 8'h22;
    rd_en   = 1'b1;

    @(negedge clk);
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wr_data = '0;

    #1;
    expect_read_data(rd_data, 8'h11);
    expect_count(1);

    fifo_read(rdata);
    expect_read_data(rdata, 8'h22);
    expect_count(0);

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 3 PASS] Synchronous FIFO verified.");
    end else begin
      $display("[PHASE 3 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule