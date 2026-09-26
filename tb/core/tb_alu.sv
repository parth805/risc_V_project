// ============================================================================
// File: tb/core/tb_alu.sv
// Description: Comprehensive Self-Checking Testbench for 32-bit ALU
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_alu;
  alu_op_e     alu_op;
  logic [31:0] op_a, op_b;
  logic [31:0] alu_res;
  logic        zero;

  int error_count = 0;

  alu dut (
    .alu_op(alu_op),
    .op_a(op_a),
    .op_b(op_b),
    .alu_res(alu_res),
    .zero(zero)
  );

  task check_alu(input string name, input logic [31:0] exp_res, input logic exp_zero);
    #1;
    if (alu_res !== exp_res || zero !== exp_zero) begin
      $display("[ERROR] %s: Expected (0x%08X, zero=%0b), Got (0x%08X, zero=%0b)", name, exp_res, exp_zero, alu_res, zero);
      error_count++;
    end else begin
      $display("[PASS] %s -> 0x%08X (zero=%0b)", name, alu_res, zero);
    end
  endtask

  initial begin
    $dumpfile("waves/tb_alu.vcd");
    $dumpvars(0, tb_alu);

    $display("=================================================");
    $display(" Starting 32-bit ALU Self-Checking Testbench     ");
    $display("=================================================");

    // ADD Test
    alu_op = ALU_ADD; op_a = 32'd25; op_b = 32'd75;
    check_alu("ADD (25 + 75)", 32'd100, 1'b0);

    // SUB Test (Result = 0 -> zero flag = 1)
    alu_op = ALU_SUB; op_a = 32'd50; op_b = 32'd50;
    check_alu("SUB (50 - 50 -> Zero)", 32'd0, 1'b1);

    // SLL Test (Logical Shift Left)
    alu_op = ALU_SLL; op_a = 32'h0000_0001; op_b = 32'd4;
    check_alu("SLL (1 << 4)", 32'h0000_0010, 1'b0);

    // SLT (Signed Less Than)
    alu_op = ALU_SLT; op_a = -32'd10; op_b = 32'd5;
    check_alu("SLT Signed (-10 < 5)", 32'd1, 1'b0);

    // SLTU (Unsigned Less Than)
    alu_op = ALU_SLTU; op_a = 32'hFFFF_FFFF; op_b = 32'd5; // 0xFFFFFFFF is large unsigned
    check_alu("SLTU Unsigned (0xFFFFFFFF < 5)", 32'd0, 1'b1);

    // SRA (Arithmetic Shift Right - preserves sign bit)
    alu_op = ALU_SRA; op_a = 32'hF000_0000; op_b = 32'd4;
    check_alu("SRA Signed Right Shift", 32'hFF00_0000, 1'b0);

    // SRL (Logical Shift Right - zero fills)
    alu_op = ALU_SRL; op_a = 32'hF000_0000; op_b = 32'd4;
    check_alu("SRL Logical Right Shift", 32'h0F00_0000, 1'b0);

    // Bitwise XOR, OR, AND
    alu_op = ALU_XOR; op_a = 32'hAAAA_5555; op_b = 32'hFFFF_FFFF;
    check_alu("XOR (~A)", 32'h5555_AAAA, 1'b0);

    alu_op = ALU_OR;  op_a = 32'hF0F0_0000; op_b = 32'h0F0F_0000;
    check_alu("OR", 32'hFFFF_0000, 1'b0);

    alu_op = ALU_AND; op_a = 32'hFFFF_0000; op_b = 32'h0FF0_0000;
    check_alu("AND", 32'h0FF0_0000, 1'b0);

    $display("=================================================");
    if (error_count == 0) begin
      $display(" ALL ALU TESTS PASSED (0 ERRORS)");
    end else begin
      $display(" ALU FAILED WITH %0d ERRORS", error_count);
    end
    $display("=================================================");
    $finish;
  end

endmodule