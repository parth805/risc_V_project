// ============================================================================
// File: tb/core/tb_imm_gen.sv
// Description: Self-Checking Testbench for RV32I Immediate Generator
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_imm_gen;
  logic [31:0] instr;
  logic [31:0] imm_out;
  int error_count = 0;

  imm_gen dut (
    .instr(instr),
    .imm_out(imm_out)
  );

  task check_imm(input string name, input logic [31:0] expected);
    #1;
    if (imm_out !== expected) begin
      $display("[ERROR] %s: Expected 0x%08X (%0d), got 0x%08X (%0d)", name, expected, $signed(expected), imm_out, $signed(imm_out));
      error_count++;
    end else begin
      $display("[PASS] %s -> 0x%08X (%0d)", name, imm_out, $signed(imm_out));
    end
  endtask

  initial begin
    $dumpfile("waves/tb_imm_gen.vcd");
    $dumpvars(0, tb_imm_gen);

    $display("=================================================");
    $display(" Starting Immediate Generator Testbench          ");
    $display("=================================================");

    // 1. I-Type: ADDI x1, x0, -4 (imm = -4 = 0xFFFFFFFC)
    // instr = [12'b111111111100][5'b00000][3'b000][5'b00001][7'b0010011]
    instr = 32'hFFC00093;
    check_imm("I-Type Negative (ADDI -4)", 32'hFFFFFFFC);

    // 2. I-Type: ADDI x1, x0, 15 (imm = +15 = 0x0000000F)
    instr = 32'h00F00093;
    check_imm("I-Type Positive (ADDI 15)", 32'h0000000F);
    
    // 3. S-Type: SW x2, -8(x3) (imm = -8 = 0xFFFFFFF8)
    // imm[11:5]=7'b1111111, imm[4:0]=5'b11000
    instr = 32'hFE21AC23;

    // 4. B-Type: BEQ x1, x2, +16 (imm = +16 = 0x00000010)
    instr = 32'h00208863;
    check_imm("B-Type Positive (BEQ +16)", 32'h00000010);

    // 5. U-Type: LUI x5, 0x12345 (imm = 0x12345000)
    instr = 32'h123452B7;
    check_imm("U-Type (LUI 0x12345000)", 32'h12345000);

    // 6. J-Type: JAL x1, -16 (imm = -16 = 0xFFFFFFF0)
    instr = 32'hFF1FF0EF;
    check_imm("J-Type Negative (JAL -16)", 32'hFFFFFFF0);

    $display("=================================================");
    if (error_count == 0) begin
      $display(" ALL IMM_GEN TESTS PASSED (0 ERRORS)");
    end else begin
      $display(" IMM_GEN FAILED WITH %0d ERRORS", error_count);
    end
    $display("=================================================");
    $finish;
  end

endmodule