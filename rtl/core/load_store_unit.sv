// ============================================================================
// File: rtl/core/load_store_unit.sv
// Description: Memory Load/Store Aligner & Byte-Strobe Generator for RV32I
// ============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module load_store_unit (
  input  logic [2:0]  funct3,       // Memory access size & sign from instruction
  input  logic [31:0] addr,         // Target byte address
  input  logic [31:0] reg_wdata,    // Store data coming from rs2 register
  input  logic [31:0] mem_rdata,    // Raw 32-bit word read from Data RAM

  // Outputs to Memory Bus
  output logic [3:0]  mem_wstrb,    // Byte enable strobe (active high per byte)
  output logic [31:0] mem_wdata,    // Shifted write data aligned to byte address

  // Output to Register Writeback
  output logic [31:0] load_data     // Sign/Zero-extended data ready for register write
);

  logic [1:0] byte_offset;
  assign byte_offset = addr[1:0];

  // --------------------------------------------------------------------------
  // STORE Logic: Shift write data and assert appropriate byte strobes
  // --------------------------------------------------------------------------
  always_comb begin
    case (funct3)
      MEM_B: begin // SB (Store Byte)
        case (byte_offset)
          2'b00: begin mem_wstrb = 4'b0001; mem_wdata = {24'h0, reg_wdata[7:0]}; end
          2'b01: begin mem_wstrb = 4'b0010; mem_wdata = {16'h0, reg_wdata[7:0], 8'h0}; end
          2'b10: begin mem_wstrb = 4'b0100; mem_wdata = {8'h0,  reg_wdata[7:0], 16'h0}; end
          2'b11: begin mem_wstrb = 4'b1000; mem_wdata = {reg_wdata[7:0], 24'h0}; end
        endcase
      end

      MEM_H: begin // SH (Store Halfword - 16-bit aligned)
        case (byte_offset[1])
          1'b0:  begin mem_wstrb = 4'b0011; mem_wdata = {16'h0, reg_wdata[15:0]}; end
          1'b1:  begin mem_wstrb = 4'b1100; mem_wdata = {reg_wdata[15:0], 16'h0}; end
        endcase
      end

      MEM_W: begin // SW (Store Word - 32-bit aligned)
        mem_wstrb = 4'b1111;
        mem_wdata = reg_wdata;
      end

      default: begin
        mem_wstrb = 4'b0000;
        mem_wdata = 32'h0;
      end
    endcase
  end

  // --------------------------------------------------------------------------
  // LOAD Logic: Extract byte/halfword/word and apply Sign or Zero Extension
  // --------------------------------------------------------------------------
  always_comb begin
    case (funct3)
      MEM_B: begin // LB (Signed Byte)
        case (byte_offset)
          2'b00: load_data = {{24{mem_rdata[7]}},  mem_rdata[7:0]};
          2'b01: load_data = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
          2'b10: load_data = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
          2'b11: load_data = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
        endcase
      end

      MEM_BU: begin // LBU (Unsigned Byte)
        case (byte_offset)
          2'b00: load_data = {24'h0, mem_rdata[7:0]};
          2'b01: load_data = {24'h0, mem_rdata[15:8]};
          2'b10: load_data = {24'h0, mem_rdata[23:16]};
          2'b11: load_data = {24'h0, mem_rdata[31:24]};
        endcase
      end

      MEM_H: begin // LH (Signed Halfword)
        case (byte_offset[1])
          1'b0: load_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
          1'b1: load_data = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
        endcase
      end

      MEM_HU: begin // LHU (Unsigned Halfword)
        case (byte_offset[1])
          1'b0: load_data = {16'h0, mem_rdata[15:0]};
          1'b1: load_data = {16'h0, mem_rdata[31:16]};
        endcase
      end

      MEM_W: begin // LW (Word)
        load_data = mem_rdata;
      end

      default: begin
        load_data = mem_rdata;
      end
    endcase
  end

endmodule