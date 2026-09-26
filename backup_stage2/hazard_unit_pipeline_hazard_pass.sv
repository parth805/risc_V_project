// ============================================================================
// File: rtl/core/hazard_unit.sv
// Description: Load-use hazard detection for the 5-stage RV32I pipeline
// ============================================================================

module hazard_unit (
  input  logic        id_ex_mem_read,
  input  logic [4:0]  id_ex_rd,

  input  logic        ex_mem_mem_read,
  input  logic [4:0]  ex_mem_rd,

  input  logic [4:0]  if_id_rs1,
  input  logic [4:0]  if_id_rs2,

  output logic        stall
);

  always_comb begin
    stall = 1'b0;

    // Stall while the load is in ID/EX.
    if (id_ex_mem_read &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2))) begin
      stall = 1'b1;
    end

    // Keep the dependent instruction stalled for one more cycle
    // while the load is in EX/MEM.
    if (ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) &&
        ((ex_mem_rd == if_id_rs1) ||
         (ex_mem_rd == if_id_rs2))) begin
      stall = 1'b1;
    end
  end

endmodule