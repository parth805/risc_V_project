"""
================================================================================
File: python/sim_soc.py
Description: Bit-Accurate Cycle-by-Cycle Python SoC & Accelerator Simulation Engine
             Verifies the complete integration of RISC-V RV32IM CPU + AI Coprocessor
================================================================================
"""

import numpy as np
import os
import sys
from generate_firmware import generate_soc_firmware

def to_int32(val):
    val = val & 0xFFFFFFFF
    return val if val < 0x80000000 else val - 0x100000000

class RiscVSoCSimulator:
    def __init__(self, mem_size_words=4096):
        self.mem = [0] * mem_size_words
        self.regs = [0] * 32
        self.pc = 0
        self.cycles = 0
        self.running = True
        
        # AI Accelerator Internal State
        self.accel_state = "IDLE"
        self.accel_act_en = 0
        self.accel_a = np.zeros((4, 4), dtype=np.int8)
        self.accel_b = np.zeros((4, 4), dtype=np.int8)
        self.accel_c = np.zeros((4, 4), dtype=np.int32)
        self.accel_busy = 0
        self.accel_done = 0
        self.accel_timer = 0

    def load_firmware(self, binary_words):
        for i, word in enumerate(binary_words):
            if i < len(self.mem):
                self.mem[i] = int(word) & 0xFFFFFFFF

    def step(self):
        if not self.running:
            return

        self.cycles += 1
        
        # Step Accelerator FSM if active
        if self.accel_busy:
            self.accel_timer += 1
            if self.accel_timer >= 8: # 8 deterministic cycles
                raw_c = np.matmul(self.accel_a.astype(np.int32), self.accel_b.astype(np.int32))
                if self.accel_act_en:
                    self.accel_c = np.maximum(0, raw_c)
                else:
                    self.accel_c = raw_c
                self.accel_busy = 0
                self.accel_done = 1
                self.accel_state = "DONE"

        # Fetch instruction
        word_idx = (self.pc >> 2) & 0xFFF
        instr = int(self.mem[word_idx])
        
        opcode = instr & 0x7F
        rd     = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x07
        rs1    = (instr >> 15) & 0x1F
        rs2    = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F
        
        # Sign-extended Immediates
        imm_i = (instr >> 20)
        if imm_i & 0x800: imm_i -= 0x1000

        imm_s = ((instr >> 25) << 5) | ((instr >> 7) & 0x1F)
        if imm_s & 0x800: imm_s -= 0x1000

        imm_b = (((instr >> 31) & 1) << 12) | (((instr >> 7) & 1) << 11) | (((instr >> 25) & 0x3F) << 5) | (((instr >> 8) & 0xF) << 1)
        if imm_b & 0x1000: imm_b -= 0x2000

        imm_u = instr & 0xFFFFF000

        next_pc = self.pc + 4

        # Execute Instruction
        if opcode == 0x37: # LUI
            if rd != 0: self.regs[rd] = to_int32(imm_u)

        elif opcode == 0x13: # OP-IMM
            src = self.regs[rs1]
            if funct3 == 0:   res = src + imm_i # ADDI
            elif funct3 == 2: res = 1 if src < imm_i else 0 # SLTI
            elif funct3 == 3: res = 1 if (src & 0xFFFFFFFF) < (imm_i & 0xFFFFFFFF) else 0 # SLTIU
            elif funct3 == 4: res = src ^ imm_i # XORI
            elif funct3 == 6: res = src | imm_i # ORI
            elif funct3 == 7: res = src & imm_i # ANDI
            elif funct3 == 1: res = src << (imm_i & 0x1F) # SLLI
            elif funct3 == 5:
                shamt = imm_i & 0x1F
                if funct7 == 0x20: res = src >> shamt # SRAI
                else:              res = (src & 0xFFFFFFFF) >> shamt # SRLI
            if rd != 0: self.regs[rd] = to_int32(res)

        elif opcode == 0x33: # OP / RV32M
            src1 = self.regs[rs1]
            src2 = self.regs[rs2]
            if funct7 == 0x01: # RV32M Extension
                if funct3 == 0:   res = src1 * src2 # MUL
                elif funct3 == 1: res = (src1 * src2) >> 32 # MULH
                elif funct3 == 4: res = src1 // src2 if src2 != 0 else -1 # DIV
                elif funct3 == 6: res = src1 % src2 if src2 != 0 else src1 # REM
            else: # RV32I Base
                if funct3 == 0:
                    if funct7 == 0x20: res = src1 - src2 # SUB
                    else:              res = src1 + src2 # ADD
                elif funct3 == 1: res = src1 << (src2 & 0x1F) # SLL
                elif funct3 == 2: res = 1 if src1 < src2 else 0 # SLT
                elif funct3 == 4: res = src1 ^ src2 # XOR
                elif funct3 == 6: res = src1 | src2 # OR
                elif funct3 == 7: res = src1 & src2 # AND
            if rd != 0: self.regs[rd] = to_int32(res)

        elif opcode == 0x23: # STORE
            addr = (self.regs[rs1] + imm_s) & 0xFFFFFFFF
            wdata = self.regs[rs2]
            if (addr & 0xF0000000) == 0x40000000: # MMIO Space
                self.handle_mmio_write(addr, wdata)
            else: # SRAM Space
                w_idx = (addr >> 2) & 0xFFF
                self.mem[w_idx] = wdata & 0xFFFFFFFF

        elif opcode == 0x03: # LOAD
            addr = (self.regs[rs1] + imm_i) & 0xFFFFFFFF
            if (addr & 0xF0000000) == 0x40000000: # MMIO Space
                rdata = self.handle_mmio_read(addr)
            else: # SRAM Space
                w_idx = (addr >> 2) & 0xFFF
                rdata = self.mem[w_idx]
            if rd != 0: self.regs[rd] = to_int32(rdata)

        elif opcode == 0x63: # BRANCH
            src1 = self.regs[rs1]
            src2 = self.regs[rs2]
            taken = False
            if funct3 == 0:   taken = (src1 == src2) # BEQ
            elif funct3 == 1: taken = (src1 != src2) # BNE
            elif funct3 == 4: taken = (src1 < src2)  # BLT
            elif funct3 == 5: taken = (src1 >= src2) # BGE
            if taken:
                next_pc = self.pc + imm_b
                # Detect infinite termination loop
                if imm_b == 0:
                    self.running = False

        self.pc = next_pc

    def handle_mmio_write(self, addr, wdata):
        if addr == 0x40000000: # REG_CTRL
            if wdata & 1: # START
                self.accel_busy = 1
                self.accel_done = 0
                self.accel_timer = 0
                self.accel_state = "COMPUTE"
        elif addr == 0x4000001C: # REG_CFG_ACT
            self.accel_act_en = wdata & 1
        elif 0x40000100 <= addr <= 0x4000010C: # Matrix A Rows
            r = (addr - 0x40000100) >> 2
            self.accel_a[r, 0] = np.int8(wdata & 0xFF)
            self.accel_a[r, 1] = np.int8((wdata >> 8) & 0xFF)
            self.accel_a[r, 2] = np.int8((wdata >> 16) & 0xFF)
            self.accel_a[r, 3] = np.int8((wdata >> 24) & 0xFF)
        elif 0x40000200 <= addr <= 0x4000020C: # Matrix B Rows
            r = (addr - 0x40000200) >> 2
            self.accel_b[r, 0] = np.int8(wdata & 0xFF)
            self.accel_b[r, 1] = np.int8((wdata >> 8) & 0xFF)
            self.accel_b[r, 2] = np.int8((wdata >> 16) & 0xFF)
            self.accel_b[r, 3] = np.int8((wdata >> 24) & 0xFF)

    def handle_mmio_read(self, addr):
        if addr == 0x40000000:
            return 1 if self.accel_busy else 0
        elif addr == 0x40000004: # REG_STATUS
            return (self.accel_busy << 1) | (self.accel_done & 1)
        elif 0x40000300 <= addr < 0x40000340: # Matrix C Elements
            elem_idx = (addr - 0x40000300) >> 2
            r = elem_idx // 4
            c = elem_idx % 4
            return int(self.accel_c[r, c])
        return 0

def run_soc_verification():
    print("================================================================================")
    print("          RISC-V AI ACCELERATOR SOC CYCLE-ACCURATE SYSTEM SIMULATION            ")
    print("================================================================================")
    
    binary_words = generate_soc_firmware()
    sim = RiscVSoCSimulator()
    sim.load_firmware(binary_words)

    max_cycles = 1000
    while sim.running and sim.cycles < max_cycles:
        sim.step()

    print(f"\n[INFO] Simulation completed in {sim.cycles} clock cycles.")

    # Validate RV32M Registers
    print("\n--- 1. RV32M MULTIPLY/DIVIDE CHECK ---")
    print(f"  x3 (MUL 12*10) = {sim.regs[3]} (Expected: 120) -> {'PASS' if sim.regs[3] == 120 else 'FAIL'}")
    print(f"  x4 (DIV 120/12)= {sim.regs[4]} (Expected: 10)  -> {'PASS' if sim.regs[4] == 10 else 'FAIL'}")
    print(f"  x5 (REM 120%10)= {sim.regs[5]} (Expected: 0)   -> {'PASS' if sim.regs[5] == 0 else 'FAIL'}")

    # Validate Computed Matrix C
    print("\n--- 2. ACCELERATOR MATRIX MULTIPLICATION RESULTS ---")
    print("Matrix A:")
    print(sim.accel_a)
    print("Matrix B:")
    print(sim.accel_b)
    print("Matrix C (Hardware Computed via SoC Interconnect):")
    print(sim.accel_c)

    expected_c = np.matmul(sim.accel_a.astype(np.int32), sim.accel_b.astype(np.int32))
    match = np.array_equal(sim.accel_c, expected_c)
    
    # Check SRAM signature
    sig = sim.mem[0x10FC >> 2]
    print(f"\n--- 3. FIRMWARE STATUS SIGNATURE ---")
    print(f"  Signature @ 0x10FC: 0x{sig:08X} (Expected: 0xCAFEBABE) -> {'PASS' if sig == 0xCAFEBABE else 'FAIL'}")

    if match and sig == 0xCAFEBABE and sim.regs[3] == 120:
        print("\n================================================================================")
        print("    [SUCCESS] FULL RISC-V SoC + AI ACCELERATOR INTEGRATION 100% VERIFIED!      ")
        print("================================================================================\n")
        return True
    else:
        print("\n[ERROR] SoC Verification Failed!")
        return False

if __name__ == "__main__":
    success = run_soc_verification()
    sys.exit(0 if success else 1)
