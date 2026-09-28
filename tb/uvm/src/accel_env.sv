// ============================================================================
// File: tb/uvm/src/accel_env.sv
// Description: UVM Environment for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

class accel_env;
    string name;
    accel_agent      agent;
    accel_scoreboard scoreboard;
    accel_coverage   coverage_collector;

    function new(string name = "accel_env", virtual accel_if vif);
        this.name               = name;
        this.agent              = new("accel_agent", vif);
        this.scoreboard         = new("accel_scoreboard");
        this.coverage_collector = new("accel_coverage");
    endfunction

    // Run test item through environment
    task run_item(accel_seq_item item);
        accel_seq_item monitored_item = new();
        monitored_item.test_mode = item.test_mode;

        // Drive item to DUT in parallel with passive monitor
        fork
            agent.driver.drive_transaction(item);
            agent.monitor.collect_transaction(monitored_item);
        join

        // Send to scoreboard and coverage
        scoreboard.check_transaction(monitored_item);
        coverage_collector.sample(monitored_item);
    endtask

    // Final reports
    function void report();
        scoreboard.report_summary();
        coverage_collector.report_coverage();
    endfunction

endclass : accel_env
