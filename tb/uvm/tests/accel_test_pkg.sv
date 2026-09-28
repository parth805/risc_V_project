// ============================================================================
// File: tb/uvm/tests/accel_test_pkg.sv
// Description: UVM Test Package aggregating all verification components
// ============================================================================

`timescale 1ns/1ps

package accel_test_pkg;
    `include "accel_seq_item.sv"
    `include "accel_sequence.sv"
    `include "accel_driver.sv"
    `include "accel_monitor.sv"
    `include "accel_scoreboard.sv"
    `include "accel_coverage.sv"
    `include "accel_agent.sv"
    `include "accel_env.sv"
endpackage : accel_test_pkg
