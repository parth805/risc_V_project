// ============================================================================
// File: tb/uvm/src/accel_agent.sv
// Description: UVM Agent encapsulating Driver and Monitor for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

class accel_agent;
    string name;
    accel_driver  driver;
    accel_monitor monitor;

    function new(string name = "accel_agent", virtual accel_if vif);
        this.name    = name;
        this.driver  = new("accel_driver", vif.DRIVER);
        this.monitor = new("accel_monitor", vif.MONITOR);
    endfunction

endclass : accel_agent
