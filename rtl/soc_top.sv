// ============================================================================
// File: rtl/soc_top.sv
// Description: Top-Level RISC-V AI Accelerator System-on-Chip (SoC)
//              Integrates:
//              - 32-bit RV32IM Pipelined CPU Core
//              - 16 KB Dual-Port Instruction / Data SRAM Subsystem
//              - Address Crossbar & Interconnect Router
//              - 4x4 Systolic Array AI Accelerator Coprocessor (INT8/INT32)
// ============================================================================

`timescale 1ns/1ps

import riscv_pkg::*;
import accelerator_pkg::*;

module soc_top #(
    parameter bit [31:0] RESET_ADDR     = 32'h0000_0000,
    parameter int        MEM_SIZE_BYTES = 16384,
    parameter string     INIT_FILE      = ""
)(
    input  logic        clk,
    input  logic        rst_n,

    // SoC Status & Debug Outputs
    output logic        accel_done,
    output logic        accel_busy,
    output logic        accel_error,
    output logic        accel_irq,

    // Debug bus observability
    output logic [31:0] dbg_pc,
    output logic        dbg_data_req,
    output logic [31:0] dbg_data_addr,
    output logic [31:0] dbg_data_wdata
);

    // ------------------------------------------------------------------------
    // Internal Interconnect & Bus Signals
    // ------------------------------------------------------------------------
    // CPU Instruction Bus
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    // CPU Data Master Bus
    logic        cpu_data_req;
    logic        cpu_data_we;
    logic [3:0]  cpu_data_wstrb;
    logic [31:0] cpu_data_addr;
    logic [31:0] cpu_data_wdata;
    logic [31:0] cpu_data_rdata;

    // SRAM Subsystem Bus
    logic        sram_req;
    logic        sram_we;
    logic [3:0]  sram_wstrb;
    logic [31:0] sram_addr;
    logic [31:0] sram_wdata;
    logic [31:0] sram_rdata;

    // AI Accelerator MMIO Bus
    logic        accel_we;
    logic [31:0] accel_addr;
    logic [31:0] accel_wdata;
    logic [31:0] accel_rdata;

    // Direct Accelerator Matrix signals (Unused when driven via MMIO)
    logic signed [DATA_WIDTH-1:0] dummy_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [DATA_WIDTH-1:0] dummy_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [ACC_WIDTH-1:0]  direct_c[0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Debug assignments
    assign dbg_pc         = instr_addr;
    assign dbg_data_req   = cpu_data_req;
    assign dbg_data_addr  = cpu_data_addr;
    assign dbg_data_wdata = cpu_data_wdata;

    // ------------------------------------------------------------------------
    // 1. RISC-V RV32IM CPU Core Instance (Master)
    // ------------------------------------------------------------------------
    riscv_core #(
        .RESET_ADDR(RESET_ADDR)
    ) u_riscv_core (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr_addr  (instr_addr),
        .instr_rdata (instr_rdata),
        .data_req    (cpu_data_req),
        .data_we     (cpu_data_we),
        .data_wstrb  (cpu_data_wstrb),
        .data_addr   (cpu_data_addr),
        .data_wdata  (cpu_data_wdata),
        .data_rdata  (cpu_data_rdata)
    );

    // ------------------------------------------------------------------------
    // 2. SoC Bus Crossbar Interconnect
    // ------------------------------------------------------------------------
    soc_interconnect u_interconnect (
        // CPU Master
        .cpu_data_req   (cpu_data_req),
        .cpu_data_we    (cpu_data_we),
        .cpu_data_wstrb (cpu_data_wstrb),
        .cpu_data_addr  (cpu_data_addr),
        .cpu_data_wdata (cpu_data_wdata),
        .cpu_data_rdata (cpu_data_rdata),

        // SRAM Slave
        .sram_req       (sram_req),
        .sram_we        (sram_we),
        .sram_wstrb     (sram_wstrb),
        .sram_addr      (sram_addr),
        .sram_wdata     (sram_wdata),
        .sram_rdata     (sram_rdata),

        // Accelerator Slave
        .accel_we       (accel_we),
        .accel_addr     (accel_addr),
        .accel_wdata    (accel_wdata),
        .accel_rdata    (accel_rdata)
    );

    // ------------------------------------------------------------------------
    // 3. 16 KB SRAM Subsystem Instance
    // ------------------------------------------------------------------------
    soc_sram #(
        .MEM_SIZE_BYTES(MEM_SIZE_BYTES),
        .INIT_FILE     (INIT_FILE)
    ) u_soc_sram (
        .clk         (clk),
        .rst_n       (rst_n),
        // Port A (Instruction Fetch)
        .instr_addr  (instr_addr),
        .instr_rdata (instr_rdata),
        // Port B (Data Access)
        .data_req    (sram_req),
        .data_we     (sram_we),
        .data_wstrb  (sram_wstrb),
        .data_addr   (sram_addr),
        .data_wdata  (sram_wdata),
        .data_rdata  (sram_rdata)
    );

    // ------------------------------------------------------------------------
    // 4. Synthesizable AI Accelerator Coprocessor Instance (Slave)
    // ------------------------------------------------------------------------
    ai_accelerator #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ACC_WIDTH    (ACC_WIDTH),
        .MATRIX_SIZE  (MATRIX_SIZE),
        .NUM_ELEMENTS (NUM_ELEMENTS)
    ) u_ai_accelerator (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (1'b0),              // Triggered via MMIO REG_CTRL
        .activation_enable (1'b0),              // Configured via MMIO REG_CFG_ACT
        .a_matrix          (dummy_a),           // Unused in MMIO mode
        .b_matrix          (dummy_b),
        .c_matrix          (direct_c),
        .busy              (accel_busy),
        .done              (accel_done),
        .error             (accel_error),
        .irq               (accel_irq),
        .reg_we            (accel_we),
        .reg_addr          (accel_addr),
        .reg_wdata         (accel_wdata),
        .reg_rdata         (accel_rdata)
    );

endmodule
