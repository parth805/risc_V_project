# ==============================================================================
# File: synthesis/vivado_synth.tcl
# Description: Xilinx Vivado Non-Project Batch Synthesis & Timing Flow
# Target: Xilinx Artix-7 (xc7a100tcsg324-1) / Zynq-7000 (xc7z020clg400-1)
# ==============================================================================

# 1. Create in-memory project
set_param general.maxThreads 4
create_project -in_memory -part xc7a100tcsg324-1

# 2. Read SystemVerilog & Verilog RTL Source Files
read_verilog -sv ../rtl/accelerator/accelerator_pkg.sv
read_verilog -sv ../rtl/accelerator/mac.sv
read_verilog -sv ../rtl/accelerator/pe.sv
read_verilog -sv ../rtl/accelerator/accumulator.sv
read_verilog -sv ../rtl/accelerator/relu.sv
read_verilog -sv ../rtl/accelerator/controller.sv
read_verilog -sv ../rtl/accelerator/systolic_array.sv
read_verilog -sv ../rtl/accelerator/accelerator.sv

# 3. Read SoC Top & Core Files (Optional for full SoC synthesis)
# read_verilog -sv ../rtl/core/riscv_pkg.sv
# read_verilog -sv ../rtl/core/*.sv
# read_verilog -sv ../rtl/soc_*.sv

# 4. Target Top Module
set_property top ai_accelerator [current_fileset]

# 5. Define Clock Constraint (100 MHz target -> 10ns clock period)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# 6. Run Synthesis
synth_design -top ai_accelerator -part xc7a100tcsg324-1 -mode out_of_context

# 7. Generate Utilization and Timing Reports
file mkdir reports
report_utilization -file reports/vivado_utilization.rpt
report_timing_summary -file reports/vivado_timing_summary.rpt
report_power -file reports/vivado_power.rpt

puts "\[INFO\] Vivado Synthesis Completed Successfully!"
exit
