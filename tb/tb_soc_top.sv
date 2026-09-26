// ============================================================================
// File: tb/tb_soc_top.sv
// Description: Comprehensive Self-Checking System-Level Testbench for
//              RISC-V AI Accelerator SoC (soc_top.sv)
// ============================================================================

`timescale 1ns/1ps

import riscv_pkg::*;
import accelerator_pkg::*;

module tb_soc_top;

    logic clk;
    logic rst_n;

    // SoC Status Outputs
    logic        accel_done;
    logic        accel_busy;
    logic        accel_error;
    logic        accel_irq;

    // Debug bus observability
    logic [31:0] dbg_pc;
    logic        dbg_data_req;
    logic [31:0] dbg_data_addr;
    logic [31:0] dbg_data_wdata;

    int cycle_count;
    int error_count;

    // Instantiate Top-Level SoC
    soc_top #(
        .RESET_ADDR     (32'h0000_0000),
        .MEM_SIZE_BYTES (16384),
        .INIT_FILE      ("sim/firmware.hex")
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .accel_done     (accel_done),
        .accel_busy     (accel_busy),
        .accel_error    (accel_error),
        .accel_irq      (accel_irq),
        .dbg_pc         (dbg_pc),
        .dbg_data_req   (dbg_data_req),
        .dbg_data_addr  (dbg_data_addr),
        .dbg_data_wdata (dbg_data_wdata)
    );

    // 50 MHz System Clock (20 ns period)
    always #10 clk = ~clk;

    // Timeout watchdog (max 2000 cycles)
    initial begin
        #40000;
        $display("\n[ERROR] Testbench Timeout! Simulation exceeded 2000 cycles without completing.");
        $finish;
    end

    // Cycle counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else        cycle_count <= cycle_count + 1;
    end

    // =========================================================================
    // Test Stimulus & Verification Sequence
    // =========================================================================
    initial begin
        $dumpfile("waves/tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);

        clk         = 0;
        rst_n       = 0;
        cycle_count = 0;
        error_count = 0;

        $display("================================================================================");
        $display("          RISC-V AI ACCELERATOR SOC END-TO-END VERIFICATION TESTBENCH           ");
        $display("================================================================================");
        $display("[INFO] Initializing SoC with 16KB SRAM and firmware.hex...");

        // Hold reset for 3 clock cycles
        #30;
        rst_n = 1;
        $display("[INFO] Reset released at time %0t ns. CPU beginning instruction fetch at 0x0000_0000.", $time);

        // Wait for CPU to boot, configure accelerator, run matrix multiply, and write results
        // We poll for the signature 0xCAFEBABE in Data SRAM at address 0x0000_10FC
        wait (dut.u_soc_sram.mem[32'h10FC >> 2] == 32'hCAFEBABE);

        $display("[INFO] CPU completed firmware execution in %0d clock cycles!", cycle_count);

        // ---------------------------------------------------------------------
        // Check RV32M Multiplier / Divider results in CPU register file
        // ---------------------------------------------------------------------
        $display("\n--- 1. VERIFYING RV32M MULTIPLIER / DIVIDER EXECUTION ---");
        // x3 = 120 (0x78), x4 = 10, x5 = 0
        if (dut.u_riscv_core.u_regfile.registers[3] === 32'd120) begin
            $display("  [PASS] MUL  instruction: 12 * 10 = %0d (Expected: 120)", dut.u_riscv_core.u_regfile.registers[3]);
        end else begin
            $display("  [FAIL] MUL  instruction: Got %0d, Expected: 120", dut.u_riscv_core.u_regfile.registers[3]);
            error_count++;
        end

        if (dut.u_riscv_core.u_regfile.registers[4] === 32'd10) begin
            $display("  [PASS] DIV  instruction: 120 / 12 = %0d (Expected: 10)", dut.u_riscv_core.u_regfile.registers[4]);
        end else begin
            $display("  [FAIL] DIV  instruction: Got %0d, Expected: 10", dut.u_riscv_core.u_regfile.registers[4]);
            error_count++;
        end

        if (dut.u_riscv_core.u_regfile.registers[5] === 32'd0) begin
            $display("  [PASS] REM  instruction: 120 %% 10 = %0d (Expected: 0)", dut.u_riscv_core.u_regfile.registers[5]);
        end else begin
            $display("  [FAIL] REM  instruction: Got %0d, Expected: 0", dut.u_riscv_core.u_regfile.registers[5]);
            error_count++;
        end

        // ---------------------------------------------------------------------
        // Check Matrix C Results in Data SRAM
        // ---------------------------------------------------------------------
        $display("\n--- 2. VERIFYING AI ACCELERATOR MATRIX MULTIPLICATION (4x4) ---");
        // Expected Matrix C:
        // [11, 13,  8,  8]
        // [27, 29, 24, 24]
        // [ 5,  7,  6,  6]
        // [13, 15, 14, 14]
        check_result("C[0][0]", 32'h1000, 32'sd11);
        check_result("C[0][1]", 32'h1004, 32'sd13);
        check_result("C[0][2]", 32'h1008, 32'sd8);
        check_result("C[0][3]", 32'h100C, 32'sd8);
        check_result("C[1][0]", 32'h1010, 32'sd27);
        check_result("C[1][1]", 32'h1014, 32'sd29);

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        if (error_count == 0) begin
            $display("       🏆 [ALL TESTS PASSED] RISC-V AI ACCELERATOR SOC FULLY OPERATIONAL        ");
        end else begin
            $display("       ❌ [TESTS FAILED] Encountered %0d errors during SoC execution!           ", error_count);
        end
        $display("================================================================================\n");

        #100;
        $finish;
    end

    // Helper task to check memory word
    task check_result(input string name, input logic [31:0] addr, input logic signed [31:0] expected);
        logic signed [31:0] actual;
        actual = dut.u_soc_sram.mem[addr >> 2];
        if (actual === expected) begin
            $display("  [PASS] %s @ 0x%08X = %0d (Expected: %0d)", name, addr, actual, expected);
        end else begin
            $display("  [FAIL] %s @ 0x%08X = %0d (Expected: %0d)", name, addr, actual, expected);
            error_count++;
        end
    endtask

endmodule
