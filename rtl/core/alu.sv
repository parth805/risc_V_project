// ============================================================================
// File: rtl/core/alu.sv
// Description: Synthesizable 32-bit Arithmetic Logic Unit (RV32IM)
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module alu (
  input  alu_op_e     alu_op,
  input  logic [31:0] op_a,
  input  logic [31:0] op_b,
  output logic [31:0] alu_res,
  output logic        zero
);

  logic [4:0]  shamt;
  assign shamt = op_b[4:0]; // Shift amount is lower 5 bits of operand B

  // 64-bit intermediate products for M-extension
  logic signed [63:0] mul_ss;
  logic signed [63:0] mul_su;
  logic        [63:0] mul_uu;

  assign mul_ss = $signed(op_a) * $signed(op_b);
  assign mul_su = $signed(op_a) * $signed({1'b0, op_b});
  assign mul_uu = {32'b0, op_a} * {32'b0, op_b};

  always_comb begin
    case (alu_op)
      // ----------------------------------------------------------------------
      // RV32I Base ALU Operations
      // ----------------------------------------------------------------------
      ALU_ADD:    alu_res = op_a + op_b;
      ALU_SUB:    alu_res = op_a - op_b;
      ALU_SLL:    alu_res = op_a << shamt;
      ALU_SLT:    alu_res = ($signed(op_a) < $signed(op_b)) ? 32'd1 : 32'd0;
      ALU_SLTU:   alu_res = (op_a < op_b) ? 32'd1 : 32'd0;
      ALU_XOR:    alu_res = op_a ^ op_b;
      ALU_SRL:    alu_res = op_a >> shamt;
      ALU_SRA:    alu_res = $signed(op_a) >>> shamt; // Arithmetic shift preserving sign
      ALU_OR:     alu_res = op_a | op_b;
      ALU_AND:    alu_res = op_a & op_b;
      ALU_PASS:   alu_res = op_b;

      // ----------------------------------------------------------------------
      // RV32M Extension Operations (Multiply & Divide)
      // ----------------------------------------------------------------------
      ALU_MUL:    alu_res = mul_ss[31:0];
      ALU_MULH:   alu_res = mul_ss[63:32];
      ALU_MULHSU: alu_res = mul_su[63:32];
      ALU_MULHU:  alu_res = mul_uu[63:32];

      ALU_DIV: begin
        if (op_b == 32'd0)
          alu_res = 32'hFFFF_FFFF; // RISC-V divide by zero = -1
        else if (op_a == 32'h8000_0000 && op_b == 32'hFFFF_FFFF)
          alu_res = 32'h8000_0000; // Overflow case
        else
          alu_res = $signed(op_a) / $signed(op_b);
      end

      ALU_DIVU: begin
        if (op_b == 32'd0)
          alu_res = 32'hFFFF_FFFF;
        else
          alu_res = op_a / op_b;
      end

      ALU_REM: begin
        if (op_b == 32'd0)
          alu_res = op_a; // RISC-V remainder by zero = dividend
        else if (op_a == 32'h8000_0000 && op_b == 32'hFFFF_FFFF)
          alu_res = 32'd0; // Overflow remainder
        else
          alu_res = $signed(op_a) % $signed(op_b);
      end

      ALU_REMU: begin
        if (op_b == 32'd0)
          alu_res = op_a;
        else
          alu_res = op_a % op_b;
      end

      default: alu_res = 32'h0;
    endcase
  end

  // Zero flag asserted when ALU result equals 0
  assign zero = (alu_res == 32'h0);

endmodule