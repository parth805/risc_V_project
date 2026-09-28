// ============================================================================
// File: tb/uvm/tb_accel_uvm_top.sv
// Description: Top-Level UVM Testbench for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

import accelerator_pkg::*;
import accel_test_pkg::*;

module tb_accel_uvm_top;

    // Clock and Reset Signals
    logic clk;
    logic rst_n;

    // 100MHz System Clock Generation (10ns period)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Interface Instantiation
    accel_if intf (
        .clk(clk),
        .rst_n(rst_n)
    );

    // DUT (Device Under Test) Instantiation
    ai_accelerator #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32),
        .MATRIX_SIZE(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(intf.start),
        .activation_enable(intf.activation_enable),
        .a_matrix(intf.a_matrix),
        .b_matrix(intf.b_matrix),
        .c_matrix(intf.c_matrix),
        .busy(intf.busy),
        .done(intf.done),
        .error(intf.error),
        .irq(),
        .reg_we(intf.reg_we),
        .reg_addr(intf.reg_addr),
        .reg_wdata(intf.reg_wdata),
        .reg_rdata(intf.reg_rdata)
    );

    // Environment handle
    accel_env env;

    // Sequences
    accel_random_seq         rand_seq;
    accel_extreme_limits_seq limits_seq;
    accel_relu_stress_seq    relu_seq;
    accel_identity_seq       id_seq;
    accel_zero_seq           zero_seq;
    accel_sparse_seq         sparse_seq;

    // ------------------------------------------------------------------------
    // Main Verification Execution
    // ------------------------------------------------------------------------
    initial begin
        // Setup waveform dumping
        $dumpfile("waves/tb_accel_uvm.vcd");
        $dumpvars(0, tb_accel_uvm_top);

        $display("\n================================================================================");
        $display("   STARTING UVM VERIFICATION SUITE FOR RISC-V AI ACCELERATOR SOC                ");
        $display("================================================================================\n");

        // Construct verification environment & sequences
        env        = new("accel_env", intf);
        rand_seq   = new("accel_random_seq", 50);
        limits_seq = new("accel_extreme_limits_seq");
        relu_seq   = new("accel_relu_stress_seq");
        id_seq     = new("accel_identity_seq");
        zero_seq   = new("accel_zero_seq");
        sparse_seq = new("accel_sparse_seq");

        // Apply Reset
        rst_n = 1'b0;
        env.agent.driver.reset_dut();
        #25;
        rst_n = 1'b1;
        #15;

        // Sequence 1: Extreme Limits & Boundary Value Tests
        $display("[UVM TEST] >>> Running Extreme Limits Sequence (Max/Min Boundary)...");
        for (int i = 0; i < 6; i++) begin
            accel_seq_item item = new();
            limits_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Sequence 2: Identity Matrix Verification
        $display("[UVM TEST] >>> Running Identity Matrix Sequence...");
        for (int i = 0; i < 4; i++) begin
            accel_seq_item item = new();
            id_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Sequence 3: Zero Matrix Verification
        $display("[UVM TEST] >>> Running Zero Matrix Sequence...");
        for (int i = 0; i < 4; i++) begin
            accel_seq_item item = new();
            zero_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Sequence 4: ReLU Stress & Activation Clipping
        $display("[UVM TEST] >>> Running ReLU Stress & Negative Clipping Sequence...");
        for (int i = 0; i < 8; i++) begin
            accel_seq_item item = new();
            relu_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Sequence 5: Sparse Matrix Sequence
        $display("[UVM TEST] >>> Running Sparse Matrix Sequence...");
        for (int i = 0; i < 6; i++) begin
            accel_seq_item item = new();
            sparse_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Sequence 6: Constrained-Random Full Stimulus
        $display("[UVM TEST] >>> Running Constrained-Random Stimulus Sequence (50 Iterations)...");
        for (int i = 0; i < 50; i++) begin
            accel_seq_item item = new();
            rand_seq.generate_item(item, i);
            env.run_item(item);
        end

        // Finish and print final scoreboards & coverage
        #20;
        env.report();

        $display("UVM Verification Completed Successfully.");
        $finish;
    end

endmodule : tb_accel_uvm_top
