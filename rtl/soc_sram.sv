// ============================================================================
// File: rtl/soc_sram.sv
// Description: Synthesizable 16KB Byte-Addressable Dual-Port SRAM Subsystem
//              Port A: Instruction ROM/RAM (Read-Only)
//              Port B: Data RAM (Read/Write with Byte-Enable Strobes)
// ============================================================================

`timescale 1ns/1ps

module soc_sram #(
    parameter int MEM_SIZE_BYTES = 16384,            // 16 KB
    parameter int NUM_WORDS      = MEM_SIZE_BYTES / 4, // 4096 32-bit words
    parameter string INIT_FILE   = ""
)(
    input  logic        clk,
    input  logic        rst_n,

    // ------------------------------------------------------------------------
    // Port A: Instruction Fetch (Word-Aligned Read)
    // ------------------------------------------------------------------------
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_rdata,

    // ------------------------------------------------------------------------
    // Port B: Data Access (Byte-Addressable Read/Write)
    // ------------------------------------------------------------------------
    input  logic        data_req,
    input  logic        data_we,
    input  logic [3:0]  data_wstrb,
    input  logic [31:0] data_addr,
    input  logic [31:0] data_wdata,
    output logic [31:0] data_rdata
);

    // 4K x 32-bit Memory Array (16 KB)
    logic [31:0] mem [0:NUM_WORDS-1];

    // Word address indices (12-bit word index for 4096 words)
    logic [$clog2(NUM_WORDS)-1:0] instr_word_idx;
    logic [$clog2(NUM_WORDS)-1:0] data_word_idx;

    assign instr_word_idx = instr_addr[$clog2(MEM_SIZE_BYTES)-1:2];
    assign data_word_idx  = data_addr[$clog2(MEM_SIZE_BYTES)-1:2];

    // ------------------------------------------------------------------------
    // Port A: Combinational / Low-Latency Instruction Fetch
    // ------------------------------------------------------------------------
    assign instr_rdata = (instr_word_idx < NUM_WORDS) ? mem[instr_word_idx] : 32'h00000013; // NOP if out of bounds

    // ------------------------------------------------------------------------
    // Port B: Synchronous Data Write with Byte Enables
    // ------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (data_req && data_we && (data_word_idx < NUM_WORDS)) begin
            if (data_wstrb[0]) mem[data_word_idx][7:0]   <= data_wdata[7:0];
            if (data_wstrb[1]) mem[data_word_idx][15:8]  <= data_wdata[15:8];
            if (data_wstrb[2]) mem[data_word_idx][23:16] <= data_wdata[23:16];
            if (data_wstrb[3]) mem[data_word_idx][31:24] <= data_wdata[31:24];
        end
    end

    // Port B: Combinational Read
    assign data_rdata = (data_req && !data_we && (data_word_idx < NUM_WORDS)) ? 
                        mem[data_word_idx] : 32'h0000_0000;

    // ------------------------------------------------------------------------
    // Optional Memory Preload for Simulation / Firmware
    // ------------------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < NUM_WORDS; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

endmodule
