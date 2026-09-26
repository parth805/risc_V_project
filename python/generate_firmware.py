"""
================================================================================
File: python/generate_firmware.py
Description: Generates firmware.hex and firmware.sv test stimulus for the RISC-V AI SoC
================================================================================
"""

import os
from assembler import assemble_program

def generate_soc_firmware():
    # RISC-V SoC Assembly Verification Program
    soc_program = """
    # ==========================================================================
    # RISC-V AI ACCELERATOR SOC BOOT & TEST FIRMWARE
    # ==========================================================================
    
    # --------------------------------------------------------------------------
    # Step 1: Test RV32M Hardware Multiplier & Divider
    # --------------------------------------------------------------------------
    addi x1,  x0, 12
    addi x2,  x0, 10
    mul  x3,  x1, x2        # x3 = 12 * 10 = 120 (0x78)
    div  x4,  x3, x1        # x4 = 120 / 12 = 10
    rem  x5,  x3, x2        # x5 = 120 % 10 = 0

    # --------------------------------------------------------------------------
    # Step 2: Configure Accelerator MMIO Base Address (0x4000_0000)
    # --------------------------------------------------------------------------
    lui  x10, 0x40000       # x10 = 0x4000_0000 (Base CSR)

    # --------------------------------------------------------------------------
    # Step 3: Load Matrix A into MMIO Buffer Registers (0x4000_0100 - 0x4000_010C)
    # Matrix A:
    # Row 0: [1, 2, 3, 4] -> 0x04030201
    # Row 1: [5, 6, 7, 8] -> 0x08070605
    # Row 2: [1, 2, 1, 2] -> 0x02010201
    # Row 3: [3, 4, 3, 4] -> 0x04030403
    # --------------------------------------------------------------------------
    lui  x11, 0x04030
    addi x11, x11, 0x201    # x11 = 0x04030201
    sw   x11, 0x100(x10)    # Write Matrix A Row 0

    lui  x12, 0x08070
    addi x12, x12, 0x605    # x12 = 0x08070605
    sw   x12, 0x104(x10)    # Write Matrix A Row 1

    lui  x13, 0x02010
    addi x13, x13, 0x201    # x13 = 0x02010201
    sw   x13, 0x108(x10)    # Write Matrix A Row 2

    lui  x14, 0x04030
    addi x14, x14, 0x403    # x14 = 0x04030403
    sw   x14, 0x10C(x10)    # Write Matrix A Row 3

    # --------------------------------------------------------------------------
    # Step 4: Load Matrix B into MMIO Buffer Registers (0x4000_0200 - 0x4000_020C)
    # Matrix B:
    # Row 0: [1, 0, 2, 1] -> 0x01020001
    # Row 1: [0, 1, 1, 2] -> 0x02010100
    # Row 2: [2, 1, 0, 1] -> 0x01000102
    # Row 3: [1, 2, 1, 0] -> 0x00010201
    # --------------------------------------------------------------------------
    lui  x15, 0x01020
    addi x15, x15, 0x001    # x15 = 0x01020001
    sw   x15, 0x200(x10)    # Write Matrix B Row 0

    lui  x16, 0x02010
    addi x16, x16, 0x100    # x16 = 0x02010100
    sw   x16, 0x204(x10)    # Write Matrix B Row 1

    lui  x17, 0x01000
    addi x17, x17, 0x102    # x17 = 0x01000102
    sw   x17, 0x208(x10)    # Write Matrix B Row 2

    lui  x18, 0x00010
    addi x18, x18, 0x201    # x18 = 0x00010201
    sw   x18, 0x20C(x10)    # Write Matrix B Row 3

    # --------------------------------------------------------------------------
    # Step 5: Configure Activation & Trigger Start
    # --------------------------------------------------------------------------
    addi x19, x0, 0         # Linear / Bypass (ReLU = 0)
    sw   x19, 0x01C(x10)    # REG_CFG_ACT = 0

    addi x20, x0, 1         # Start Bit = 1
    sw   x20, 0x000(x10)    # REG_CTRL = 1 (Trigger Accelerator Computation)

    # --------------------------------------------------------------------------
    # Step 6: Poll Status Register until DONE == 1 (Bit 0)
    # --------------------------------------------------------------------------
poll_loop:
    lw   x21, 0x004(x10)    # Read REG_STATUS
    andi x22, x21, 1        # Extract DONE bit
    beq  x22, x0, poll_loop # Loop if DONE == 0

    # --------------------------------------------------------------------------
    # Step 7: Read Matrix C Results from 0x4000_0300 and Store to SRAM @ 0x1000
    # Expected Matrix C:
    # C[0][0] = 11, C[0][1] = 13, C[0][2] = 8,  C[0][3] = 8
    # C[1][0] = 27, C[1][1] = 29, C[1][2] = 24, C[1][3] = 24
    # C[2][0] = 5,  C[2][1] = 7,  C[2][2] = 6,  C[2][3] = 6
    # C[3][0] = 13, C[3][1] = 15, C[3][2] = 14, C[3][3] = 14
    # --------------------------------------------------------------------------
    lui  x23, 0x00001       # x23 = 0x0000_1000 (RAM Result Target)
    
    lw   x24, 0x300(x10)    # Read C[0][0] = 11
    sw   x24, 0x000(x23)    # Save to RAM
    
    lw   x25, 0x304(x10)    # Read C[0][1] = 13
    sw   x25, 0x004(x23)    # Save to RAM
    
    lw   x26, 0x308(x10)    # Read C[0][2] = 8
    sw   x26, 0x008(x23)    # Save to RAM
    
    lw   x27, 0x30C(x10)    # Read C[0][3] = 8
    sw   x27, 0x00C(x23)    # Save to RAM

    lw   x28, 0x310(x10)    # Read C[1][0] = 27
    sw   x28, 0x010(x23)
    
    lw   x29, 0x314(x10)    # Read C[1][1] = 29
    sw   x29, 0x014(x23)

    # --------------------------------------------------------------------------
    # Step 8: Assert Test Success Signature
    # --------------------------------------------------------------------------
    lui  x30, 0xCAFEC
    addi x30, x30, -1346    # 0xCAFEC000 - 1346 = 0xCAFEBABE
    sw   x30, 0x0FC(x23)    # Write signature to 0x0000_10FC

done_loop:
    beq  x0, x0, done_loop  # Infinite halt loop
    """

    binary_words = assemble_program(soc_program)
    
    os.makedirs("sim", exist_ok=True)
    with open("sim/firmware.hex", "w") as f:
        for w in binary_words:
            f.write(f"{w:08x}\n")

    print(f"[SUCCESS] Assembled {len(binary_words)} instructions -> sim/firmware.hex")
    return binary_words

if __name__ == "__main__":
    generate_soc_firmware()
