// ============================================================================
// File: tb/uvm/src/accel_if.sv
// Description: SystemVerilog Interface for AI Accelerator UVM Testbench
// ============================================================================

`timescale 1ns/1ps

interface accel_if (input logic clk, input logic rst_n);

    // Direct Parallel Matrix Interface
    logic                               start;
    logic                               activation_enable;
    logic signed [7:0]                  a_matrix [0:3][0:3];
    logic signed [7:0]                  b_matrix [0:3][0:3];
    logic signed [31:0]                 c_matrix [0:3][0:3];

    // Status & Handshake
    logic                               busy;
    logic                               done;
    logic                               error;

    // Memory-Mapped CSR Interface
    logic                               reg_we;
    logic [31:0]                        reg_addr;
    logic [31:0]                        reg_wdata;
    logic [31:0]                        reg_rdata;

    // Clocking block for synchronous driver
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output start;
        output activation_enable;
        output a_matrix;
        output b_matrix;
        output reg_we;
        output reg_addr;
        output reg_wdata;
        input  busy;
        input  done;
        input  error;
        input  c_matrix;
        input  reg_rdata;
    endclocking

    // Clocking block for passive monitor
    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input start;
        input activation_enable;
        input a_matrix;
        input b_matrix;
        input c_matrix;
        input busy;
        input done;
        input error;
        input reg_we;
        input reg_addr;
        input reg_wdata;
        input reg_rdata;
    endclocking

    modport DRIVER  (clocking drv_cb, input clk, input rst_n);
    modport MONITOR (clocking mon_cb, input clk, input rst_n);

endinterface : accel_if
