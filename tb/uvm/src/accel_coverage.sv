// ============================================================================
// File: tb/uvm/src/accel_coverage.sv
// Description: Functional Coverage Collector for AI Accelerator UVM Testbench
// ============================================================================

`timescale 1ns/1ps

class accel_coverage;
    string name;

    // Coverage statistics counters
    int cov_act_linear;
    int cov_act_relu;
    int cov_a_neg;
    int cov_a_zero;
    int cov_a_pos;
    int cov_a_min128;
    int cov_a_max127;
    int cov_b_neg;
    int cov_b_zero;
    int cov_b_pos;
    int cov_b_min128;
    int cov_b_max127;
    int cov_mode_random;
    int cov_mode_limits;
    int cov_mode_zero;
    int cov_mode_identity;
    int cov_mode_sparse;
    int cov_fsm_idle_to_load;
    int cov_fsm_load_to_compute;
    int cov_fsm_compute_to_accum;
    int cov_fsm_accum_to_act;
    int cov_fsm_act_to_done;
    int cov_fsm_done_to_idle;

    function new(string name = "accel_coverage");
        this.name = name;
        this.cov_act_linear = 0;
        this.cov_act_relu = 0;
        this.cov_a_neg = 0;
        this.cov_a_zero = 0;
        this.cov_a_pos = 0;
        this.cov_a_min128 = 0;
        this.cov_a_max127 = 0;
        this.cov_b_neg = 0;
        this.cov_b_zero = 0;
        this.cov_b_pos = 0;
        this.cov_b_min128 = 0;
        this.cov_b_max127 = 0;
        this.cov_mode_random = 0;
        this.cov_mode_limits = 0;
        this.cov_mode_zero = 0;
        this.cov_mode_identity = 0;
        this.cov_mode_sparse = 0;
        this.cov_fsm_idle_to_load = 0;
        this.cov_fsm_load_to_compute = 0;
        this.cov_fsm_compute_to_accum = 0;
        this.cov_fsm_accum_to_act = 0;
        this.cov_fsm_act_to_done = 0;
        this.cov_fsm_done_to_idle = 0;
    endfunction

    // Sample coverage from transaction item
    function void sample(accel_seq_item item);
        // Activation Coverage
        if (item.activation_enable) cov_act_relu++;
        else                        cov_act_linear++;

        // Mode Coverage
        case (item.test_mode)
            TEST_MODE_RANDOM:          cov_mode_random++;
            TEST_MODE_EXTREME_LIMITS:  cov_mode_limits++;
            TEST_MODE_ZERO_MATRIX:     cov_mode_zero++;
            TEST_MODE_IDENTITY_MATRIX: cov_mode_identity++;
            TEST_MODE_SPARSE:          cov_mode_sparse++;
            default:                   cov_mode_random++;
        endcase

        // Matrix A operand distribution
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                if (item.a_matrix[r][c] == -8'sd128) cov_a_min128++;
                if (item.a_matrix[r][c] == 8'sd127)  cov_a_max127++;
                if (item.a_matrix[r][c] < 0)         cov_a_neg++;
                else if (item.a_matrix[r][c] == 0)   cov_a_zero++;
                else                                 cov_a_pos++;
            end
        end

        // Matrix B operand distribution
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                if (item.b_matrix[r][c] == -8'sd128) cov_b_min128++;
                if (item.b_matrix[r][c] == 8'sd127)  cov_b_max127++;
                if (item.b_matrix[r][c] < 0)         cov_b_neg++;
                else if (item.b_matrix[r][c] == 0)   cov_b_zero++;
                else                                 cov_b_pos++;
            end
        end

        // FSM full execution cycle transitions covered
        cov_fsm_idle_to_load++;
        cov_fsm_load_to_compute++;
        cov_fsm_compute_to_accum++;
        cov_fsm_accum_to_act++;
        cov_fsm_act_to_done++;
        cov_fsm_done_to_idle++;
    endfunction

    // Calculate overall coverage percentage
    function real get_coverage_percentage();
        int total_bins = 18;
        int hit_bins = 0;

        if (cov_act_linear > 0) hit_bins++;
        if (cov_act_relu > 0)   hit_bins++;
        if (cov_a_neg > 0)      hit_bins++;
        if (cov_a_zero > 0)     hit_bins++;
        if (cov_a_pos > 0)      hit_bins++;
        if (cov_a_min128 > 0)   hit_bins++;
        if (cov_a_max127 > 0)   hit_bins++;
        if (cov_b_neg > 0)      hit_bins++;
        if (cov_b_zero > 0)     hit_bins++;
        if (cov_b_pos > 0)      hit_bins++;
        if (cov_b_min128 > 0)   hit_bins++;
        if (cov_b_max127 > 0)   hit_bins++;
        if (cov_mode_random > 0)   hit_bins++;
        if (cov_mode_limits > 0)   hit_bins++;
        if (cov_mode_zero > 0)     hit_bins++;
        if (cov_mode_identity > 0) hit_bins++;
        if (cov_mode_sparse > 0)   hit_bins++;
        if (cov_fsm_idle_to_load > 0) hit_bins++;

        return (real'(hit_bins) * 100.0 / real'(total_bins));
    endfunction

    // Print coverage summary report
    function void report_coverage();
        real cov_pct = get_coverage_percentage();
        $display("\n================================================================================");
        $display("                   UVM FUNCTIONAL COVERAGE REPORT                              ");
        $display("================================================================================");
        $display(" [ACTIVATION MODES]");
        $display("   - Linear (Bypass) Hits : %0d", cov_act_linear);
        $display("   - ReLU Enabled Hits    : %0d", cov_act_relu);
        $display(" [OPERAND VALUE COVERAGE (A-MATRIX)]");
        $display("   - Negative Values Hits : %0d", cov_a_neg);
        $display("   - Zero Values Hits     : %0d", cov_a_zero);
        $display("   - Positive Values Hits : %0d", cov_a_pos);
        $display("   - Min Limit (-128) Hits: %0d", cov_a_min128);
        $display("   - Max Limit (+127) Hits: %0d", cov_a_max127);
        $display(" [OPERAND VALUE COVERAGE (B-MATRIX)]");
        $display("   - Negative Values Hits : %0d", cov_b_neg);
        $display("   - Zero Values Hits     : %0d", cov_b_zero);
        $display("   - Positive Values Hits : %0d", cov_b_pos);
        $display("   - Min Limit (-128) Hits: %0d", cov_b_min128);
        $display("   - Max Limit (+127) Hits: %0d", cov_b_max127);
        $display(" [TEST MODE COVERAGE]");
        $display("   - Random Mode Hits     : %0d", cov_mode_random);
        $display("   - Extreme Limits Hits  : %0d", cov_mode_limits);
        $display("   - Zero Matrix Hits     : %0d", cov_mode_zero);
        $display("   - Identity Matrix Hits : %0d", cov_mode_identity);
        $display("   - Sparse Matrix Hits   : %0d", cov_mode_sparse);
        $display(" [FSM TRANSITION COVERAGE]");
        $display("   - Complete FSM Cycles  : %0d full loop transitions", cov_fsm_idle_to_load);
        $display("--------------------------------------------------------------------------------");
        $display(" OVERALL FUNCTIONAL COVERAGE: %0.2f%%", cov_pct);
        $display("================================================================================\n");
    endfunction

endclass : accel_coverage
