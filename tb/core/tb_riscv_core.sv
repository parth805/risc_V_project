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
      if (data_wstrb[0])
        dmem[data_addr[9:2]][7:0]   <= data_wdata[7:0];

      if (data_wstrb[1])
        dmem[data_addr[9:2]][15:8]  <= data_wdata[15:8];

      if (data_wstrb[2])
        dmem[data_addr[9:2]][23:16] <= data_wdata[23:16];

      if (data_wstrb[3])
        dmem[data_addr[9:2]][31:24] <= data_wdata[31:24];
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
      imem[i] = 32'h00000013; // NOP
      dmem[i] = 32'h0;
    end

    // ------------------------------------------------------------------------
    // Mini Assembly Program loaded directly into Instruction Memory
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    // Basic Arithmetic + SW/LW
    // ------------------------------------------------------------------------

    // 0x00: ADDI x1, x0, 10
    imem[0] = 32'h00A00093;

    // 0x04: ADDI x2, x0, 20
    imem[1] = 32'h01400113;

    // 0x08: ADD x3, x1, x2
    imem[2] = 32'h002081B3;

    // 0x0C: SW x3, 4(x0)
    imem[3] = 32'h00302223;

    // 0x10: LW x4, 4(x0)
    imem[4] = 32'h00402203;

    // 0x14: BNE x3, x4, +8
    imem[5] = 32'h00419463;

    // 0x18: ADDI x5, x0, 1
    imem[6] = 32'h00100293;

    // 0x1C: SW x5, 8(x0)
    imem[7] = 32'h00502423;


    // ------------------------------------------------------------------------
    // Taken Branch Test
    // ------------------------------------------------------------------------

    // 0x20: ADDI x6, x0, 10
    imem[8] = 32'h00A00313;

    // 0x24: ADDI x7, x0, 20
    imem[9] = 32'h01400393;

    // 0x28: BNE x6, x7, +8
    imem[10] = 32'h00731463;

    // 0x2C: ADDI x8, x0, 99
    // Must be skipped
    imem[11] = 32'h06300413;

    // 0x30: ADDI x8, x0, 42
    // Branch target
    imem[12] = 32'h02A00413;


    // ------------------------------------------------------------------------
    // JAL Test
    // ------------------------------------------------------------------------

    // 0x34: JAL x9, +8
    // Target = 0x3C, link = 0x38
    imem[13] = 32'h008004EF;

    // 0x38: ADDI x10, x0, 99
    // Must be skipped
    imem[14] = 32'h06300513;

    // 0x3C: ADDI x10, x0, 55
    // JAL target
    imem[15] = 32'h03700513;


    // ------------------------------------------------------------------------
    // JALR Test
    // ------------------------------------------------------------------------

    // 0x40: ADDI x11, x0, 0x50
    imem[16] = 32'h05000593;

    // 0x44: JALR x12, 0(x11)
    // Target = 0x50, link = 0x48
    imem[17] = 32'h00058667;

    // 0x48: ADDI x13, x0, 77
    // Must be skipped
    imem[18] = 32'h04D00693;

    // 0x4C: NOP
    imem[19] = 32'h00000013;

    // 0x50: ADDI x13, x0, 88
    // JALR target
    imem[20] = 32'h05800693;


    // ------------------------------------------------------------------------
    // Forwarding Test
    // ------------------------------------------------------------------------

    // 0x54: ADDI x14, x0, 5
    imem[21] = 32'h00500713;

    // 0x58: ADDI x15, x14, 3
    // Requires forwarding: x15 = 8
    imem[22] = 32'h00370793;

    // 0x5C: ADD x16, x15, x14
    // Requires forwarding: x16 = 13
    imem[23] = 32'h00E78833;


    // ------------------------------------------------------------------------
    // Byte/Halfword Store Test
    // ------------------------------------------------------------------------

    // 0x60: ADDI x17, x0, 0x7F
    imem[24] = 32'h07F00893;

    // 0x64: SB x17, 0(x0)
    imem[25] = 32'h01100023;

    // 0x68: ADDI x18, x0, 0x123
    imem[26] = 32'h12300913;

    // 0x6C: SH x18, 2(x0)
    imem[27] = 32'h01201123;


    // ------------------------------------------------------------------------
    // Byte/Halfword Load Test
    // ------------------------------------------------------------------------

    // 0x70: ADDI x19, x0, 0x180
    imem[28] = 32'h18000993;

    // 0x74: SW x19, 12(x0)
    // dmem[3] = 0x00000180
    imem[29] = 32'h01302623;

    // 0x78: LB x20, 12(x0)
    // Expected: 0xFFFFFF80
    imem[30] = 32'h00C00A03;

    // 0x7C: LBU x21, 12(x0)
    // Expected: 0x00000080
    imem[31] = 32'h00C04A83;

    // 0x80: LH x22, 12(x0)
    // Expected: 0x00000180
    imem[32] = 32'h00C01B03;

    // 0x84: LHU x23, 12(x0)
    // Expected: 0x00000180
    imem[33] = 32'h00C05B83;


    // ------------------------------------------------------------------------
    // Start Simulation
    // ------------------------------------------------------------------------

    $display("=================================================");
    $display(" Starting RISC-V RV32I Processor Core Simulation ");
    $display("=================================================");

    #25 rst_n = 1;

    // Run enough cycles for all instructions above to complete.
    repeat (65) @(posedge clk);


    // ------------------------------------------------------------------------
    // Verify Data Memory
    // ------------------------------------------------------------------------

    // Original SW/LW test
    if (dmem[1] !== 32'd30) begin
      $display("[ERROR] Data RAM at 0x04: Expected 30, got %0d",
               dmem[1]);
      error_count++;
    end else begin
      $display("[PASS] Arithmetic & SW/LW Test passed (dmem[0x04] = 30)");
    end


    // Original branch flag test
    if (dmem[2] !== 32'd1) begin
      $display("[ERROR] Branch Flag at 0x08: Expected 1, got %0d",
               dmem[2]);
      error_count++;
    end else begin
      $display("[PASS] Branch & Execution Flag passed (dmem[0x08] = 1)");
    end


    // ------------------------------------------------------------------------
    // Branch Test
    // ------------------------------------------------------------------------

    if (dut.u_regfile.regs[8] !== 32'd42) begin
      $display("[ERROR] Taken Branch Test: Expected x8 = 42, got %0d",
               dut.u_regfile.regs[8]);
      error_count++;
    end else begin
      $display("[PASS] Taken Branch Test: x8 = 42");
    end


    // ------------------------------------------------------------------------
    // JAL Test
    // ------------------------------------------------------------------------

    if (dut.u_regfile.regs[10] !== 32'd55) begin
      $display("[ERROR] JAL Test: Expected x10 = 55, got %0d",
               dut.u_regfile.regs[10]);
      error_count++;
    end else begin
      $display("[PASS] JAL Test: x10 = 55");
    end

    if (dut.u_regfile.regs[9] !== 32'h00000038) begin
      $display("[ERROR] JAL Link Test: Expected x9 = 0x38, got 0x%08h",
               dut.u_regfile.regs[9]);
      error_count++;
    end else begin
      $display("[PASS] JAL Link Test: x9 = 0x38");
    end


    // ------------------------------------------------------------------------
    // JALR Test
    // ------------------------------------------------------------------------

    if (dut.u_regfile.regs[13] !== 32'd88) begin
      $display("[ERROR] JALR Test: Expected x13 = 88, got %0d",
               dut.u_regfile.regs[13]);
      error_count++;
    end else begin
      $display("[PASS] JALR Test: x13 = 88");
    end

    if (dut.u_regfile.regs[12] !== 32'h00000048) begin
      $display("[ERROR] JALR Link Test: Expected x12 = 0x48, got 0x%08h",
               dut.u_regfile.regs[12]);
      error_count++;
    end else begin
      $display("[PASS] JALR Link Test: x12 = 0x48");
    end


    // ------------------------------------------------------------------------
    // Forwarding Tests
    // ------------------------------------------------------------------------

    if (dut.u_regfile.regs[14] !== 32'd5) begin
      $display("[ERROR] Forwarding Test 1: Expected x14 = 5, got %0d",
               dut.u_regfile.regs[14]);
      error_count++;
    end else begin
      $display("[PASS] Forwarding Test 1: x14 = 5");
    end

    if (dut.u_regfile.regs[15] !== 32'd8) begin
      $display("[ERROR] Forwarding Test 2: Expected x15 = 8, got %0d",
               dut.u_regfile.regs[15]);
      error_count++;
    end else begin
      $display("[PASS] Forwarding Test 2: x15 = 8");
    end

    if (dut.u_regfile.regs[16] !== 32'd13) begin
      $display("[ERROR] Forwarding Test 3: Expected x16 = 13, got %0d",
               dut.u_regfile.regs[16]);
      error_count++;
    end else begin
      $display("[PASS] Forwarding Test 3: x16 = 13");
    end


    // ------------------------------------------------------------------------
    // SB / SH Test
    // ------------------------------------------------------------------------

    if (dmem[0] !== 32'h0123007F) begin
      $display("[ERROR] SB/SH Test: Expected dmem[0] = 0x0123007F, got 0x%08h",
               dmem[0]);
      error_count++;
    end else begin
      $display("[PASS] SB/SH Test: dmem[0] = 0x0123007F");
    end


    // ------------------------------------------------------------------------
    // LB / LBU / LH / LHU Tests
    // ------------------------------------------------------------------------

    if (dut.u_regfile.regs[20] !== 32'hFFFFFF80) begin
      $display("[ERROR] LB Test: Expected x20 = 0xFFFFFF80, got 0x%08h",
               dut.u_regfile.regs[20]);
      error_count++;
    end else begin
      $display("[PASS] LB Test: x20 = 0xFFFFFF80");
    end

    if (dut.u_regfile.regs[21] !== 32'h00000080) begin
      $display("[ERROR] LBU Test: Expected x21 = 0x00000080, got 0x%08h",
               dut.u_regfile.regs[21]);
      error_count++;
    end else begin
      $display("[PASS] LBU Test: x21 = 0x00000080");
    end

    if (dut.u_regfile.regs[22] !== 32'h00000180) begin
      $display("[ERROR] LH Test: Expected x22 = 0x00000180, got 0x%08h",
               dut.u_regfile.regs[22]);
      error_count++;
    end else begin
      $display("[PASS] LH Test: x22 = 0x00000180");
    end

    if (dut.u_regfile.regs[23] !== 32'h00000180) begin
      $display("[ERROR] LHU Test: Expected x23 = 0x00000180, got 0x%08h",
               dut.u_regfile.regs[23]);
      error_count++;
    end else begin
      $display("[PASS] LHU Test: x23 = 0x00000180");
    end


    // ------------------------------------------------------------------------
    // Final Result
    // ------------------------------------------------------------------------

    $display("=================================================");

    if (error_count == 0) begin
      $display(" ALL RISC-V CORE TESTS PASSED (0 ERRORS)");
    end else begin
      $display(" RISC-V CORE FAILED WITH %0d ERRORS", error_count);
    end

    $display("=================================================");
    $display("[INFO] Existing pipeline test completed successfully.");

    $finish;
  end

endmodule