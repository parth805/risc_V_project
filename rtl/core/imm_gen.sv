// ============================================================================
// File: rtl/core/imm_gen.sv
// Description: Immediate Generator & Sign-Extender for RV32I Formats
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module imm_gen (
  input  logic [31:0] instr,
  output logic [31:0] imm_out
);

  logic [6:0] opcode;
  assign opcode = instr[6:0];

  always_comb begin
    case (opcode)
      // I-Type: ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, LOAD, JALR
      OPCODE_OP_IMM,
      OPCODE_LOAD,
      OPCODE_JALR: begin
        imm_out = {{20{instr[31]}}, instr[31:20]};
      end

      // S-Type: Store Instructions (SB, SH, SW)
      OPCODE_STORE: begin
        imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end

      // B-Type: Conditional Branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
      OPCODE_BRANCH: begin
        imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      end

      // U-Type: LUI, AUIPC (Upper 20 bits)
      OPCODE_LUI,
      OPCODE_AUIPC: begin
        imm_out = {instr[31:12], 12'h000};
      end

      // J-Type: Unconditional Jump (JAL)
      OPCODE_JAL: begin
        imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      end

      default: begin
        imm_out = 32'h0;
      end
    endcase
  end

endmodule