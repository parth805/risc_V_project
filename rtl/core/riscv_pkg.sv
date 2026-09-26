// ============================================================================
// File: rtl/core/riscv_pkg.sv
// Description: RISC-V RV32IM Architecture Definitions & Control Enums
// ============================================================================

package riscv_pkg;

  // --------------------------------------------------------------------------
  // RV32I Base Opcodes (instr[6:0])
  // --------------------------------------------------------------------------
  localparam bit [6:0] OPCODE_OP       = 7'b0110011; // R-Type: Base ALU & M-Extension
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
  // ALU Operations Enum (RV32I + RV32M Extension)
  // --------------------------------------------------------------------------
  typedef enum logic [4:0] {
    ALU_ADD    = 5'b00000,
    ALU_SUB    = 5'b00001,
    ALU_SLL    = 5'b00010,
    ALU_SLT    = 5'b00011,
    ALU_SLTU   = 5'b00100,
    ALU_XOR    = 5'b00101,
    ALU_SRL    = 5'b00110,
    ALU_SRA    = 5'b00111,
    ALU_OR     = 5'b01000,
    ALU_AND    = 5'b01001,
    ALU_PASS   = 5'b01010,  // Pass Operand B directly
    // RV32M Extension
    ALU_MUL    = 5'b01011,  // Signed x Signed (Lower 32)
    ALU_MULH   = 5'b01100,  // Signed x Signed (Upper 32)
    ALU_MULHSU = 5'b01101,  // Signed x Unsigned (Upper 32)
    ALU_MULHU  = 5'b01110,  // Unsigned x Unsigned (Upper 32)
    ALU_DIV    = 5'b01111,  // Signed Divide
    ALU_DIVU   = 5'b10000,  // Unsigned Divide
    ALU_REM    = 5'b10001,  // Signed Remainder
    ALU_REMU   = 5'b10010   // Unsigned Remainder
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