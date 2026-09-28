// ============================================================================
// File: tb/uvm/src/accel_monitor.sv
// Description: UVM Monitor Component for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

class accel_monitor;
    virtual accel_if.MONITOR vif;
    string name;

    function new(string name = "accel_monitor", virtual accel_if.MONITOR vif);
        this.name = name;
        this.vif  = vif;
    endfunction

    // Passively monitor and collect a completed execution transaction
    task collect_transaction(accel_seq_item item);
        int cycle_count = 0;

        // Wait for start signal
        while (!vif.mon_cb.start) begin
            @(vif.mon_cb);
        end

        // Sample input operands and config
        item.activation_enable = vif.mon_cb.activation_enable;
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                item.a_matrix[r][c] = vif.mon_cb.a_matrix[r][c];
                item.b_matrix[r][c] = vif.mon_cb.b_matrix[r][c];
            end
        end

        // Monitor execution latency until done is asserted
        @(vif.mon_cb);
        while (!vif.mon_cb.done) begin
            cycle_count++;
            @(vif.mon_cb);
        end

        item.latency_cycles = cycle_count;

        // Sample output matrix results from DUT
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                item.c_matrix[r][c] = vif.mon_cb.c_matrix[r][c];
            end
        end

        // Compute golden model prediction
        item.calculate_expected();
    endtask

endclass : accel_monitor
