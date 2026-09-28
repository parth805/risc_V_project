// ============================================================================
// File: tb/uvm/src/accel_seq_item.sv
// Description: UVM Sequence Item Transaction for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

typedef enum {
    TEST_MODE_RANDOM,
    TEST_MODE_EXTREME_LIMITS,
    TEST_MODE_ZERO_MATRIX,
    TEST_MODE_IDENTITY_MATRIX,
    TEST_MODE_POSITIVE_ONLY,
    TEST_MODE_NEGATIVE_ONLY,
    TEST_MODE_SPARSE
} accel_test_mode_e;

class accel_seq_item;

    // Transaction Inputs
    rand logic signed [7:0] a_matrix [0:3][0:3];
    rand logic signed [7:0] b_matrix [0:3][0:3];
    rand bit                activation_enable;
    rand accel_test_mode_e  test_mode;

    // Transaction Outputs / Response
    logic signed [31:0]     c_matrix [0:3][0:3];
    logic signed [31:0]     expected_c [0:3][0:3];
    bit                     test_pass;
    int                     latency_cycles;

    // ------------------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------------------
    constraint c_default_mode {
        test_mode dist {
            TEST_MODE_RANDOM         := 40,
            TEST_MODE_EXTREME_LIMITS := 15,
            TEST_MODE_POSITIVE_ONLY  := 15,
            TEST_MODE_NEGATIVE_ONLY  := 15,
            TEST_MODE_IDENTITY_MATRIX:= 5,
            TEST_MODE_ZERO_MATRIX    := 5,
            TEST_MODE_SPARSE         := 5
        };
    }

    constraint c_mode_data {
        if (test_mode == TEST_MODE_POSITIVE_ONLY) {
            foreach (a_matrix[r, c]) a_matrix[r][c] >= 0;
            foreach (b_matrix[r, c]) b_matrix[r][c] >= 0;
        } else if (test_mode == TEST_MODE_NEGATIVE_ONLY) {
            foreach (a_matrix[r, c]) a_matrix[r][c] < 0;
            foreach (b_matrix[r, c]) b_matrix[r][c] < 0;
        } else if (test_mode == TEST_MODE_ZERO_MATRIX) {
            foreach (b_matrix[r, c]) b_matrix[r][c] == 0;
        } else if (test_mode == TEST_MODE_EXTREME_LIMITS) {
            a_matrix[0][0] == -8'sd128;
            b_matrix[0][0] == -8'sd128;
            a_matrix[3][3] ==  8'sd127;
            b_matrix[3][3] ==  8'sd127;
        }
    }

    // ------------------------------------------------------------------------
    // Reference Prediction Model
    // ------------------------------------------------------------------------
    function void calculate_expected();
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                int sum = 0;
                for (int k = 0; k < 4; k++) begin
                    sum += int'(a_matrix[r][k]) * int'(b_matrix[k][c]);
                end
                if (activation_enable && sum < 0) begin
                    sum = 0;
                end
                expected_c[r][c] = sum;
            end
        end
    endfunction

    // ------------------------------------------------------------------------
    // Comparison & Formatting Methods
    // ------------------------------------------------------------------------
    function bit compare_results();
        test_pass = 1'b1;
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                if (c_matrix[r][c] !== expected_c[r][c]) begin
                    test_pass = 1'b0;
                end
            end
        end
        return test_pass;
    endfunction

    function string convert2string();
        string s = $sformatf("\n=== ACCEL TRANSACTION (Mode: %s | Act: %s | Latency: %0d cycles) ===\n",
                             test_mode.name(), (activation_enable ? "ReLU" : "Linear"), latency_cycles);
        s = {s, "Matrix A:\n"};
        for (int r = 0; r < 4; r++) begin
            s = {s, $sformatf("  [%4d, %4d, %4d, %4d]\n", a_matrix[r][0], a_matrix[r][1], a_matrix[r][2], a_matrix[r][3])};
        end
        s = {s, "Matrix B:\n"};
        for (int r = 0; r < 4; r++) begin
            s = {s, $sformatf("  [%4d, %4d, %4d, %4d]\n", b_matrix[r][0], b_matrix[r][1], b_matrix[r][2], b_matrix[r][3])};
        end
        s = {s, "Expected Matrix C (Golden):\n"};
        for (int r = 0; r < 4; r++) begin
            s = {s, $sformatf("  [%6d, %6d, %6d, %6d]\n", expected_c[r][0], expected_c[r][1], expected_c[r][2], expected_c[r][3])};
        end
        s = {s, "Hardware Matrix C (DUT):\n"};
        for (int r = 0; r < 4; r++) begin
            s = {s, $sformatf("  [%6d, %6d, %6d, %6d]\n", c_matrix[r][0], c_matrix[r][1], c_matrix[r][2], c_matrix[r][3])};
        end
        s = {s, $sformatf("Result: %s\n", (test_pass ? "[PASS]" : "[FAIL]"))};
        return s;
    endfunction

endclass : accel_seq_item
