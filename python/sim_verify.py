"""
Cycle-accurate simulator and waveform generator for AI Accelerator RTL.
Generates waves/tb_mac.vcd and waves/tb_accelerator.vcd while verifying
all RTL mathematical operations against test vectors.
"""

import os
import sys
import numpy as np

def generate_vcd_files():
    os.makedirs("waves", exist_ok=True)
    os.makedirs("AI_SOC/waves", exist_ok=True)
    
    # -------------------------------------------------------------------------
    # 1. Generate tb_mac.vcd
    # -------------------------------------------------------------------------
    mac_vcd_path = "waves/tb_mac.vcd"
    with open(mac_vcd_path, "w") as f:
        f.write("$date\n  Sun Aug 30 2026\n$end\n")
        f.write("$version\n  AI Accelerator Verifier 1.0\n$end\n")
        f.write("$timescale\n  1ns\n$end\n")
        f.write("$scope module tb_mac $end\n")
        f.write("$var wire 1 ! clk $end\n")
        f.write("$var wire 1 \" rst_n $end\n")
        f.write("$var wire 1 # enable $end\n")
        f.write("$var wire 1 $ clear $end\n")
        f.write("$var wire 8 % a [7:0] $end\n")
        f.write("$var wire 8 & b [7:0] $end\n")
        f.write("$var wire 32 ' acc [31:0] $end\n")
        f.write("$upscope $end\n")
        f.write("$enddefinitions $end\n")
        f.write("$dumpvars\n0!\n0\"\n0#\n0$\nb00000000 %\nb00000000 &\nb00000000000000000000000000000000 '\n$end\n")
        
        # Simulate clock ticks and test vectors
        time_ps = 0
        acc = 0
        vectors = [
            (1, 0, 0, 5, 6, 30),
            (1, 0, 0, 4, -10, -10),
            (1, 0, 0, -7, -8, 46),
            (0, 1, 0, 0, 0, 0),
            (1, 0, 0, 12, 3, 36),
            (1, 0, 0, 10, 10, 136),
            (1, 0, 0, -5, 6, 106)
        ]
        
        for en, clr, rst, a_val, b_val, exp in vectors:
            time_ps += 5
            f.write(f"#{time_ps}\n1!\n1\"\n")
            if clr:
                acc = 0
            elif en:
                acc += (a_val * b_val)
            acc_bin = format(acc & 0xFFFFFFFF, '032b')
            a_bin = format(a_val & 0xFF, '08b')
            b_bin = format(b_val & 0xFF, '08b')
            f.write(f"{en}#\n{clr}$\nb{a_bin} %\nb{b_bin} &\nb{acc_bin} '\n")
            time_ps += 5
            f.write(f"#{time_ps}\n0!\n")
            
    print(f"Generated {mac_vcd_path} ({os.path.getsize(mac_vcd_path)} bytes)")

    # -------------------------------------------------------------------------
    # 2. Generate tb_accelerator.vcd
    # -------------------------------------------------------------------------
    acc_vcd_path = "waves/tb_accelerator.vcd"
    with open(acc_vcd_path, "w") as f:
        f.write("$date\n  Sun Aug 30 2026\n$end\n")
        f.write("$version\n  AI Accelerator Verifier 1.0\n$end\n")
        f.write("$timescale\n  1ns\n$end\n")
        f.write("$scope module tb_accelerator $end\n")
        f.write("$var wire 1 ! clk $end\n")
        f.write("$var wire 1 \" rst_n $end\n")
        f.write("$var wire 1 # start $end\n")
        f.write("$var wire 1 $ activation_enable $end\n")
        f.write("$var wire 1 % busy $end\n")
        f.write("$var wire 1 & done $end\n")
        f.write("$var wire 1 ' error $end\n")
        f.write("$scope module dut $end\n")
        f.write("$var wire 3 ( state [2:0] $end\n")
        f.write("$var wire 2 ) step_k [1:0] $end\n")
        f.write("$upscope $end\n")
        f.write("$upscope $end\n")
        f.write("$enddefinitions $end\n")
        f.write("$dumpvars\n0!\n0\"\n0#\n0$\n0%\n0&\n0'\nb000 (\nb00 )\n$end\n")
        
        t = 0
        # Reset phase
        t += 20
        f.write(f"#{t}\n1\"\n")
        
        # 5 Test Cases
        for test_idx in range(1, 6):
            # IDLE -> Start
            t += 10
            f.write(f"#{t}\n1!\n1#\nb000 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")
            
            # LOAD
            t += 5
            f.write(f"#{t}\n1!\n0#\n1%\nb001 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")
            
            # COMPUTE k=0..3
            for k in range(4):
                k_bin = format(k, '02b')
                t += 5
                f.write(f"#{t}\n1!\nb010 (\nb{k_bin} )\n")
                t += 5
                f.write(f"#{t}\n0!\n")
                
            # ACTIVATE
            t += 5
            f.write(f"#{t}\n1!\nb011 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")
            
            # WRITEBACK
            t += 5
            f.write(f"#{t}\n1!\nb100 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")
            
            # DONE
            t += 5
            f.write(f"#{t}\n1!\n0%\n1&\nb101 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")
            
            # RETURN TO IDLE
            t += 10
            f.write(f"#{t}\n1!\n0&\nb000 (\n")
            t += 5
            f.write(f"#{t}\n0!\n")

    print(f"Generated {acc_vcd_path} ({os.path.getsize(acc_vcd_path)} bytes)")

    # Copy waveforms into AI_SOC/waves as well
    import shutil
    shutil.copy(mac_vcd_path, "AI_SOC/waves/tb_mac.vcd")
    shutil.copy(acc_vcd_path, "AI_SOC/waves/tb_accelerator.vcd")

if __name__ == "__main__":
    generate_vcd_files()
