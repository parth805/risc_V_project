# ==============================================================================
# RISC-V AI Accelerator SoC - Comprehensive Build & Simulation Makefile
# Simulator: Icarus Verilog (iverilog -g2012 / vvp) & Python Cycle-Accurate Model
# Waveform Viewer: GTKWave
# ==============================================================================

SIM_DIR   = sim
WAVES_DIR = waves
RTL_DIR   = rtl
TB_DIR    = tb
PYTHON    = python

IVFLAGS   = -g2012 -Wall

# ------------------------------------------------------------------------------
# Source File Lists
# ------------------------------------------------------------------------------
ACCEL_SRCS = $(RTL_DIR)/accelerator/accelerator_pkg.sv \
             $(RTL_DIR)/accelerator/mac.sv \
             $(RTL_DIR)/accelerator/pe.sv \
             $(RTL_DIR)/accelerator/systolic_array.sv \
             $(RTL_DIR)/accelerator/accumulator.sv \
             $(RTL_DIR)/accelerator/relu.sv \
             $(RTL_DIR)/accelerator/controller.sv \
             $(RTL_DIR)/accelerator/accelerator.sv

CORE_SRCS  = $(RTL_DIR)/core/riscv_pkg.sv \
             $(RTL_DIR)/core/alu.sv \
             $(RTL_DIR)/core/branch_comp.sv \
             $(RTL_DIR)/core/control_unit.sv \
             $(RTL_DIR)/core/hazard_unit.sv \
             $(RTL_DIR)/core/imm_gen.sv \
             $(RTL_DIR)/core/load_store_unit.sv \
             $(RTL_DIR)/core/register_file.sv \
             $(RTL_DIR)/core/riscv_core.sv

SOC_SRCS   = $(CORE_SRCS) \
             $(ACCEL_SRCS) \
             $(RTL_DIR)/soc_sram.sv \
             $(RTL_DIR)/soc_interconnect.sv \
             $(RTL_DIR)/soc_top.sv

MAC_TB_SRCS   = $(RTL_DIR)/accelerator/mac.sv $(TB_DIR)/tb_mac.sv
ACCEL_TB_SRCS = $(ACCEL_SRCS) $(TB_DIR)/tb_accelerator.sv
CORE_TB_SRCS  = $(CORE_SRCS) $(TB_DIR)/core/tb_riscv_core.sv
SOC_TB_SRCS   = $(SOC_SRCS) $(TB_DIR)/tb_soc_top.sv

all: test

# ------------------------------------------------------------------------------
# Directory Setup
# ------------------------------------------------------------------------------
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(WAVES_DIR):
	mkdir -p $(WAVES_DIR)

# ------------------------------------------------------------------------------
# Firmware Generation
# ------------------------------------------------------------------------------
firmware: $(SIM_DIR)
	$(PYTHON) python/generate_firmware.py

# ------------------------------------------------------------------------------
# Hardware Compilation Targets
# ------------------------------------------------------------------------------
compile_mac: $(SIM_DIR)
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_mac $(MAC_TB_SRCS)

compile_accel: $(SIM_DIR)
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_accelerator $(ACCEL_TB_SRCS)

compile_core: $(SIM_DIR)
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_core $(CORE_TB_SRCS)

compile_soc: $(SIM_DIR) firmware
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_soc $(SOC_TB_SRCS)

compile: compile_mac compile_accel compile_core compile_soc

# ------------------------------------------------------------------------------
# Simulation Targets
# ------------------------------------------------------------------------------
test_mac: compile_mac $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_mac

test_accel: compile_accel $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_accelerator

test_core: compile_core $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_core

test_soc: compile_soc $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_soc

# Python Simulation
sim_py_soc: firmware
	$(PYTHON) python/sim_soc.py

test_all: test_mac test_accel test_core test_soc sim_py_soc

test: sim_py_soc

# ------------------------------------------------------------------------------
# Golden Reference Models & Benchmarks
# ------------------------------------------------------------------------------
golden:
	$(PYTHON) python/golden_model.py

benchmark:
	$(PYTHON) python/benchmark_cpu_vs_accel.py

telemetry:
	$(PYTHON) scripts/generate_timing_report.py

nn_demo:
	$(PYTHON) python/sim_nn_demo.py

# ------------------------------------------------------------------------------
# UVM Verification Targets
# ------------------------------------------------------------------------------
uvm:
	$(PYTHON) python/run_uvm_suite.py

test_uvm: uvm

wave_uvm:
	gtkwave $(WAVES_DIR)/tb_accel_uvm.vcd &

# ------------------------------------------------------------------------------
# Clean Target
# ------------------------------------------------------------------------------
clean:
	rm -rf $(SIM_DIR) $(WAVES_DIR)/*.vcd reports/*.html

.PHONY: all compile compile_mac compile_accel compile_core compile_soc test test_mac test_accel test_core test_soc test_all sim_py_soc golden benchmark telemetry nn_demo uvm test_uvm wave_uvm clean
