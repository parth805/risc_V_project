// ============================================================================
// File: rtl/core/riscv_pkg.sv
// Description: RISC-V RV32I Architecture Definitions & Control Enums
// ============================================================================

package riscv_pkg;

  // --------------------------------------------------------------------------
  // RV32I Base Opcodes (instr[6:0])
  // --------------------------------------------------------------------------
  localparam bit [6:0] OPCODE_OP       = 7'b0110011; // R-Type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
  localparam bit [6:0] OPCODE_OP_IMM   = 7'b0010011; // I-Type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
  localparam bit [6:0] OPCODE_LOAD     = 7'b0000011; // I-Type: LB, LH, LW, LBU, LHU
  localparam bit [6:0] OPCODE_STORE    = 7'b0100011; // S-Type: SB, SH, SW
  localparam bit [6:0] OPCODE_BRANCH   = 7'b1100011; // B-Type: BEQ, BNE, BLT, BGE, BLTU, BGEU
  localparam bit [6:0] OPCODE_LUI      = 7'b0110111; // U-Type: Load Upper Immediate
  localparam bit [6:0] OPCODE_AUIPC    = 7'b0010111; // U-Type: Add Upper Immediate to PC
  localparam bit [6:0] OPCODE_JAL      = 7'b1101111; // J-Type: Jump and Link
  localparam bit [6:0] OPCODE_JALR     = 7'b1100111; // I-Type: Jump and Link Register
  localparam bit [6:0] OPCODE_SYSTEM   = 7'b1110011; // I-Type: ECALL, EBREAK, CSR
  localparam bit [6:0] OPCODE_FENCE    = 7'b0001111; // I-Type: FENCE

  // --------------------------------------------------------------------------
  // ALU Operations Enum
  // --------------------------------------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_SLL  = 4'b0010,
    ALU_SLT  = 4'b0011,
    ALU_SLTU = 4'b0100,
    ALU_XOR  = 4'b0101,
    ALU_SRL  = 4'b0110,
    ALU_SRA  = 4'b0111,
    ALU_OR   = 4'b1000,
    ALU_AND  = 4'b1001,
    ALU_PASS = 4'b1010  // Pass Operand B directly
  } alu_op_e;

  // --------------------------------------------------------------------------
  // Branch Condition Funct3
  // --------------------------------------------------------------------------
  localparam bit [2:0] BR_BEQ  = 3'b000;
  localparam bit [2:0] BR_BNE  = 3'b001;
  localparam bit [2:0] BR_BLT  = 3'b100;
  localparam bit [2:0] BR_BGE  = 3'b101;
  localparam bit [2:0] BR_BLTU = 3'b110;
  localparam bit [2:0] BR_BGEU = 3'b111;

  // --------------------------------------------------------------------------
  // Memory Access Widths (Load/Store Funct3)
  // --------------------------------------------------------------------------
  localparam bit [2:0] MEM_B   = 3'b000; // Byte (Signed)
  localparam bit [2:0] MEM_H   = 3'b001; // Halfword (Signed)
  localparam bit [2:0] MEM_W   = 3'b010; // Word (32-bit)
  localparam bit [2:0] MEM_BU  = 3'b100; // Byte (Unsigned)
  localparam bit [2:0] MEM_HU  = 3'b101; // Halfword (Unsigned)

endpackage : riscv_pkg