// ============================================================================
// File: rtl/core/branch_comp.sv
// Description: Branch Condition Comparator Unit
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module branch_comp (
  input  logic [2:0]  funct3,
  input  logic [31:0] op_a,
  input  logic [31:0] op_b,
  output logic        branch_taken
);

  always_comb begin
    case (funct3)
      BR_BEQ:  branch_taken = (op_a == op_b);
      BR_BNE:  branch_taken = (op_a != op_b);
      BR_BLT:  branch_taken = ($signed(op_a) < $signed(op_b));
      BR_BGE:  branch_taken = ($signed(op_a) >= $signed(op_b));
      BR_BLTU: branch_taken = (op_a < op_b);
      BR_BGEU: branch_taken = (op_a >= op_b);
      default: branch_taken = 1'b0;
    endcase
  end

endmodule