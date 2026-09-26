"""
================================================================================
File: scripts/generate_timing_report.py
Description: Generates unified timing and performance telemetry comparing
             the RISC-V Scalar CPU core vs. AI Accelerator Coprocessor.
================================================================================
"""

import json
import os
import sys

def compute_metrics(clock_freq_mhz=100.0):
    period_ns = 1000.0 / clock_freq_mhz
    
    matrix_sizes = [4, 8, 16, 32, 64]
    benchmarks = []
    
    for n in matrix_sizes:
        total_macs = n * n * n
        
        # 1. RISC-V CPU Estimation:
        # Loop overheads + LB + MUL + ADD + SW + Branch per element
        # For N=4: ~845 cycles
        cpu_cycles = 1 + n * (1 + n * (2 + n * 11 + 2 + 2 + 2) + 2)
        cpu_latency_us = (cpu_cycles * period_ns) / 1000.0
        cpu_macs_per_cycle = total_macs / cpu_cycles
        
        # 2. AI Accelerator Estimation:
        # Tiled across 4x4 array:
        # num_tiles = (N/4) * (N/4) * (N/4)
        # cycles_per_tile = 8 (1 load + 4 compute + 1 act + 1 wb + 1 done)
        num_tiles = (n // 4) * (n // 4) * (n // 4)
        accel_cycles = num_tiles * 8
        accel_latency_us = (accel_cycles * period_ns) / 1000.0
        accel_macs_per_cycle = total_macs / accel_cycles
        
        speedup = cpu_cycles / accel_cycles
        time_saved_pct = ((cpu_cycles - accel_cycles) / cpu_cycles) * 100.0
        
        benchmarks.append({
            "matrix_size": f"{n}x{n}",
            "total_macs": total_macs,
            "cpu_cycles": cpu_cycles,
            "cpu_latency_us": round(cpu_latency_us, 3),
            "cpu_macs_per_cycle": round(cpu_macs_per_cycle, 4),
            "accel_cycles": accel_cycles,
            "accel_latency_us": round(accel_latency_us, 3),
            "accel_macs_per_cycle": round(accel_macs_per_cycle, 3),
            "speedup_ratio": round(speedup, 1),
            "latency_reduction_pct": round(time_saved_pct, 2)
        })
        
    fsm_timing_trace = [
        {"cycle": 0, "time_ns": 0,  "state": "IDLE",      "step_k": 0, "busy": 0, "done": 0, "mac_en": 0},
        {"cycle": 1, "time_ns": 10, "state": "LOAD",      "step_k": 0, "busy": 1, "done": 0, "mac_en": 0},
        {"cycle": 2, "time_ns": 20, "state": "COMPUTE",   "step_k": 0, "busy": 1, "done": 0, "mac_en": 1},
        {"cycle": 3, "time_ns": 30, "state": "COMPUTE",   "step_k": 1, "busy": 1, "done": 0, "mac_en": 1},
        {"cycle": 4, "time_ns": 40, "state": "COMPUTE",   "step_k": 2, "busy": 1, "done": 0, "mac_en": 1},
        {"cycle": 5, "time_ns": 50, "state": "COMPUTE",   "step_k": 3, "busy": 1, "done": 0, "mac_en": 1},
        {"cycle": 6, "time_ns": 60, "state": "ACTIVATE",  "step_k": 0, "busy": 1, "done": 0, "mac_en": 0},
        {"cycle": 7, "time_ns": 70, "state": "WRITEBACK", "step_k": 0, "busy": 1, "done": 0, "mac_en": 0},
        {"cycle": 8, "time_ns": 80, "state": "DONE",      "step_k": 0, "busy": 0, "done": 1, "mac_en": 0},
    ]

    report = {
        "clock_frequency_mhz": clock_freq_mhz,
        "clock_period_ns": period_ns,
        "benchmarks": benchmarks,
        "fsm_timing_trace": fsm_timing_trace
    }
    
    os.makedirs("waves", exist_ok=True)
    with open("waves/timing_report.json", "w") as f:
        json.dump(report, f, indent=2)
        
    print("[SUCCESS] Generated waves/timing_report.json")

if __name__ == "__main__":
    compute_metrics()
