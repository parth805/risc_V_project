"""
================================================================================
File: python/assembler.py
Description: Mini RV32IM Assembler and Hex Generator for SoC Verification
================================================================================
"""

import sys

OPCODES = {
    "add":   ("R", 0x33, 0x0, 0x00),
    "sub":   ("R", 0x33, 0x0, 0x20),
    "sll":   ("R", 0x33, 0x1, 0x00),
    "slt":   ("R", 0x33, 0x2, 0x00),
    "sltu":  ("R", 0x33, 0x3, 0x00),
    "xor":   ("R", 0x33, 0x4, 0x00),
    "srl":   ("R", 0x33, 0x5, 0x00),
    "sra":   ("R", 0x33, 0x5, 0x20),
    "or":    ("R", 0x33, 0x6, 0x00),
    "and":   ("R", 0x33, 0x7, 0x00),
    # RV32M Extension
    "mul":   ("R", 0x33, 0x0, 0x01),
    "mulh":  ("R", 0x33, 0x1, 0x01),
    "mulhsu":("R", 0x33, 0x2, 0x01),
    "mulhu": ("R", 0x33, 0x3, 0x01),
    "div":   ("R", 0x33, 0x4, 0x01),
    "divu":  ("R", 0x33, 0x5, 0x01),
    "rem":   ("R", 0x33, 0x6, 0x01),
    "remu":  ("R", 0x33, 0x7, 0x01),

    # I-Type ALU
    "addi":  ("I", 0x13, 0x0),
    "slti":  ("I", 0x13, 0x2),
    "sltiu": ("I", 0x13, 0x3),
    "xori":  ("I", 0x13, 0x4),
    "ori":   ("I", 0x13, 0x6),
    "andi":  ("I", 0x13, 0x7),
    "slli":  ("I_SHIFT", 0x13, 0x1, 0x00),
    "srli":  ("I_SHIFT", 0x13, 0x5, 0x00),
    "srai":  ("I_SHIFT", 0x13, 0x5, 0x20),

    # Loads
    "lb":    ("I_LOAD", 0x03, 0x0),
    "lh":    ("I_LOAD", 0x03, 0x1),
    "lw":    ("I_LOAD", 0x03, 0x2),
    "lbu":   ("I_LOAD", 0x03, 0x4),
    "lhu":   ("I_LOAD", 0x03, 0x5),

    # Stores
    "sb":    ("S", 0x23, 0x0),
    "sh":    ("S", 0x23, 0x1),
    "sw":    ("S", 0x23, 0x2),

    # Branches
    "beq":   ("B", 0x63, 0x0),
    "bne":   ("B", 0x63, 0x1),
    "blt":   ("B", 0x63, 0x4),
    "bge":   ("B", 0x63, 0x5),
    "bltu":  ("B", 0x63, 0x6),
    "bgeu":  ("B", 0x63, 0x7),

    # U-Type & Jumps
    "lui":   ("U", 0x37),
    "auipc": ("U", 0x17),
    "jal":   ("J", 0x6F),
    "jalr":  ("I_JALR", 0x67, 0x0),
}

def parse_reg(reg_str):
    reg_str = reg_str.strip().lower().replace(",", "")
    if reg_str.startswith("x"):
        return int(reg_str[1:])
    reg_aliases = {
        "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7,
        "s0": 8, "fp": 8, "s1": 9, "a0": 10, "a1": 11, "a2": 12, "a3": 13,
        "a4": 14, "a5": 15, "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20,
        "s5": 21, "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
        "t3": 28, "t4": 29, "t5": 30, "t6": 31
    }
    return reg_aliases[reg_str]

def parse_imm(imm_str):
    imm_str = imm_str.strip().replace(",", "")
    if imm_str.startswith("0x") or imm_str.startswith("0X"):
        return int(imm_str, 16)
    return int(imm_str)

def parse_mem_operand(op_str):
    # e.g., "16(x10)" or "0(a0)" or "0x100(x10)"
    op_str = op_str.strip().replace(")", "")
    parts = op_str.split("(")
    imm = parse_imm(parts[0]) if parts[0] else 0
    reg = parse_reg(parts[1])
    return imm, reg

def assemble_instruction(line, pc=0, labels=None):
    labels = labels or {}
    line = line.split("//")[0].split("#")[0].strip()
    if not line:
        return None

    tokens = line.replace(",", " ").split()
    mnemonic = tokens[0].lower()

    if mnemonic == "nop":
        return 0x00000013  # addi x0, x0, 0

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    info = OPCODES[mnemonic]
    itype = info[0]

    if itype == "R":
        _, opcode, funct3, funct7 = info
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        rs2 = parse_reg(tokens[3])
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    elif itype == "I":
        _, opcode, funct3 = info
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        imm = parse_imm(tokens[3]) & 0xFFF
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    elif itype == "I_SHIFT":
        _, opcode, funct3, funct7 = info
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        shamt = parse_imm(tokens[3]) & 0x1F
        return (funct7 << 25) | (shamt << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    elif itype == "I_LOAD":
        _, opcode, funct3 = info
        rd = parse_reg(tokens[1])
        if len(tokens) == 3 and "(" in tokens[2]:
            imm, rs1 = parse_mem_operand(tokens[2])
        else:
            rs1 = parse_reg(tokens[2])
            imm = parse_imm(tokens[3])
        imm = imm & 0xFFF
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    elif itype == "S":
        _, opcode, funct3 = info
        rs2 = parse_reg(tokens[1])
        if len(tokens) == 3 and "(" in tokens[2]:
            imm, rs1 = parse_mem_operand(tokens[2])
        else:
            rs1 = parse_reg(tokens[2])
            imm = parse_imm(tokens[3])
        imm_11_5 = (imm >> 5) & 0x7F
        imm_4_0  = imm & 0x1F
        return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

    elif itype == "B":
        _, opcode, funct3 = info
        rs1 = parse_reg(tokens[1])
        rs2 = parse_reg(tokens[2])
        target = tokens[3]
        if target in labels:
            offset = labels[target] - pc
        else:
            offset = parse_imm(target)
        imm_12   = (offset >> 12) & 0x1
        imm_10_5 = (offset >> 5)  & 0x3F
        imm_4_1  = (offset >> 1)  & 0xF
        imm_11   = (offset >> 11) & 0x1
        return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

    elif itype == "U":
        _, opcode = info
        rd = parse_reg(tokens[1])
        imm = parse_imm(tokens[2]) & 0xFFFFF
        return (imm << 12) | (rd << 7) | opcode

    elif itype == "J":
        _, opcode = info
        rd = parse_reg(tokens[1])
        target = tokens[2]
        if target in labels:
            offset = labels[target] - pc
        else:
            offset = parse_imm(target)
        imm_20    = (offset >> 20) & 0x1
        imm_10_1  = (offset >> 1)  & 0x3FF
        imm_11    = (offset >> 11) & 0x1
        imm_19_12 = (offset >> 12) & 0xFF
        return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | (imm_19_12 << 12) | (rd << 7) | opcode

    return None

def assemble_program(source_text):
    lines = source_text.strip().split("\n")
    labels = {}
    cleaned_lines = []
    pc = 0

    # Pass 1: Label resolution
    for line in lines:
        cleaned = line.split("//")[0].split("#")[0].strip()
        if not cleaned:
            continue
        if cleaned.endswith(":"):
            label_name = cleaned[:-1].strip()
            labels[label_name] = pc
        else:
            if ":" in cleaned:
                label_part, inst_part = cleaned.split(":", 1)
                labels[label_part.strip()] = pc
                cleaned_lines.append((pc, inst_part.strip()))
                pc += 4
            else:
                cleaned_lines.append((pc, cleaned))
                pc += 4

    # Pass 2: Machine code generation
    binary_words = []
    for cur_pc, inst_str in cleaned_lines:
        word = assemble_instruction(inst_str, pc=cur_pc, labels=labels)
        binary_words.append(word)

    return binary_words

if __name__ == "__main__":
    test_asm = """
    lui  x10, 0x40000
    addi x1,  x0, 10
    addi x2,  x0, 20
    mul  x3,  x1, x2
    sw   x3,  0(x10)
    """
    words = assemble_program(test_asm)
    for i, w in enumerate(words):
        print(f"{i*4:04x}: {w:08x}")
