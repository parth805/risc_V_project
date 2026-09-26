// ============================================================================
// File: rtl/core/alu.sv
// Description: Synthesizable 32-bit Arithmetic Logic Unit (ALU)
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

  logic [4:0] shamt;
  assign shamt = op_b[4:0]; // Shift amount is lower 5 bits of operand B

  always_comb begin
    case (alu_op)
      ALU_ADD:  alu_res = op_a + op_b;
      ALU_SUB:  alu_res = op_a - op_b;
      ALU_SLL:  alu_res = op_a << shamt;
      ALU_SLT:  alu_res = ($signed(op_a) < $signed(op_b)) ? 32'd1 : 32'd0;
      ALU_SLTU: alu_res = (op_a < op_b) ? 32'd1 : 32'd0;
      ALU_XOR:  alu_res = op_a ^ op_b;
      ALU_SRL:  alu_res = op_a >> shamt;
      ALU_SRA:  alu_res = $signed(op_a) >>> shamt; // Arithmetic shift preserving sign
      ALU_OR:   alu_res = op_a | op_b;
      ALU_AND:  alu_res = op_a & op_b;
      ALU_PASS: alu_res = op_b;
      default:  alu_res = 32'h0;
    endcase
  end

  // Zero flag asserted when ALU result equals 0
  assign zero = (alu_res == 32'h0);

endmodule