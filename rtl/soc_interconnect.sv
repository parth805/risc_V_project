// ============================================================================
// File: rtl/soc_interconnect.sv
// Description: Memory Bus Crossbar & Address Decoder for RISC-V AI SoC
//              - SRAM Subsystem:       0x0000_0000 - 0x0000_3FFF (16 KB)
//              - AI Accelerator MMIO:  0x4000_0000 - 0x4000_03FF (1 KB)
// ============================================================================

`timescale 1ns/1ps

module soc_interconnect (
    // ------------------------------------------------------------------------
    // CPU Master Bus Interface
    // ------------------------------------------------------------------------
    input  logic        cpu_data_req,
    input  logic        cpu_data_we,
    input  logic [3:0]  cpu_data_wstrb,
    input  logic [31:0] cpu_data_addr,
    input  logic [31:0] cpu_data_wdata,
    output logic [31:0] cpu_data_rdata,

    // ------------------------------------------------------------------------
    // SRAM Slave Interface (0x0000_0000 - 0x3FFF_FFFF)
    // ------------------------------------------------------------------------
    output logic        sram_req,
    output logic        sram_we,
    output logic [3:0]  sram_wstrb,
    output logic [31:0] sram_addr,
    output logic [31:0] sram_wdata,
    input  logic [31:0] sram_rdata,

    // ------------------------------------------------------------------------
    // AI Accelerator Slave Interface (0x4000_0000 - 0x4000_FFFF)
    // ------------------------------------------------------------------------
    output logic        accel_we,
    output logic [31:0] accel_addr,
    output logic [31:0] accel_wdata,
    input  logic [31:0] accel_rdata
);

    // Address Decoding
    logic is_accel_space;
    assign is_accel_space = (cpu_data_addr[31:28] == 4'h4); // Prefix 0x4...

    // SRAM Routing
    assign sram_req   = cpu_data_req && !is_accel_space;
    assign sram_we    = cpu_data_we;
    assign sram_wstrb = cpu_data_wstrb;
    assign sram_addr  = cpu_data_addr;
    assign sram_wdata = cpu_data_wdata;

    // Accelerator Routing
    assign accel_we    = cpu_data_req && cpu_data_we && is_accel_space;
    assign accel_addr  = cpu_data_addr;
    assign accel_wdata = cpu_data_wdata;

    // Read Data Multiplexer
    assign cpu_data_rdata = is_accel_space ? accel_rdata : sram_rdata;

endmodule
