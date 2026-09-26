// ============================================================================
// File: rtl/core/control_unit.sv
// Description: RV32I Control Unit / Instruction Decoder
// ============================================================================

`timescale 1ns/1ps

import riscv_pkg::*;

module control_unit (
  input  logic [6:0]  opcode,
  input  logic [2:0]  funct3,
  input  logic [6:0]  funct7,

  // Control Signals
  output logic        reg_write,      // Write to register file
  output logic        mem_read,       // Read from Data RAM
  output logic        mem_write,      // Write to Data RAM
  output logic        branch,         // Branch instruction
  output logic        jump,           // Unconditional jump (JAL / JALR)
  output logic        is_jalr,        // Distinguishes JALR from JAL
  output logic        alu_src_a_sel,  // 0: rs1, 1: PC
  output logic        alu_src_b_sel,  // 0: rs2, 1: Immediate
  output logic [1:0]  wb_src_sel,     // 0: ALU, 1: Memory, 2: PC+4
  output alu_op_e     alu_op          // ALU operation
);

  always_comb begin

    // ------------------------------------------------------------------------
    // Default / safe values
    // ------------------------------------------------------------------------
    reg_write     = 1'b0;
    mem_read      = 1'b0;
    mem_write     = 1'b0;
    branch        = 1'b0;
    jump          = 1'b0;
    is_jalr       = 1'b0;

    alu_src_a_sel = 1'b0;
    alu_src_b_sel = 1'b0;

    wb_src_sel    = 2'b00;
    alu_op        = ALU_ADD;

    // ------------------------------------------------------------------------
    // Instruction decoding
    // ------------------------------------------------------------------------
    case (opcode)

      // ======================================================================
      // R-Type
      // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
      // ======================================================================
      OPCODE_OP: begin

        reg_write     = 1'b1;
        alu_src_a_sel = 1'b0;
        alu_src_b_sel = 1'b0;
        wb_src_sel    = 2'b00;

        case (funct3)

          3'b000: begin
            if (funct7[5])
              alu_op = ALU_SUB;
            else
              alu_op = ALU_ADD;
          end

          3'b001: begin
            alu_op = ALU_SLL;
          end

          3'b010: begin
            alu_op = ALU_SLT;
          end

          3'b011: begin
            alu_op = ALU_SLTU;
          end

          3'b100: begin
            alu_op = ALU_XOR;
          end

          3'b101: begin
            if (funct7[5])
              alu_op = ALU_SRA;
            else
              alu_op = ALU_SRL;
          end

          3'b110: begin
            alu_op = ALU_OR;
          end

          3'b111: begin
            alu_op = ALU_AND;
          end

          default: begin
            alu_op = ALU_ADD;
          end

        endcase
      end


      // ======================================================================
      // I-Type ALU
      // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
      // ======================================================================
      OPCODE_OP_IMM: begin

        reg_write     = 1'b1;
        alu_src_a_sel = 1'b0;
        alu_src_b_sel = 1'b1;
        wb_src_sel    = 2'b00;

        case (funct3)

          3'b000: begin
            alu_op = ALU_ADD;       // ADDI
          end

          3'b001: begin
            alu_op = ALU_SLL;       // SLLI
          end

          3'b010: begin
            alu_op = ALU_SLT;       // SLTI
          end

          3'b011: begin
            alu_op = ALU_SLTU;      // SLTIU
          end

          3'b100: begin
            alu_op = ALU_XOR;       // XORI
          end

          3'b101: begin
            if (funct7[5])
              alu_op = ALU_SRA;     // SRAI
            else
              alu_op = ALU_SRL;     // SRLI
          end

          3'b110: begin
            alu_op = ALU_OR;        // ORI
          end

          3'b111: begin
            alu_op = ALU_AND;       // ANDI
          end

          default: begin
            alu_op = ALU_ADD;
          end

        endcase
      end


      // ======================================================================
      // LOAD
      // LB, LH, LW, LBU, LHU
      // ======================================================================
      OPCODE_LOAD: begin

        reg_write     = 1'b1;
        mem_read      = 1'b1;

        alu_src_a_sel = 1'b0;
        alu_src_b_sel = 1'b1;

        wb_src_sel    = 2'b01;

        // Address = rs1 + immediate
        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // STORE
      // SB, SH, SW
      // ======================================================================
      OPCODE_STORE: begin

        mem_write     = 1'b1;

        alu_src_a_sel = 1'b0;
        alu_src_b_sel = 1'b1;

        // Address = rs1 + immediate
        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // BRANCH
      // BEQ, BNE, BLT, BGE, BLTU, BGEU
      // ======================================================================
      OPCODE_BRANCH: begin

        branch        = 1'b1;

        // Branch target = PC + immediate
        alu_src_a_sel = 1'b1;
        alu_src_b_sel = 1'b1;

        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // LUI
      // ======================================================================
      OPCODE_LUI: begin

        reg_write     = 1'b1;

        // ALU operand B = immediate
        alu_src_b_sel = 1'b1;

        wb_src_sel    = 2'b00;

        // Result = immediate
        alu_op        = ALU_PASS;
      end


      // ======================================================================
      // AUIPC
      // ======================================================================
      OPCODE_AUIPC: begin

        reg_write     = 1'b1;

        // Result = PC + immediate
        alu_src_a_sel = 1'b1;
        alu_src_b_sel = 1'b1;

        wb_src_sel    = 2'b00;

        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // JAL
      // ======================================================================
      OPCODE_JAL: begin

        reg_write     = 1'b1;
        jump          = 1'b1;

        // Jump target = PC + immediate
        alu_src_a_sel = 1'b1;
        alu_src_b_sel = 1'b1;

        // Write PC + 4 to rd
        wb_src_sel    = 2'b10;

        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // JALR
      // ======================================================================
      OPCODE_JALR: begin

        reg_write     = 1'b1;
        jump          = 1'b1;
        is_jalr       = 1'b1;

        // Jump target = rs1 + immediate
        alu_src_a_sel = 1'b0;
        alu_src_b_sel = 1'b1;

        // Write PC + 4 to rd
        wb_src_sel    = 2'b10;

        alu_op        = ALU_ADD;
      end


      // ======================================================================
      // Default
      // ======================================================================
      default: begin
        // Keep safe default values
      end

    endcase
  end

endmodule