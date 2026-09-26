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


  // --------------------------------------------------------------------------
  // IF/ID Pipeline Register
  // --------------------------------------------------------------------------
  logic [31:0] if_id_pc;
  logic [31:0] if_id_pc_plus4;
  logic [31:0] if_id_instr;

  // --------------------------------------------------------------------------
  // ID/EX Pipeline Register
  // --------------------------------------------------------------------------
  logic [31:0] id_ex_pc;
  logic [31:0] id_ex_pc_plus4;
  logic [31:0] id_ex_rdata1;
  logic [31:0] id_ex_rdata2;
  logic [31:0] id_ex_imm;
  logic [4:0]  id_ex_rs1;
  logic [4:0]  id_ex_rs2;
  logic [4:0]  id_ex_rd;


  logic        id_ex_reg_write;
  logic        id_ex_mem_read;
  logic        id_ex_mem_write;
  logic        id_ex_branch;
  logic        id_ex_jump;
  logic        id_ex_is_jalr;
  logic        id_ex_alu_src_a_sel;
  logic        id_ex_alu_src_b_sel;
  logic [1:0]  id_ex_wb_src_sel;
  alu_op_e     id_ex_alu_op;
  logic [2:0]  id_ex_funct3;


  // --------------------------------------------------------------------------
  // EX/MEM Pipeline Register
  // --------------------------------------------------------------------------
  logic [31:0] ex_mem_alu_res;
  logic [31:0] ex_mem_rdata2;
  logic [31:0] ex_mem_pc_plus4;
  logic [4:0]  ex_mem_rd;
  logic [2:0]  ex_mem_funct3;

  logic        ex_mem_reg_write;
  logic        ex_mem_mem_read;
  logic        ex_mem_mem_write;
  logic [1:0]  ex_mem_wb_src_sel;

  // --------------------------------------------------------------------------
// MEM/WB Pipeline Register
// --------------------------------------------------------------------------
logic [31:0] mem_wb_alu_res;
logic [31:0] mem_wb_load_data;
logic [31:0] mem_wb_pc_plus4;
logic [4:0]  mem_wb_rd;

logic        mem_wb_reg_write;
logic [1:0]  mem_wb_wb_src_sel;


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
  logic [31:0] forward_a_data;
  logic [31:0] forward_b_data;
  logic        pipeline_stall;
  logic [31:0] alu_res;
  logic        alu_zero;
  logic        branch_taken;
  logic [31:0] branch_op_a;
  logic [31:0] branch_op_b;
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
    end else if (!pipeline_stall) begin
      pc_reg <= pc_next;
    end
  end

  // --------------------------------------------------------------------------
  // IF/ID Pipeline Register
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc      <= 32'd0;
      if_id_pc_plus4 <= 32'd0;
      if_id_instr   <= 32'd0;
    end else if (!pipeline_stall) begin
      if_id_pc       <= pc_reg;
      if_id_pc_plus4 <= pc_plus4;
      if_id_instr    <= instr;
    end
  end



    // --------------------------------------------------------------------------
  // ID/EX Pipeline Register
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc             <= 32'd0;
      id_ex_pc_plus4       <= 32'd0;
      id_ex_rdata1         <= 32'd0;
      id_ex_rdata2         <= 32'd0;
      id_ex_imm            <= 32'd0;
      id_ex_rs1            <= 5'd0;
      id_ex_rs2            <= 5'd0;
      id_ex_rd             <= 5'd0;
      id_ex_reg_write      <= 1'b0;
      id_ex_mem_read       <= 1'b0;
      id_ex_mem_write      <= 1'b0;
      id_ex_branch         <= 1'b0;
      id_ex_jump           <= 1'b0;
      id_ex_is_jalr        <= 1'b0;
      id_ex_alu_src_a_sel  <= 1'b0;
      id_ex_alu_src_b_sel  <= 1'b0;
      id_ex_wb_src_sel     <= 2'b00;
      id_ex_alu_op         <= ALU_ADD;
      id_ex_funct3         <= 3'd0;
    end else begin
      id_ex_pc             <= if_id_pc;
      id_ex_pc_plus4       <= if_id_pc_plus4;
      id_ex_rdata1         <= rdata1;
      id_ex_rdata2         <= rdata2;
      id_ex_rs1            <= rs1;
      id_ex_rs2            <= rs2;
      id_ex_imm            <= imm;
      id_ex_rd             <= rd;
      id_ex_reg_write      <= reg_write;
      id_ex_mem_read       <= mem_read;
      id_ex_mem_write      <= mem_write;
      id_ex_branch         <= branch;
      id_ex_jump           <= jump;
      id_ex_is_jalr        <= is_jalr;
      id_ex_alu_src_a_sel  <= alu_src_a_sel;
      id_ex_alu_src_b_sel  <= alu_src_b_sel;
      id_ex_wb_src_sel     <= wb_src_sel;
      id_ex_alu_op         <= alu_op;
      id_ex_funct3         <= funct3;
    end
  end

    // --------------------------------------------------------------------------
  // EX/MEM Pipeline Register
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_alu_res    <= 32'd0;
      ex_mem_rdata2     <= 32'd0;
      ex_mem_pc_plus4   <= 32'd0;
      ex_mem_rd         <= 5'd0;
      ex_mem_funct3     <= 3'd0;
      ex_mem_reg_write  <= 1'b0;
      ex_mem_mem_read   <= 1'b0;
      ex_mem_mem_write  <= 1'b0;
      ex_mem_wb_src_sel <= 2'b00;
    end else begin
      ex_mem_alu_res    <= alu_res;
      ex_mem_rdata2 <= forward_b_data;
      ex_mem_pc_plus4   <= id_ex_pc_plus4;
      ex_mem_rd         <= id_ex_rd;
      ex_mem_funct3     <= id_ex_funct3;
      ex_mem_reg_write  <= id_ex_reg_write;
      ex_mem_mem_read   <= id_ex_mem_read;
      ex_mem_mem_write  <= id_ex_mem_write;
      ex_mem_wb_src_sel <= id_ex_wb_src_sel;
    end
  end

  // --------------------------------------------------------------------------
// MEM/WB Pipeline Register
// --------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    mem_wb_alu_res    <= 32'd0;
    mem_wb_load_data  <= 32'd0;
    mem_wb_pc_plus4   <= 32'd0;
    mem_wb_rd         <= 5'd0;
    mem_wb_reg_write  <= 1'b0;
    mem_wb_wb_src_sel <= 2'b00;
  end else begin
    mem_wb_alu_res    <= ex_mem_alu_res;
    mem_wb_load_data  <= load_data;
    mem_wb_pc_plus4   <= ex_mem_pc_plus4;
    mem_wb_rd         <= ex_mem_rd;
    mem_wb_reg_write  <= ex_mem_reg_write;
    mem_wb_wb_src_sel <= ex_mem_wb_src_sel;
  end
end

  // --------------------------------------------------------------------------
  // 2. Instruction Decode (ID Stage)
  // --------------------------------------------------------------------------
  assign opcode = if_id_instr[6:0];
  assign rd     = if_id_instr[11:7];
  assign funct3 = if_id_instr[14:12];
  assign rs1    = if_id_instr[19:15];
  assign rs2    = if_id_instr[24:20];
  assign funct7 = if_id_instr[31:25];

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
    .instr   (if_id_instr),
    .imm_out (imm)
  );

  register_file u_regfile (
    .clk    (clk),
    .rst_n  (rst_n),
    .raddr1 (rs1),
    .rdata1 (rdata1),
    .raddr2 (rs2),
    .rdata2 (rdata2),
    .we     (mem_wb_reg_write),
    .waddr  (mem_wb_rd),
    .wdata  (wb_data)
  );

    // --------------------------------------------------------------------------
  // Hazard Detection Unit
  // --------------------------------------------------------------------------
  hazard_unit u_hazard_unit (
    .id_ex_mem_read (id_ex_mem_read),
    .id_ex_rd       (id_ex_rd),
    .if_id_rs1      (rs1),
    .if_id_rs2      (rs2),
    .stall          (pipeline_stall)
  );

  // --------------------------------------------------------------------------
  // Branch operand forwarding
  // --------------------------------------------------------------------------
  always_comb begin
    branch_op_a = rdata1;
    branch_op_b = rdata2;

    // Forward ALU result from EX/MEM.
    // Do not forward EX/MEM for a load because the load data is not
    // available until the MEM/WB stage.
    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs1)) begin
      branch_op_a = ex_mem_alu_res;
    end

    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs2)) begin
      branch_op_b = ex_mem_alu_res;
    end

    // Forward the final WB value.
    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs1)) begin
      branch_op_a = wb_data;
    end

    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs2)) begin
      branch_op_b = wb_data;
    end
  end

  branch_comp u_branch_comp (
    .funct3       (funct3),
    .op_a         (branch_op_a),
    .op_b         (branch_op_b),
    .branch_taken (branch_taken)
  );

  // --------------------------------------------------------------------------
  // EX-stage forwarding
  // --------------------------------------------------------------------------
  always_comb begin
    forward_a_data = id_ex_rdata1;
    forward_b_data = id_ex_rdata2;

    // Forward from EX/MEM
    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
    end

    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs2)) begin
      forward_b_data = ex_mem_alu_res;
    end 

    // Forward from MEM/WB
    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
    end

    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs2)) begin
      forward_b_data = wb_data;
    end
  end

  assign alu_op_a = id_ex_alu_src_a_sel ? id_ex_pc : forward_a_data;
  assign alu_op_b = id_ex_alu_src_b_sel ? id_ex_imm : forward_b_data;

  alu u_alu (
    .alu_op  (id_ex_alu_op),
    .op_a    (alu_op_a),
    .op_b    (alu_op_b),
    .alu_res (alu_res),
    .zero    (alu_zero)
  );

  // --------------------------------------------------------------------------
  // MEM stage
  // --------------------------------------------------------------------------
  assign data_req   = ex_mem_mem_read | ex_mem_mem_write;
  assign data_we    = ex_mem_mem_write;
  assign data_addr  = ex_mem_alu_res;


  load_store_unit u_lsu (
    .funct3    (ex_mem_funct3),
    .addr      (ex_mem_alu_res),
    .reg_wdata (ex_mem_rdata2),
    .mem_rdata (data_rdata),
    .mem_wstrb (data_wstrb),
    .mem_wdata (data_wdata),
    .load_data (load_data)
  );

  // --------------------------------------------------------------------------
  // 5. Writeback Stage (WB Stage)
  // --------------------------------------------------------------------------
  always_comb begin
    case (mem_wb_wb_src_sel)
      2'b00:   wb_data = mem_wb_alu_res;
      2'b01:   wb_data = mem_wb_load_data;
      2'b10:   wb_data = mem_wb_pc_plus4;
      default: wb_data = mem_wb_alu_res;
    endcase
  end

endmodule