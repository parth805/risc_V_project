`timescale 1ns/1ps

module tb_hazard_unit;

  logic        id_ex_mem_read;
  logic [4:0]  id_ex_rd;

  logic        ex_mem_mem_read;
  logic [4:0]  ex_mem_rd;

  logic [4:0]  if_id_rs1;
  logic [4:0]  if_id_rs2;

  logic        stall;

  integer error_count;

  hazard_unit dut (
    .id_ex_mem_read  (id_ex_mem_read),
    .id_ex_rd        (id_ex_rd),
    .ex_mem_mem_read (ex_mem_mem_read),
    .ex_mem_rd       (ex_mem_rd),
    .if_id_rs1       (if_id_rs1),
    .if_id_rs2       (if_id_rs2),
    .stall            (stall)
  );

  task check_stall;
    input expected;
    input [255:0] test_name;
    begin
      #1;
      if (stall !== expected) begin
        $display("[ERROR] %s: expected stall=%b, got stall=%b",
                 test_name, expected, stall);
        error_count++;
      end else begin
        $display("[PASS] %s", test_name);
      end
    end
  endtask

  initial begin
    error_count = 0;

    // Default inputs
    id_ex_mem_read  = 1'b0;
    id_ex_rd        = 5'd0;
    ex_mem_mem_read = 1'b0;
    ex_mem_rd       = 5'd0;
    if_id_rs1       = 5'd0;
    if_id_rs2       = 5'd0;

    // Test 1: No hazard
    check_stall(1'b0, "No hazard");

    // Test 2: Load-use hazard through rs1
    id_ex_mem_read = 1'b1;
    id_ex_rd       = 5'd5;
    if_id_rs1      = 5'd5;
    if_id_rs2      = 5'd0;
    check_stall(1'b1, "ID/EX load hazard on rs1");

    // Test 3: Load-use hazard through rs2
    if_id_rs1 = 5'd0;
    if_id_rs2 = 5'd5;
    check_stall(1'b1, "ID/EX load hazard on rs2");

    // Test 4: Different registers -> no hazard
    if_id_rs1 = 5'd6;
    if_id_rs2 = 5'd7;
    check_stall(1'b0, "Different registers");

    // Test 5: rd=x0 must never cause a stall
    id_ex_rd  = 5'd0;
    if_id_rs1 = 5'd0;
    if_id_rs2 = 5'd0;
    check_stall(1'b0, "x0 destination ignored");

    // Test 6: EX/MEM load hazard
    id_ex_mem_read  = 1'b0;
    ex_mem_mem_read = 1'b1;
    ex_mem_rd       = 5'd8;
    if_id_rs1       = 5'd8;
    if_id_rs2       = 5'd0;
    check_stall(1'b1, "EX/MEM load hazard on rs1");

    // Test 7: EX/MEM load hazard through rs2
    if_id_rs1 = 5'd0;
    if_id_rs2 = 5'd8;
    check_stall(1'b1, "EX/MEM load hazard on rs2");

    // Test 8: Different EX/MEM destination -> no hazard
    if_id_rs1 = 5'd9;
    if_id_rs2 = 5'd10;
    check_stall(1'b0, "No EX/MEM hazard");

    $display("=================================================");
    if (error_count == 0)
      $display(" ALL HAZARD UNIT TESTS PASSED (0 ERRORS)");
    else
      $display(" HAZARD UNIT FAILED WITH %0d ERRORS", error_count);
    $display("=================================================");

    $finish;
  end

endmodule