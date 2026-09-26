// ============================================================================
// File: rtl/core/riscv_core.sv
// Description: 32-bit RISC-V RV32I Processor Core with Bus Interfaces
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module riscv_core #(
  parameter bit [31:0] RESET_ADDR = 32'h0000_0000
)(
  input  logic        clk,
  input  logic        rst_n,

  // --------------------------------------------------------------------------
  // Instruction Memory Bus (Read-Only)
  // --------------------------------------------------------------------------
  output logic [31:0] instr_addr,
  input  logic [31:0] instr_rdata,

  // --------------------------------------------------------------------------
  // Data Memory / Peripheral Bus (Master Interface)
  // --------------------------------------------------------------------------
  output logic        data_req,       // Request active (Read or Write)
  output logic        data_we,        // 1 = Write, 0 = Read
  output logic [3:0]  data_wstrb,     // Byte enable mask (SB/SH/SW)
  output logic [31:0] data_addr,      // Memory / CSR address
  output logic [31:0] data_wdata,     // Data to write
  input  logic [31:0] data_rdata      // Data read back
);

  // --------------------------------------------------------------------------
  // Internal Signals
  // --------------------------------------------------------------------------
  logic [31:0] pc_reg, pc_next, pc_plus4;
  logic [31:0] instr;

  // Decoded fields
  logic [6:0]  opcode;
  logic [4:0]  rd, rs1, rs2;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  logic [31:0] imm;

  // Control signals
  logic        reg_write;
  logic        mem_read;
  logic        mem_write;
  logic        branch;
  logic        jump;
  logic        is_jalr;
  logic        alu_src_a_sel;
  logic        alu_src_b_sel;
  logic [1:0]  wb_src_sel;
  alu_op_e     alu_op;

  // Datapath signals
  logic [31:0] rdata1, rdata2;
  logic [31:0] alu_op_a, alu_op_b;
  logic [31:0] alu_res;
  logic        alu_zero;
  logic        branch_taken;
  logic [31:0] load_data;
  logic [31:0] wb_data;

  // --------------------------------------------------------------------------
  // 1. Instruction Fetch (IF Stage)
  // --------------------------------------------------------------------------
  assign instr_addr = pc_reg;
  assign instr      = instr_rdata;
  assign pc_plus4   = pc_reg + 32'd4;

  always_comb begin
    if (jump) begin
      if (is_jalr) begin
        pc_next = (rdata1 + imm) & ~32'd1; // JALR target (LSB cleared)
      end else begin
        pc_next = pc_reg + imm;            // JAL target
      end
    end else if (branch && branch_taken) begin
      pc_next = pc_reg + imm;              // Conditional Branch target
    end else begin
      pc_next = pc_plus4;                  // Next sequential instruction
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_reg <= RESET_ADDR;
    end else begin
      pc_reg <= pc_next;
    end
  end

  // --------------------------------------------------------------------------
  // 2. Instruction Decode (ID Stage)
  // --------------------------------------------------------------------------
  assign opcode = instr[6:0];
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];

  control_unit u_control (
    .opcode        (opcode),
    .funct3        (funct3),
    .funct7        (funct7),
    .reg_write     (reg_write),
    .mem_read      (mem_read),
    .mem_write     (mem_write),
    .branch        (branch),
    .jump          (jump),
    .is_jalr       (is_jalr),
    .alu_src_a_sel (alu_src_a_sel),
    .alu_src_b_sel (alu_src_b_sel),
    .wb_src_sel    (wb_src_sel),
    .alu_op        (alu_op)
  );

  imm_gen u_imm_gen (
    .instr   (instr),
    .imm_out (imm)
  );

  register_file u_regfile (
    .clk    (clk),
    .rst_n  (rst_n),
    .raddr1 (rs1),
    .rdata1 (rdata1),
    .raddr2 (rs2),
    .rdata2 (rdata2),
    .we     (reg_write),
    .waddr  (rd),
    .wdata  (wb_data)
  );

  branch_comp u_branch_comp (
    .funct3       (funct3),
    .op_a         (rdata1),
    .op_b         (rdata2),
    .branch_taken (branch_taken)
  );

  // --------------------------------------------------------------------------
  // 3. Execute (EX Stage)
  // --------------------------------------------------------------------------
  assign alu_op_a = (alu_src_a_sel) ? pc_reg : rdata1;
  assign alu_op_b = (alu_src_b_sel) ? imm    : rdata2;

  alu u_alu (
    .alu_op  (alu_op),
    .op_a    (alu_op_a),
    .op_b    (alu_op_b),
    .alu_res (alu_res),
    .zero    (alu_zero)
  );

  // --------------------------------------------------------------------------
  // 4. Memory Stage (MEM Stage)
  // --------------------------------------------------------------------------
  assign data_req  = mem_read | mem_write;
  assign data_we   = mem_write;
  assign data_addr = alu_res;

  load_store_unit u_lsu (
    .funct3    (funct3),
    .addr      (alu_res),
    .reg_wdata (rdata2),
    .mem_rdata (data_rdata),
    .mem_wstrb (data_wstrb),
    .mem_wdata (data_wdata),
    .load_data (load_data)
  );

  // --------------------------------------------------------------------------
  // 5. Writeback Stage (WB Stage)
  // --------------------------------------------------------------------------
  always_comb begin
    case (wb_src_sel)
      2'b00:   wb_data = alu_res;   // ALU Result
      2'b01:   wb_data = load_data; // Memory Read Data
      2'b10:   wb_data = pc_plus4;  // Return address for JAL / JALR
      default: wb_data = alu_res;
    endcase
  end

endmodule