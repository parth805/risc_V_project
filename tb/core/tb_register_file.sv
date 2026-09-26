// ============================================================================
// File: tb/core/tb_register_file.sv
// Description: Comprehensive Self-Checking Testbench for Register File
// ============================================================================

`timescale 1ns/1ps

module tb_register_file;
  logic        clk;
  logic        rst_n;
  logic [4:0]  raddr1, raddr2, waddr;
  logic        we;
  logic [31:0] wdata;
  logic [31:0] rdata1, rdata2;

  int error_count = 0;

  // DUT Instantiation
  register_file dut (
    .clk(clk),
    .rst_n(rst_n),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .we(we),
    .waddr(waddr),
    .wdata(wdata)
  );

  // Clock Generation (100MHz -> 10ns period)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("waves/tb_register_file.vcd");
    $dumpvars(0, tb_register_file);

    clk   = 0;
    rst_n = 0;
    we    = 0;
    raddr1 = 0;
    raddr2 = 0;
    waddr  = 0;
    wdata  = 0;

    $display("=================================================");
    $display(" Starting Register File Self-Checking Testbench  ");
    $display("=================================================");

    // 1. Reset Test
    #15 rst_n = 1;

    // 2. Write to x0 (Must remain 0)
    @(posedge clk);
    we = 1; waddr = 5'd0; wdata = 32'hDEAD_BEEF;
    @(posedge clk);
    we = 0; raddr1 = 5'd0;
    #1;
    if (rdata1 !== 32'h0) begin
      $display("[ERROR] x0 is not 0! Read: 0x%08X", rdata1);
      error_count++;
    end else begin
      $display("[PASS] x0 zero-invariance check passed.");
    end

    // 3. Sequential Write and Read for Registers x1 to x31
    for (int i = 1; i < 32; i++) begin
      @(posedge clk);
      we = 1; waddr = i[4:0]; wdata = (i * 32'h1111_1111);
    end
    @(posedge clk);
    we = 0;

    // Check all written registers
    for (int i = 1; i < 32; i++) begin
      raddr1 = i[4:0];
      #1;
      if (rdata1 !== (i * 32'h1111_1111)) begin
        $display("[ERROR] Mismatch at x%0d: Expected 0x%08X, got 0x%08X", i, (i * 32'h1111_1111), rdata1);
        error_count++;
      end
    end

    // 4. Simultaneous Write & Read Bypass Forwarding
    @(posedge clk);
    we = 1; waddr = 5'd10; wdata = 32'hCAFE_BABE;
    raddr1 = 5'd10; // Reading same cycle
    #1;
    if (rdata1 !== 32'hCAFE_BABE) begin
      $display("[ERROR] Bypass forwarding failed! Got 0x%08X", rdata1);
      error_count++;
    end else begin
      $display("[PASS] Write-forwarding bypass check passed.");
    end

    @(posedge clk);
    we = 0;

    $display("=================================================");
    if (error_count == 0) begin
      $display(" ALL REGISTER FILE TESTS PASSED (0 ERRORS)");
    end else begin
      $display(" REGISTER FILE FAILED WITH %0d ERRORS", error_count);
    end
    $display("=================================================");
    $finish;
  end

endmodule