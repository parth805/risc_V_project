// ============================================================================
// File: tb/uvm/src/accel_scoreboard.sv
// Description: UVM Scoreboard for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

class accel_scoreboard;
    string name;
    int total_transactions;
    int passed_transactions;
    int failed_transactions;
    int total_latency;
    int min_latency;
    int max_latency;

    function new(string name = "accel_scoreboard");
        this.name = name;
        this.total_transactions = 0;
        this.passed_transactions = 0;
        this.failed_transactions = 0;
        this.total_latency = 0;
        this.min_latency = 999999;
        this.max_latency = 0;
    endfunction

    // Check transaction and update scoreboard statistics
    function bit check_transaction(accel_seq_item item);
        bit is_match = 1'b1;
        total_transactions++;

        // Update latency metrics
        total_latency += item.latency_cycles;
        if (item.latency_cycles < min_latency) min_latency = item.latency_cycles;
        if (item.latency_cycles > max_latency) max_latency = item.latency_cycles;

        // Perform bit-exact comparison
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                if (item.c_matrix[r][c] !== item.expected_c[r][c]) begin
                    is_match = 1'b0;
                    $display("[SCOREBOARD MISMATCH] Trans #%0d @ (%0d,%0d): Expected = %0d, Got = %0d (ActEn=%b)",
                             total_transactions, r, c, item.expected_c[r][c], item.c_matrix[r][c], item.activation_enable);
                end
            end
        end

        if (is_match) begin
            passed_transactions++;
        end else begin
            failed_transactions++;
        end

        return is_match;
    endfunction

    // Print final scoreboard summary report
    function void report_summary();
        real avg_latency = total_transactions > 0 ? real'(total_latency) / real'(total_transactions) : 0.0;
        $display("\n================================================================================");
        $display("                       UVM SCOREBOARD FINAL REPORT                             ");
        $display("================================================================================");
        $display(" Total Transactions Checked : %0d", total_transactions);
        $display(" Transactions Passed        : %0d", passed_transactions);
        $display(" Transactions Failed        : %0d", failed_transactions);
        $display(" Scoreboard Match Rate      : %0.2f%%", total_transactions > 0 ? (real'(passed_transactions) * 100.0 / real'(total_transactions)) : 0.0);
        $display(" Execution Latency (Cycles) : Min = %0d, Max = %0d, Avg = %0.2f", min_latency == 999999 ? 0 : min_latency, max_latency, avg_latency);
        if (failed_transactions == 0 && total_transactions > 0) begin
            $display(" STATUS                     : >>> ALL UVM TESTS PASSED [100%% BIT-EXACT] <<<");
        end else begin
            $display(" STATUS                     : >>> VERIFICATION FAILED (%0d MISMATCHES) <<<", failed_transactions);
        end
        $display("================================================================================\n");
    endfunction

endclass : accel_scoreboard
