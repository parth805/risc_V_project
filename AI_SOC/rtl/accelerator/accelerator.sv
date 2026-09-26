`timescale 1ns/1ps

import accelerator_pkg::*;

module ai_accelerator #(
    parameter int DATA_WIDTH   = 8,
    parameter int ACC_WIDTH    = 32,
    parameter int MATRIX_SIZE  = 4,
    parameter int NUM_ELEMENTS = MATRIX_SIZE * MATRIX_SIZE
)(
    input  logic                                            clk,
    input  logic                                            rst_n,
    
    // Direct hardware control interface
    input  logic                                            start,
    input  logic                                            activation_enable,
    
    // Direct 4x4 matrix inputs (INT8) and output (INT32)
    input  logic signed [DATA_WIDTH-1:0]                    a_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    input  logic signed [DATA_WIDTH-1:0]                    b_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic signed [ACC_WIDTH-1:0]                     c_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    
    // Status flags
    output logic                                            busy,
    output logic                                            done,
    output logic                                            error,

    // Optional Memory-Mapped Register Abstraction Interface (Pre-wired for RISC-V SoC bus)
    input  logic                                            reg_we,
    input  logic [31:0]                                     reg_addr,
    input  logic [31:0]                                     reg_wdata,
    output logic [31:0]                                     reg_rdata
);

    // =========================================================================
    // Internal Registers for Configuration and Operands
    // =========================================================================
    logic signed [DATA_WIDTH-1:0] a_reg [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [DATA_WIDTH-1:0] b_reg [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic                         act_en_reg;

    // Memory-mapped CSR registersx
    logic [31:0] reg_addr_a;
    logic [31:0] reg_addr_b;
    logic [31:0] reg_addr_c;
    logic        reg_start_pulse;

    // Controller signals
    logic        ctrl_start;
    logic        ctrl_busy;
    logic        ctrl_done;
    logic        ctrl_error;
    logic        load_en;
    logic        mac_clear;
    logic        mac_enable;
    logic [1:0]  compute_step;
    logic        wb_en;
    state_t      current_state;

    // Systolic array and ReLU intermediate signals
    logic signed [ACC_WIDTH-1:0] raw_c_matrix  [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [ACC_WIDTH-1:0] relu_c_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [ACC_WIDTH-1:0] final_c_matrix[0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Status output assignments
    assign busy  = ctrl_busy;
    assign done  = ctrl_done;
    assign error = ctrl_error;

    // Start signal is active either via direct hardware port or register write
    assign ctrl_start = start | reg_start_pulse;

    // =========================================================================
    // Memory-Mapped CSR Register Logic
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_addr_a      <= 32'h0000_0000;
            reg_addr_b      <= 32'h0000_0000;
            reg_addr_c      <= 32'h0000_0000;
            reg_start_pulse <= 1'b0;
        end else begin
            reg_start_pulse <= 1'b0; // Single cycle pulse
            if (reg_we) begin
                case (reg_addr)
                    REG_CTRL: begin
                        if (reg_wdata[CTRL_START_BIT]) begin
                            reg_start_pulse <= 1'b1;
                        end
                    end
                    REG_ADDR_A:  reg_addr_a <= reg_wdata;
                    REG_ADDR_B:  reg_addr_b <= reg_wdata;
                    REG_ADDR_C:  reg_addr_c <= reg_wdata;
                    default: ;
                endcase
            end
        end
    end

    // CSR Read multiplexer
    always_comb begin
        case (reg_addr)
            REG_CTRL:     reg_rdata = {31'd0, ctrl_start};
            REG_STATUS:   reg_rdata = {29'd0, ctrl_error, ctrl_busy, ctrl_done};
            REG_CFG_SIZE: reg_rdata = 32'(MATRIX_SIZE);
            REG_CFG_K:    reg_rdata = 32'(MATRIX_SIZE);
            REG_ADDR_A:   reg_rdata = reg_addr_a;
            REG_ADDR_B:   reg_rdata = reg_addr_b;
            REG_ADDR_C:   reg_rdata = reg_addr_c;
            REG_CFG_ACT:  reg_rdata = {31'd0, act_en_reg};
            default:      reg_rdata = 32'h0000_0000;
        endcase
    end

    // =========================================================================
    // Input Matrix Operand Latching
    // =========================================================================
    integer r_idx, c_idx;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_en_reg <= 1'b0;
            for (r_idx = 0; r_idx < MATRIX_SIZE; r_idx = r_idx + 1) begin
                for (c_idx = 0; c_idx < MATRIX_SIZE; c_idx = c_idx + 1) begin
                    a_reg[r_idx][c_idx] <= '0;
                    b_reg[r_idx][c_idx] <= '0;
                end
            end
        end else if (load_en) begin
            act_en_reg <= activation_enable;
            for (r_idx = 0; r_idx < MATRIX_SIZE; r_idx = r_idx + 1) begin
                for (c_idx = 0; c_idx < MATRIX_SIZE; c_idx = c_idx + 1) begin
                    a_reg[r_idx][c_idx] <= a_matrix[r_idx][c_idx];
                    b_reg[r_idx][c_idx] <= b_matrix[r_idx][c_idx];
                end
            end
        end
    end

    // =========================================================================
    // Controller FSM Instance
    // =========================================================================
    controller #(
        .MATRIX_SIZE(MATRIX_SIZE)
    ) u_controller (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (ctrl_start),
        .busy         (ctrl_busy),
        .done         (ctrl_done),
        .error        (ctrl_error),
        .load_en      (load_en),
        .mac_clear    (mac_clear),
        .mac_enable   (mac_enable),
        .compute_step (compute_step),
        .wb_en        (wb_en),
        .state_out    (current_state)
    );

    // =========================================================================
    // 4x4 Systolic Array Instance
    // =========================================================================
    systolic_array #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) u_systolic_array (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (mac_enable),
        .clear      (mac_clear),
        .step_k     (compute_step),
        .a_matrix   (a_reg),
        .b_matrix   (b_reg),
        .c_matrix   (raw_c_matrix)
    );

    // =========================================================================
    // ReLU Activation Logic (Generate Loop)
    // =========================================================================
    genvar gr, gc;
    generate
        for (gr = 0; gr < MATRIX_SIZE; gr = gr + 1) begin : gen_relu_r
            for (gc = 0; gc < MATRIX_SIZE; gc = gc + 1) begin : gen_relu_c
                relu #(
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_relu (
                    .data_in (raw_c_matrix[gr][gc]),
                    .data_out(relu_c_matrix[gr][gc])
                );

                // Activation bypass multiplexer
                assign final_c_matrix[gr][gc] = (act_en_reg) ? 
                                                relu_c_matrix[gr][gc] : 
                                                raw_c_matrix[gr][gc];
            end
        end
    endgenerate

    // =========================================================================
    // Result Storage Accumulator Instance
    // =========================================================================
    accumulator #(
        .ACC_WIDTH   (ACC_WIDTH),
        .MATRIX_SIZE (MATRIX_SIZE),
        .NUM_ELEMENTS(NUM_ELEMENTS)
    ) u_accumulator (
        .clk             (clk),
        .rst_n           (rst_n),
        .clear           (mac_clear),
        .write_enable    (1'b0),
        .addr            ('0),
        .data_in         ('0),
        .parallel_we     (wb_en),
        .parallel_data_in(final_c_matrix),
        .data_out        (),
        .matrix_out      (c_matrix)
    );

    // =========================================================================
    // Basic Assertions for Validation
    // =========================================================================
    `ifndef SYNTHESIS
    // Check reset clears controller state
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            assert (current_state == STATE_IDLE)
                else $error("Assertion Failed: Controller state is not IDLE during reset!");
        end
    end

    // Ensure busy and done are not simultaneously asserted indefinitely
    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert (!(busy && done))
                else $error("Assertion Failed: Controller cannot be both BUSY and DONE simultaneously!");
        end
    end
    `endif

endmodule
