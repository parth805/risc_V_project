// ============================================================================
// File: tb/uvm/src/accel_driver.sv
// Description: UVM Driver Component for AI Accelerator
// ============================================================================

`timescale 1ns/1ps

class accel_driver;
    virtual accel_if.DRIVER vif;
    string name;

    function new(string name = "accel_driver", virtual accel_if.DRIVER vif);
        this.name = name;
        this.vif  = vif;
    endfunction

    // Reset task
    task reset_dut();
        vif.drv_cb.start             <= 1'b0;
        vif.drv_cb.activation_enable <= 1'b0;
        vif.drv_cb.reg_we            <= 1'b0;
        vif.drv_cb.reg_addr          <= 32'h0;
        vif.drv_cb.reg_wdata         <= 32'h0;
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                vif.drv_cb.a_matrix[r][c] <= 8'sd0;
                vif.drv_cb.b_matrix[r][c] <= 8'sd0;
            end
        end
        @(vif.drv_cb);
    endtask

    // Drive a single matrix multiplication transaction
    task drive_transaction(accel_seq_item item);
        @(vif.drv_cb);
        
        // Apply matrix inputs & configuration
        vif.drv_cb.activation_enable <= item.activation_enable;
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                vif.drv_cb.a_matrix[r][c] <= item.a_matrix[r][c];
                vif.drv_cb.b_matrix[r][c] <= item.b_matrix[r][c];
            end
        end

        // Assert start pulse
        vif.drv_cb.start <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.start <= 1'b0;

        // Wait until accelerator finishes processing (done == 1)
        while (!vif.drv_cb.done) begin
            @(vif.drv_cb);
        end
        
        // Wait 1 cycle after done
        @(vif.drv_cb);
    endtask

endclass : accel_driver
