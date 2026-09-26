// ============================================================================
// File: rtl/core/register_file.sv
// Description: 32 x 32-bit Dual-Read, Single-Write Register File
// ============================================================================

`timescale 1ns/1ps

module register_file (
  input  logic        clk,
  input  logic        rst_n,

  // Read Port 1 (rs1)
  input  logic [4:0]  raddr1,
  output logic [31:0] rdata1,

  // Read Port 2 (rs2)
  input  logic [4:0]  raddr2,
  output logic [31:0] rdata2,

  // Write Port (rd)
  input  logic        we,
  input  logic [4:0]  waddr,
  input  logic [31:0] wdata
);

  // 32 General-Purpose Registers
  logic [31:0] regs [0:31];

  // Synchronous Write Operation with Active-Low Reset
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 32; i++) begin
        regs[i] <= 32'h0;
      end
    end else begin
      // Register x0 is read-only zero (writes to x0 are ignored)
      if (we && (waddr != 5'd0)) begin
        regs[waddr] <= wdata;
      end
    end
  end

  // Asynchronous Dual-Port Read with Write-Forwarding Bypass:
  // If reading the register currently being written, return new data immediately
  always_comb begin
    // Port 1
    if (raddr1 == 5'd0) begin
      rdata1 = 32'h0;
    end else if (we && (waddr == raddr1)) begin
      rdata1 = wdata; // Forwarding bypass
    end else begin
      rdata1 = regs[raddr1];
    end

    // Port 2
    if (raddr2 == 5'd0) begin
      rdata2 = 32'h0;
    end else if (we && (waddr == raddr2)) begin
      rdata2 = wdata; // Forwarding bypass
    end else begin
      rdata2 = regs[raddr2];
    end
  end

endmodule