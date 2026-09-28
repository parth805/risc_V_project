// ============================================================================
// File: tb/uvm/src/accel_sequence.sv
// Description: UVM Sequences for AI Accelerator Constrained-Random Verification
// ============================================================================

`timescale 1ns/1ps

class accel_base_sequence;
    accel_seq_item req;
    string seq_name;

    function new(string name = "accel_base_sequence");
        this.seq_name = name;
        this.req = new();
    endfunction

    virtual task body();
        // Base sequence body placeholder
    endtask
endclass : accel_base_sequence

// ----------------------------------------------------------------------------
// Sequence 1: Random Constrained Stimulus Sequence
// ----------------------------------------------------------------------------
class accel_random_seq extends accel_base_sequence;
    int num_transactions = 25;

    function new(string name = "accel_random_seq", int num_trans = 25);
        super.new(name);
        this.num_transactions = num_trans;
    endfunction

    function void generate_item(accel_seq_item item, int idx);
        item.test_mode = TEST_MODE_RANDOM;
        item.activation_enable = (idx % 2 == 1);
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                // Generate varied signed 8-bit values across [-128, 127]
                item.a_matrix[r][c] = $urandom_range(0, 255) - 128;
                item.b_matrix[r][c] = $urandom_range(0, 255) - 128;
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_random_seq

// ----------------------------------------------------------------------------
// Sequence 2: Extreme Limits Sequence (INT8 max +127 and min -128)
// ----------------------------------------------------------------------------
class accel_extreme_limits_seq extends accel_base_sequence;
    function new(string name = "accel_extreme_limits_seq");
        super.new(name);
    endfunction

    function void generate_item(accel_seq_item item, int sub_idx);
        item.test_mode = TEST_MODE_EXTREME_LIMITS;
        item.activation_enable = (sub_idx % 2 == 1);
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                case (sub_idx)
                    0: begin // Max positive
                        item.a_matrix[r][c] = 8'sd127;
                        item.b_matrix[r][c] = 8'sd127;
                    end
                    1: begin // Min negative
                        item.a_matrix[r][c] = -8'sd128;
                        item.b_matrix[r][c] = -8'sd128;
                    end
                    2: begin // Mixed extremes
                        item.a_matrix[r][c] = ((r + c) % 2 == 0) ? 8'sd127 : -8'sd128;
                        item.b_matrix[r][c] = ((r + c) % 2 == 0) ? -8'sd128 : 8'sd127;
                    end
                    default: begin
                        item.a_matrix[r][c] = (r == c) ? 8'sd127 : -8'sd128;
                        item.b_matrix[r][c] = (r == c) ? -8'sd128 : 8'sd127;
                    end
                endcase
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_extreme_limits_seq

// ----------------------------------------------------------------------------
// Sequence 3: ReLU Stress Sequence (Negative inputs to verify clipping)
// ----------------------------------------------------------------------------
class accel_relu_stress_seq extends accel_base_sequence;
    function new(string name = "accel_relu_stress_seq");
        super.new(name);
    endfunction

    function void generate_item(accel_seq_item item, int idx);
        item.test_mode = TEST_MODE_NEGATIVE_ONLY;
        item.activation_enable = 1'b1; // Enforce ReLU
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                item.a_matrix[r][c] = -($urandom_range(1, 120));
                item.b_matrix[r][c] = $urandom_range(1, 120); // Positive B * Negative A = Negative Dot Product
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_relu_stress_seq

// ----------------------------------------------------------------------------
// Sequence 4: Identity Matrix Sequence
// ----------------------------------------------------------------------------
class accel_identity_seq extends accel_base_sequence;
    function new(string name = "accel_identity_seq");
        super.new(name);
    endfunction

    function void generate_item(accel_seq_item item, int idx);
        item.test_mode = TEST_MODE_IDENTITY_MATRIX;
        item.activation_enable = (idx % 2 == 1);
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                item.a_matrix[r][c] = $urandom_range(0, 200) - 100;
                item.b_matrix[r][c] = (r == c) ? 8'sd1 : 8'sd0; // B is Identity Matrix
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_identity_seq

// ----------------------------------------------------------------------------
// Sequence 5: Zero Matrix Sequence
// ----------------------------------------------------------------------------
class accel_zero_seq extends accel_base_sequence;
    function new(string name = "accel_zero_seq");
        super.new(name);
    endfunction

    function void generate_item(accel_seq_item item, int idx);
        item.test_mode = TEST_MODE_ZERO_MATRIX;
        item.activation_enable = (idx % 2 == 1);
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                item.a_matrix[r][c] = $urandom_range(0, 200) - 100;
                item.b_matrix[r][c] = 8'sd0; // B is Zero Matrix
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_zero_seq

// ----------------------------------------------------------------------------
// Sequence 6: Sparse Matrix Sequence
// ----------------------------------------------------------------------------
class accel_sparse_seq extends accel_base_sequence;
    function new(string name = "accel_sparse_seq");
        super.new(name);
    endfunction

    function void generate_item(accel_seq_item item, int idx);
        item.test_mode = TEST_MODE_SPARSE;
        item.activation_enable = (idx % 2 == 1);
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                // ~75% sparsity
                item.a_matrix[r][c] = ($urandom_range(0, 3) == 0) ? ($urandom_range(0, 200) - 100) : 8'sd0;
                item.b_matrix[r][c] = ($urandom_range(0, 3) == 0) ? ($urandom_range(0, 200) - 100) : 8'sd0;
            end
        end
        item.calculate_expected();
    endfunction
endclass : accel_sparse_seq
