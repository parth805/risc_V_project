import subprocess
import os
import sys

iverilog_bin = r"P:\iverilog\bin"
env = os.environ.copy()
env["PATH"] = iverilog_bin + os.pathsep + env.get("PATH", "")

files = [
    "rtl/accelerator/accelerator_pkg.sv",
    "rtl/accelerator/mac.sv",
    "rtl/accelerator/pe.sv",
    "rtl/accelerator/accumulator.sv",
    "rtl/accelerator/relu.sv",
    "rtl/accelerator/controller.sv",
    "rtl/accelerator/systolic_array.sv",
    "rtl/accelerator/accelerator.sv",
    "tb/tb_accelerator.sv"
]

out_vvp = "sim/tb_accelerator.vvp"
compile_cmd = ["iverilog", "-g2012", "-I", "rtl", "-I", "rtl/accelerator", "-o", out_vvp] + files

print("Compiling AI Accelerator Testbench...")
res = subprocess.run(compile_cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if res.returncode != 0:
    print("Compilation failed:")
    sys.stdout.buffer.write(res.stderr)
    sys.exit(res.returncode)

print("Running AI Accelerator Simulation...")
sim_res = subprocess.run(["vvp", out_vvp], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
sys.stdout.buffer.write(sim_res.stdout)
if sim_res.stderr:
    sys.stdout.buffer.write(sim_res.stderr)

if sim_res.returncode != 0:
    sys.exit(sim_res.returncode)
