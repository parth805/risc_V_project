// ============================================================================
// File: tb/core/tb_riscv_core.sv
// Description: Self-Checking Testbench for RV32I Core running Program Code
// ============================================================================

`timescale 1ns/1ps

module tb_riscv_core;
  logic        clk;
  logic        rst_n;

  // Instruction Bus
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;

  // Data Bus
  logic        data_req;
  logic        data_we;
  logic [3:0]  data_wstrb;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;

  // Simple 1KB Instruction ROM & 1KB Data RAM models
  logic [31:0] imem [0:255];
  logic [31:0] dmem [0:255];

  int error_count = 0;

  // Instantiate Core
  riscv_core #(.RESET_ADDR(32'h0000_0000)) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .instr_addr  (instr_addr),
    .instr_rdata (instr_rdata),
    .data_req    (data_req),
    .data_we     (data_we),
    .data_wstrb  (data_wstrb),
    .data_addr   (data_addr),
    .data_wdata  (data_wdata),
    .data_rdata  (data_rdata)
  );

  // Clock generation (50 MHz)
  always #10 clk = ~clk;

  // Instruction ROM Read
  assign instr_rdata = imem[instr_addr[9:2]];

 // Data RAM Write
always_ff @(posedge clk) begin
  if (data_req && data_we) begin
    if (data_wstrb[0]) dmem[data_addr[9:2]][7:0]   <= data_wdata[7:0];
    if (data_wstrb[1]) dmem[data_addr[9:2]][15:8]  <= data_wdata[15:8];
    if (data_wstrb[2]) dmem[data_addr[9:2]][23:16] <= data_wdata[23:16];
    if (data_wstrb[3]) dmem[data_addr[9:2]][31:24] <= data_wdata[31:24];
  end
end

// Combinational Data RAM Read
assign data_rdata = dmem[data_addr[9:2]];

  initial begin
    $dumpfile("waves/tb_riscv_core.vcd");
    $dumpvars(0, tb_riscv_core);

    clk   = 0;
    rst_n = 0;

    // Clear Memories
    for (int i = 0; i < 256; i++) begin
      imem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
      dmem[i] = 32'h0;
    end

    // ------------------------------------------------------------------------
    // Mini Assembly Program loaded directly into Instruction Memory:
    // ------------------------------------------------------------------------
    // 0x00: ADDI x1, x0, 10        (x1 = 10)
    imem[0] = 32'h00A00093;
    // 0x04: ADDI x2, x0, 20        (x2 = 20)
    imem[1] = 32'h01400113;
    // 0x08: ADD  x3, x1, x2        (x3 = 10 + 20 = 30)
    imem[2] = 32'h002081B3;
    // 0x0C: SW   x3, 4(x0)         (Store 30 to Data RAM addr 0x04)
    imem[3] = 32'h00302223;
    // 0x10: LW   x4, 4(x0)         (Load from Data RAM addr 0x04 -> x4 = 30)
    imem[4] = 32'h00402203;
    // 0x14: BNE  x3, x4, +8        (Branch if x3 != x4 -> Not taken)
    imem[5] = 32'h00419463;
    // 0x18: ADDI x5, x0, 1         (x5 = 1 -> Test Success Flag)
    imem[6] = 32'h00100293;
    // 0x1C: SW   x5, 8(x0)         (Store 1 to Data RAM addr 0x08)
    imem[7] = 32'h00502423;

    $display("=================================================");
    $display(" Starting RISC-V RV32I Processor Core Simulation ");
    $display("=================================================");

    #25 rst_n = 1;

    // Run for 30 clock cycles to complete execution
    repeat (30) @(posedge clk);

    // Verify Data Memory contents
    if (dmem[1] !== 32'd30) begin // Addr 0x04 -> word index 1
      $display("[ERROR] Data RAM at 0x04: Expected 30, got %0d", dmem[1]);
      error_count++;
    end else begin
      $display("[PASS] Arithmetic & SW/LW Test passed (dmem[0x04] = 30)");
    end

    if (dmem[2] !== 32'd1) begin // Addr 0x08 -> word index 2
      $display("[ERROR] Branch Flag at 0x08: Expected 1, got %0d", dmem[2]);
      error_count++;
    end else begin
      $display("[PASS] Branch & Execution Flag passed (dmem[0x08] = 1)");
    end

    $display("=================================================");
    if (error_count == 0) begin
      $display(" ALL RISC-V CORE TESTS PASSED (0 ERRORS)");
    end else begin
      $display(" RISC-V CORE FAILED WITH %0d ERRORS", error_count);
    end
    $display("=================================================");
    $finish;
  end

endmodule