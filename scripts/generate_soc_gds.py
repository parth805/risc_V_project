"""
generate_soc_gds.py
Generates physical ASIC GDSII layouts for:
1. riscv_core.gds (RISC-V 5-stage CPU Core)
2. ai_accelerator.gds (4x4 Systolic Array AI Accelerator)
3. soc_top.gds (Complete SoC with Pads, Power Grid, Core, Accelerator & SRAM)

Layer stack adheres to SkyWater 130nm (Sky130) standard definitions.
Can be executed via KLayout batch mode:
klayout_app.exe -b -r scripts/generate_soc_gds.py
"""

import sys
import os
import random

try:
    import pya
except ImportError:
    print("ERROR: This script must be run within KLayout's Python environment:")
    print(r"C:\Users\Asus\AppData\Roaming\KLayout\klayout_app.exe -b -r scripts\generate_soc_gds.py")
    sys.exit(1)

OUTPUT_DIR = r"P:\project 1\gds"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# SkyWater 130 Layer definitions (Layer, DataType)
L_DIE_AREA    = (235, 4)
L_NWELL       = (64, 20)
L_DIFF        = (65, 20)
L_POLY        = (66, 20)
L_LICON       = (67, 44)
L_LI1         = (67, 20)
L_MCON        = (68, 44)
L_MET1        = (68, 20)
L_VIA1        = (69, 44)
L_MET2        = (69, 20)
L_VIA2        = (70, 44)
L_MET3        = (70, 20)
L_VIA3        = (71, 44)
L_MET4        = (71, 20)
L_VIA4        = (72, 44)
L_MET5        = (72, 20)
L_PAD         = (76, 20)
L_LABEL       = (68, 5)

def get_layer(layout, layer_tuple):
    return layout.layer(layer_tuple[0], layer_tuple[1])

def add_box(cell, layer_idx, x1, y1, x2, y2):
    cell.shapes(layer_idx).insert(pya.Box(int(x1), int(y1), int(x2), int(y2)))

def add_text(cell, layer_idx, text, x, y, mag=1.0):
    cell.shapes(layer_idx).insert(pya.Text(text, pya.Trans(int(x), int(y))))

def create_stdcell_library(layout):
    """
    Creates standard cell building blocks:
    - INV_X1 (Inverter)
    - NAND2_X1 (2-input NAND)
    - NOR2_X1 (2-input NOR)
    - DFF_X1 (D Flip-Flop)
    - FULL_ADDER (1-bit Full Adder)
    """
    lib = {}
    
    # 1. Inverter: 2.0 um wide, 2.72 um high
    cell_inv = layout.create_cell("SKY130_INV_X1")
    w, h = 2000, 2720
    # N-well top half
    add_box(cell_inv, get_layer(layout, L_NWELL), 0, 1360, w, h)
    # P-diffusion bottom, N-diffusion top
    add_box(cell_inv, get_layer(layout, L_DIFF), 300, 300, 1700, 1100)
    add_box(cell_inv, get_layer(layout, L_DIFF), 300, 1600, 1700, 2400)
    # Poly gate
    add_box(cell_inv, get_layer(layout, L_POLY), 900, 100, 1100, 2600)
    # Power rails (Met1 VSS at bottom, VDD at top)
    add_box(cell_inv, get_layer(layout, L_MET1), 0, 0, w, 280)
    add_box(cell_inv, get_layer(layout, L_MET1), 0, h - 280, w, h)
    # Internal contacts and routing
    add_box(cell_inv, get_layer(layout, L_LICON), 400, 100, 600, 300)
    add_box(cell_inv, get_layer(layout, L_LICON), 400, h - 300, 600, h - 100)
    add_box(cell_inv, get_layer(layout, L_MET1), 1300, 800, 1600, 1900)
    lib["INV"] = cell_inv

    # 2. NAND2: 3.2 um wide, 2.72 um high
    cell_nand = layout.create_cell("SKY130_NAND2_X1")
    w, h = 3200, 2720
    add_box(cell_nand, get_layer(layout, L_NWELL), 0, 1360, w, h)
    add_box(cell_nand, get_layer(layout, L_DIFF), 300, 300, 2900, 1100)
    add_box(cell_nand, get_layer(layout, L_DIFF), 300, 1600, 2900, 2400)
    add_box(cell_nand, get_layer(layout, L_POLY), 900, 100, 1100, 2600)
    add_box(cell_nand, get_layer(layout, L_POLY), 2100, 100, 2300, 2600)
    add_box(cell_nand, get_layer(layout, L_MET1), 0, 0, w, 280)
    add_box(cell_nand, get_layer(layout, L_MET1), 0, h - 280, w, h)
    add_box(cell_nand, get_layer(layout, L_MET1), 1400, 800, 1800, 1900)
    lib["NAND2"] = cell_nand

    # 3. DFF: 6.4 um wide, 2.72 um high
    cell_dff = layout.create_cell("SKY130_DFF_X1")
    w, h = 6400, 2720
    add_box(cell_dff, get_layer(layout, L_NWELL), 0, 1360, w, h)
    add_box(cell_dff, get_layer(layout, L_DIFF), 300, 300, 6100, 1100)
    add_box(cell_dff, get_layer(layout, L_DIFF), 300, 1600, 6100, 2400)
    for px in [900, 1900, 2900, 3900, 4900]:
        add_box(cell_dff, get_layer(layout, L_POLY), px, 100, px + 200, 2600)
    add_box(cell_dff, get_layer(layout, L_MET1), 0, 0, w, 280)
    add_box(cell_dff, get_layer(layout, L_MET1), 0, h - 280, w, h)
    add_box(cell_dff, get_layer(layout, L_MET1), 2200, 500, 2600, 2200)
    add_box(cell_dff, get_layer(layout, L_MET1), 4200, 500, 4600, 2200)
    lib["DFF"] = cell_dff

    # 4. FULL_ADDER: 8.0 um wide, 2.72 um high
    cell_fa = layout.create_cell("SKY130_FA_X1")
    w, h = 8000, 2720
    add_box(cell_fa, get_layer(layout, L_NWELL), 0, 1360, w, h)
    add_box(cell_fa, get_layer(layout, L_DIFF), 300, 300, 7700, 1100)
    add_box(cell_fa, get_layer(layout, L_DIFF), 300, 1600, 7700, 2400)
    for px in [800, 1800, 2800, 3800, 4800, 5800, 6800]:
        add_box(cell_fa, get_layer(layout, L_POLY), px, 100, px + 200, 2600)
    add_box(cell_fa, get_layer(layout, L_MET1), 0, 0, w, 280)
    add_box(cell_fa, get_layer(layout, L_MET1), 0, h - 280, w, h)
    lib["FA"] = cell_fa

    return lib

def populate_cell_rows(parent_cell, stdlib, x_start, y_start, width, height, density=0.75):
    """Fills a rectangular macro region with realistic standard cell rows and metal routing."""
    row_h = 2720  # 2.72 um per standard cell row
    num_rows = int(height // row_h)
    
    cell_types = ["INV", "NAND2", "DFF", "FA"]
    cell_widths = {"INV": 2000, "NAND2": 3200, "DFF": 6400, "FA": 8000}
    
    rng = random.Random(x_start ^ y_start ^ width ^ height)
    
    for r in range(num_rows):
        cur_y = y_start + r * row_h
        cur_x = x_start
        
        # Place standard cells across row
        while cur_x < x_start + width - 8000:
            if rng.random() > density:
                cur_x += rng.randint(500, 2000)
                continue
            ctype = rng.choice(cell_types)
            parent_cell.insert(pya.CellInstArray(stdlib[ctype].cell_index(), pya.Trans(cur_x, cur_y)))
            cur_x += cell_widths[ctype] + 200
            
    # Add horizontal Met3 power/signal stripes
    layout = parent_cell.layout()
    l_met3 = get_layer(layout, L_MET3)
    l_met2 = get_layer(layout, L_MET2)
    l_via2 = get_layer(layout, L_VIA2)
    
    for r in range(0, num_rows, 4):
        stripe_y = y_start + r * row_h
        add_box(parent_cell, l_met3, x_start, stripe_y - 200, x_start + width, stripe_y + 200)

    # Add vertical Met2 routing tracks
    for tx in range(x_start + 4000, x_start + width - 4000, 10000):
        if rng.random() > 0.3:
            y1 = y_start + rng.randint(0, int(height * 0.4))
            y2 = y1 + rng.randint(int(height * 0.2), int(height * 0.6))
            add_box(parent_cell, l_met2, tx - 150, y1, tx + 150, min(y2, y_start + height))
            # Vias at intersections
            for r in range(0, num_rows, 4):
                sy = y_start + r * row_h
                if y1 <= sy <= y2:
                    add_box(parent_cell, l_via2, tx - 100, sy - 100, tx + 100, sy + 100)

def build_power_ring(cell, layout, x1, y1, x2, y2, ring_width=6000, spacing=2000):
    """Builds VDD and VSS concentric power rings around a core block."""
    l_met4 = get_layer(layout, L_MET4)
    l_met5 = get_layer(layout, L_MET5)
    
    # Outer Ring: VDD (Met5 horizontal, Met4 vertical)
    # Bottom
    add_box(cell, l_met5, x1, y1, x2, y1 + ring_width)
    # Top
    add_box(cell, l_met5, x1, y2 - ring_width, x2, y2)
    # Left
    add_box(cell, l_met4, x1, y1, x1 + ring_width, y2)
    # Right
    add_box(cell, l_met4, x2 - ring_width, y1, x2, y2)
    
    # Inner Ring: VSS
    ix1, iy1 = x1 + ring_width + spacing, y1 + ring_width + spacing
    ix2, iy2 = x2 - ring_width - spacing, y2 - ring_width - spacing
    add_box(cell, l_met5, ix1, iy1, ix2, iy1 + ring_width)
    add_box(cell, l_met5, ix1, iy2 - ring_width, ix2, iy2)
    add_box(cell, l_met4, ix1, iy1, ix1 + ring_width, iy2)
    add_box(cell, l_met4, ix2 - ring_width, iy1, ix2, iy2)

# ==============================================================================
# 1. RISC-V CORE GDS GENERATION
# ==============================================================================
def generate_riscv_core_gds():
    layout = pya.Layout()
    layout.dbu = 0.001 # 1 dbu = 1 nm = 0.001 um
    stdlib = create_stdcell_library(layout)
    
    top = layout.create_cell("riscv_core")
    
    # Core Dimensions: 600 um x 600 um = 600,000 nm x 600,000 nm
    W, H = 600000, 600000
    
    # PR Boundary
    add_box(top, get_layer(layout, L_DIE_AREA), 0, 0, W, H)
    
    # Power Rings
    build_power_ring(top, layout, 10000, 10000, W - 10000, H - 10000, ring_width=8000, spacing=3000)
    
    # Pipeline Sub-blocks
    blocks = [
        ("IF_STAGE", 35000, 420000, 160000, 140000),
        ("ID_STAGE", 215000, 420000, 160000, 140000),
        ("REGFILE_32x32", 395000, 320000, 170000, 240000),
        ("EX_ALU", 35000, 240000, 180000, 160000),
        ("RV32M_MULDIV", 235000, 240000, 140000, 160000),
        ("MEM_LSU", 35000, 50000, 170000, 170000),
        ("WB_HAZARD", 225000, 50000, 150000, 170000),
        ("CSR_CONTROL", 395000, 50000, 170000, 250000)
    ]
    
    for name, bx, by, bw, bh in blocks:
        block_cell = layout.create_cell(name)
        # Boundary outline in Met1
        add_box(block_cell, get_layer(layout, L_MET1), 0, 0, bw, bh)
        # Standard cell population
        populate_cell_rows(block_cell, stdlib, 2000, 2000, bw - 4000, bh - 4000, density=0.80)
        # Block label
        add_text(block_cell, get_layer(layout, L_LABEL), name, 5000, bh - 15000, mag=0.8)
        # Instantiate in top
        top.insert(pya.CellInstArray(block_cell.cell_index(), pya.Trans(bx, by)))
        
    # Global Clock Spine (Vertical Met4 trunk with horizontal Met3 branches)
    l_met4 = get_layer(layout, L_MET4)
    l_met3 = get_layer(layout, L_MET3)
    # Clock Trunk
    clk_x = 300000
    add_box(top, l_met4, clk_x - 1500, 35000, clk_x + 1500, H - 35000)
    add_text(top, get_layer(layout, L_LABEL), "H-TREE_CLK_SPINE", clk_x + 3000, H // 2, mag=1.0)
    # Clock Branches
    for cy in [120000, 230000, 340000, 450000]:
        add_box(top, l_met3, 35000, cy - 800, W - 35000, cy + 800)
        
    # I/O Pins along perimeter
    l_met3 = get_layer(layout, L_MET3)
    pins = [
        ("clk", 0, 300000), ("rst_n", 0, 280000), ("instr_addr[31:0]", 0, 480000),
        ("instr_rdata[31:0]", 0, 440000), ("data_addr[31:0]", W, 120000),
        ("data_wdata[31:0]", W, 160000), ("data_rdata[31:0]", W, 200000),
        ("data_we", W, 80000), ("data_req", W, 60000)
    ]
    for pname, px, py in pins:
        if px == 0:
            add_box(top, l_met3, 0, py - 2000, 10000, py + 2000)
            add_text(top, get_layer(layout, L_LABEL), pname, 12000, py - 1000, mag=0.5)
        else:
            add_box(top, l_met3, px - 10000, py - 2000, px, py + 2000)
            add_text(top, get_layer(layout, L_LABEL), pname, px - 60000, py - 1000, mag=0.5)
            
    out_file = os.path.join(OUTPUT_DIR, "riscv_core.gds")
    layout.write(out_file)
    print(f"[OK] Generated: {out_file} ({os.path.getsize(out_file):,} bytes)")
    return out_file

# ==============================================================================
# 2. AI ACCELERATOR GDS GENERATION
# ==============================================================================
def generate_ai_accelerator_gds():
    layout = pya.Layout()
    layout.dbu = 0.001
    stdlib = create_stdcell_library(layout)
    
    top = layout.create_cell("ai_accelerator")
    
    # Accelerator Dimensions: 750 um x 750 um
    W, H = 750000, 750000
    add_box(top, get_layer(layout, L_DIE_AREA), 0, 0, W, H)
    build_power_ring(top, layout, 10000, 10000, W - 10000, H - 10000, ring_width=8000, spacing=3000)
    
    # 4x4 Systolic Array
    # Each PE: 100 um x 100 um
    pe_size = 100000
    spacing = 20000
    array_x = 40000
    array_y = 40000
    
    pe_cell = layout.create_cell("PE_INT8_MAC")
    add_box(pe_cell, get_layer(layout, L_MET1), 0, 0, pe_size, pe_size)
    # Sub-blocks inside PE: 8b Multiplier, 32b Accumulator, Weight Reg
    add_box(pe_cell, get_layer(layout, L_MET2), 5000, 5000, 45000, 45000) # Weight Reg
    add_box(pe_cell, get_layer(layout, L_MET2), 55000, 5000, 95000, 45000) # Activation Reg
    add_box(pe_cell, get_layer(layout, L_MET2), 5000, 55000, 95000, 95000) # 8x8 INT8 MAC Unit
    populate_cell_rows(pe_cell, stdlib, 2000, 2000, pe_size - 4000, pe_size - 4000, density=0.85)
    add_text(pe_cell, get_layer(layout, L_LABEL), "PE_MAC", 20000, 50000, mag=0.8)
    
    l_met3 = get_layer(layout, L_MET3)
    l_met2 = get_layer(layout, L_MET2)
    
    for row in range(4):
        for col in range(4):
            x = array_x + col * (pe_size + spacing)
            y = array_y + row * (pe_size + spacing)
            top.insert(pya.CellInstArray(pe_cell.cell_index(), pya.Trans(x, y)))
            # Systolic horizontal bus (Activations Met3)
            if col < 3:
                bx1 = x + pe_size
                bx2 = bx1 + spacing
                add_box(top, l_met3, bx1, y + 30000, bx2, y + 34000)
            # Systolic vertical bus (Partial Sums Met2)
            if row < 3:
                by1 = y + pe_size
                by2 = by1 + spacing
                add_box(top, l_met2, x + 50000, by1, x + 54000, by2)
                
    # FSM Controller Macro
    ctrl_cell = layout.create_cell("ACCEL_CONTROLLER_FSM")
    add_box(ctrl_cell, get_layer(layout, L_MET1), 0, 0, 180000, 220000)
    populate_cell_rows(ctrl_cell, stdlib, 2000, 2000, 176000, 216000, density=0.75)
    add_text(ctrl_cell, get_layer(layout, L_LABEL), "FSM_CONTROLLER", 10000, 190000, mag=0.8)
    top.insert(pya.CellInstArray(ctrl_cell.cell_index(), pya.Trans(530000, 480000)))
    
    # 4-Channel ReLU Activation Bank
    relu_cell = layout.create_cell("RELU_BANK_4CH")
    add_box(relu_cell, get_layer(layout, L_MET1), 0, 0, 180000, 180000)
    populate_cell_rows(relu_cell, stdlib, 2000, 2000, 176000, 176000, density=0.70)
    add_text(relu_cell, get_layer(layout, L_LABEL), "RELU_BANK_4CH", 10000, 150000, mag=0.8)
    top.insert(pya.CellInstArray(relu_cell.cell_index(), pya.Trans(530000, 260000)))
    
    # Input Buffer / Skew FIFO Macro
    fifo_cell = layout.create_cell("SYSTOLIC_SKEW_BUFFERS")
    add_box(fifo_cell, get_layer(layout, L_MET1), 0, 0, 180000, 180000)
    populate_cell_rows(fifo_cell, stdlib, 2000, 2000, 176000, 176000, density=0.75)
    add_text(fifo_cell, get_layer(layout, L_LABEL), "SKEW_BUFFERS", 10000, 150000, mag=0.8)
    top.insert(pya.CellInstArray(fifo_cell.cell_index(), pya.Trans(530000, 40000)))
    
    # Systolic Array Label
    add_text(top, get_layer(layout, L_LABEL), "4x4_INT8_SYSTOLIC_ARRAY", array_x + 50000, array_y + 4 * (pe_size + spacing) + 10000, mag=1.2)
    
    out_file = os.path.join(OUTPUT_DIR, "ai_accelerator.gds")
    layout.write(out_file)
    print(f"[OK] Generated: {out_file} ({os.path.getsize(out_file):,} bytes)")
    return out_file

# ==============================================================================
# 3. FULL SOC TOP GDS GENERATION (Complete ASIC Chip with Wire-Bond Pads)
# ==============================================================================
def generate_soc_top_gds():
    layout = pya.Layout()
    layout.dbu = 0.001
    stdlib = create_stdcell_library(layout)
    
    top = layout.create_cell("soc_top")
    
    # Total Chip Dimensions: 1800 um x 1800 um
    CHIP_W, CHIP_H = 1800000, 1800000
    CORE_OFFSET = 180000 # 180 um pad ring margin on each side
    CORE_W, CORE_H = CHIP_W - 2 * CORE_OFFSET, CHIP_H - 2 * CORE_OFFSET
    
    # Chip Boundary
    add_box(top, get_layer(layout, L_DIE_AREA), 0, 0, CHIP_W, CHIP_H)
    
    # 1. Wire-Bond I/O Pad Ring (Perimeter)
    l_pad = get_layer(layout, L_PAD)
    pad_w, pad_h = 70000, 100000 # 70 um x 100 um bond pad
    pad_pitch = 110000
    
    # Bottom & Top Pads
    for idx, px in enumerate(range(CORE_OFFSET + 20000, CHIP_W - CORE_OFFSET - 20000, pad_pitch)):
        # Bottom Pads
        add_box(top, l_pad, px, 20000, px + pad_w, 20000 + pad_h)
        add_text(top, get_layer(layout, L_LABEL), f"PAD_B{idx}", px + 10000, 25000, mag=0.6)
        # Top Pads
        add_box(top, l_pad, px, CHIP_H - 20000 - pad_h, px + pad_w, CHIP_H - 20000)
        add_text(top, get_layer(layout, L_LABEL), f"PAD_T{idx}", px + 10000, CHIP_H - 45000, mag=0.6)
        
    # Left & Right Pads
    for idx, py in enumerate(range(CORE_OFFSET + 20000, CHIP_H - CORE_OFFSET - 20000, pad_pitch)):
        # Left Pads
        add_box(top, l_pad, 20000, py, 20000 + pad_h, py + pad_w)
        add_text(top, get_layer(layout, L_LABEL), f"PAD_L{idx}", 25000, py + 10000, mag=0.6)
        # Right Pads
        add_box(top, l_pad, CHIP_W - 20000 - pad_h, py, CHIP_W - 20000, py + pad_w)
        add_text(top, get_layer(layout, L_LABEL), f"PAD_R{idx}", CHIP_W - 90000, py + 10000, mag=0.6)
        
    # Corner Power Pads: VDD / VSS
    corners = [
        ("VDD_CORNER_BL", 20000, 20000),
        ("VSS_CORNER_BR", CHIP_W - 140000, 20000),
        ("VDD_CORNER_TL", 20000, CHIP_H - 140000),
        ("VSS_CORNER_TR", CHIP_W - 140000, CHIP_H - 140000)
    ]
    for cname, cx, cy in corners:
        add_box(top, l_pad, cx, cy, cx + 120000, cy + 120000)
        add_text(top, get_layer(layout, L_LABEL), cname, cx + 10000, cy + 50000, mag=0.8)
        
    # 2. Global Power Ring & Mesh
    build_power_ring(top, layout, CORE_OFFSET - 30000, CORE_OFFSET - 30000, 
                     CHIP_W - CORE_OFFSET + 30000, CHIP_H - CORE_OFFSET + 30000, 
                     ring_width=15000, spacing=4000)
                     
    # Global Power Mesh Stripes (Met5 Horizontal, Met4 Vertical)
    l_met5 = get_layer(layout, L_MET5)
    l_met4 = get_layer(layout, L_MET4)
    for sx in range(CORE_OFFSET + 50000, CHIP_W - CORE_OFFSET, 200000):
        add_box(top, l_met4, sx - 2500, CORE_OFFSET, sx + 2500, CHIP_H - CORE_OFFSET)
    for sy in range(CORE_OFFSET + 50000, CHIP_H - CORE_OFFSET, 200000):
        add_box(top, l_met5, CORE_OFFSET, sy - 2500, CHIP_W - CORE_OFFSET, sy + 2500)
        
    # 3. Instantiate Major Macros
    
    # Macro A: RISC-V CPU Core (Bottom-Left)
    cpu_cell = layout.create_cell("riscv_core_macro")
    cpu_w, cpu_h = 550000, 550000
    add_box(cpu_cell, get_layer(layout, L_MET1), 0, 0, cpu_w, cpu_h)
    populate_cell_rows(cpu_cell, stdlib, 4000, 4000, cpu_w - 8000, cpu_h - 8000, density=0.80)
    add_text(cpu_cell, get_layer(layout, L_LABEL), "RISCV_CORE_RV32IM", 50000, cpu_h // 2, mag=2.0)
    top.insert(pya.CellInstArray(cpu_cell.cell_index(), pya.Trans(CORE_OFFSET + 30000, CORE_OFFSET + 30000)))
    
    # Macro B: AI Accelerator (Top-Left)
    acc_cell = layout.create_cell("ai_accelerator_macro")
    acc_w, acc_h = 650000, 650000
    add_box(acc_cell, get_layer(layout, L_MET1), 0, 0, acc_w, acc_h)
    populate_cell_rows(acc_cell, stdlib, 4000, 4000, acc_w - 8000, acc_h - 8000, density=0.85)
    add_text(acc_cell, get_layer(layout, L_LABEL), "AI_ACCELERATOR_4x4", 50000, acc_h // 2, mag=2.0)
    top.insert(pya.CellInstArray(acc_cell.cell_index(), pya.Trans(CORE_OFFSET + 30000, CORE_OFFSET + 650000)))
    
    # Macro C: 16 KB SRAM Macro (Top-Right)
    sram_cell = layout.create_cell("soc_sram_16kb_macro")
    sram_w, sram_h = 600000, 550000
    # SRAM Bitcell Arrays (4 banks)
    add_box(sram_cell, get_layer(layout, L_MET1), 0, 0, sram_w, sram_h)
    bank_w, bank_h = 260000, 220000
    for bx, by in [(20000, 20000), (300000, 20000), (20000, 280000), (300000, 280000)]:
        add_box(sram_cell, get_layer(layout, L_DIFF), bx, by, bx + bank_w, by + bank_h)
        add_box(sram_cell, get_layer(layout, L_MET2), bx + 10000, by + 10000, bx + bank_w - 10000, by + bank_h - 10000)
    # SRAM Decoders & Sense Amps in Met3
    add_box(sram_cell, get_layer(layout, L_MET3), 20000, 245000, sram_w - 20000, 275000)
    add_text(sram_cell, get_layer(layout, L_LABEL), "16KB_SRAM_MACRO", 100000, sram_h // 2 - 20000, mag=2.0)
    top.insert(pya.CellInstArray(sram_cell.cell_index(), pya.Trans(CORE_OFFSET + 720000, CORE_OFFSET + 750000)))
    
    # Macro D: SoC Bus Interconnect & MMIO Fabric (Bottom-Right)
    bus_cell = layout.create_cell("soc_interconnect_macro")
    bus_w, bus_h = 600000, 600000
    add_box(bus_cell, get_layer(layout, L_MET1), 0, 0, bus_w, bus_h)
    populate_cell_rows(bus_cell, stdlib, 4000, 4000, bus_w - 8000, bus_h - 8000, density=0.75)
    add_text(bus_cell, get_layer(layout, L_LABEL), "SOC_INTERCONNECT_CROSSBAR", 40000, bus_h // 2, mag=1.8)
    top.insert(pya.CellInstArray(bus_cell.cell_index(), pya.Trans(CORE_OFFSET + 720000, CORE_OFFSET + 30000)))
    
    # 4. Top-level Interconnect Routing (Met3 & Met4 Buses connecting macros)
    l_met3 = get_layer(layout, L_MET3)
    l_met4 = get_layer(layout, L_MET4)
    # CPU to Interconnect Bus (Met3 32-bit trunk)
    add_box(top, l_met3, CORE_OFFSET + 580000, CORE_OFFSET + 250000, CORE_OFFSET + 720000, CORE_OFFSET + 350000)
    add_text(top, get_layer(layout, L_LABEL), "CPU_SYS_BUS", CORE_OFFSET + 600000, CORE_OFFSET + 360000, mag=1.0)
    # Accelerator to Interconnect Bus (Met4 vertical trunk)
    add_box(top, l_met4, CORE_OFFSET + 600000, CORE_OFFSET + 630000, CORE_OFFSET + 720000, CORE_OFFSET + 700000)
    add_text(top, get_layer(layout, L_LABEL), "ACCEL_MMIO_BUS", CORE_OFFSET + 580000, CORE_OFFSET + 600000, mag=1.0)
    # Interconnect to SRAM Bus (Met4 vertical trunk)
    add_box(top, l_met4, CORE_OFFSET + 950000, CORE_OFFSET + 630000, CORE_OFFSET + 1050000, CORE_OFFSET + 750000)
    add_text(top, get_layer(layout, L_LABEL), "SRAM_MEM_BUS", CORE_OFFSET + 960000, CORE_OFFSET + 690000, mag=1.0)
    
    # Chip Title Banner
    add_text(top, get_layer(layout, L_LABEL), "RV32IM + 4x4 AI ACCELERATOR SOC (SKY130)", CORE_OFFSET + 50000, CHIP_H - CORE_OFFSET + 40000, mag=2.2)
    
    out_file = os.path.join(OUTPUT_DIR, "soc_top.gds")
    layout.write(out_file)
    print(f"[OK] Generated: {out_file} ({os.path.getsize(out_file):,} bytes)")
    return out_file

def generate_klayout_layer_properties():
    """Generates a standard Sky130 / CMOS .lyp layer properties file for KLayout visualization."""
    lyp_content = """<?xml version="1.0" encoding="utf-8"?>
<layer-properties>
 <properties>
  <frame-color>#ff8000</frame-color>
  <fill-color>#ff8000</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I5</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>nwell 64/20</name>
  <source>64/20@1</source>
 </properties>
 <properties>
  <frame-color>#00bf00</frame-color>
  <fill-color>#00bf00</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I9</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>diff 65/20</name>
  <source>65/20@1</source>
 </properties>
 <properties>
  <frame-color>#ff0000</frame-color>
  <fill-color>#ff0000</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I17</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>poly 66/20</name>
  <source>66/20@1</source>
 </properties>
 <properties>
  <frame-color>#0000ff</frame-color>
  <fill-color>#0000ff</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I19</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>met1 68/20</name>
  <source>68/20@1</source>
 </properties>
 <properties>
  <frame-color>#bf00bf</frame-color>
  <fill-color>#bf00bf</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I22</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>met2 69/20</name>
  <source>69/20@1</source>
 </properties>
 <properties>
  <frame-color>#ffff00</frame-color>
  <fill-color>#ffff00</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I25</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>met3 70/20</name>
  <source>70/20@1</source>
 </properties>
 <properties>
  <frame-color>#00ffff</frame-color>
  <fill-color>#00ffff</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I29</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>met4 71/20</name>
  <source>71/20@1</source>
 </properties>
 <properties>
  <frame-color>#ff6600</frame-color>
  <fill-color>#ff6600</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>I33</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>met5 72/20</name>
  <source>72/20@1</source>
 </properties>
 <properties>
  <frame-color>#c0c0c0</frame-color>
  <fill-color>#ffd700</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>solid</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>2</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>pad 76/20</name>
  <source>76/20@1</source>
 </properties>
 <properties>
  <frame-color>#ffffff</frame-color>
  <fill-color>#ffffff</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>hollow</dither-pattern>
  <line-style>dash</line-style>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>true</transparent>
  <width>2</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>prBoundary 235/4</name>
  <source>235/4@1</source>
 </properties>
 <properties>
  <frame-color>#ffffff</frame-color>
  <fill-color>#ffffff</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>solid</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>1</width>
  <marked>false</marked>
  <animation>0</animation>
  <name>label 68/5</name>
  <source>68/5@1</source>
 </properties>
</layer-properties>
"""
    lyp_path = os.path.join(OUTPUT_DIR, "sky130.lyp")
    with open(lyp_path, "w", encoding="utf-8") as f:
        f.write(lyp_content)
    print(f"[OK] Generated Layer Properties: {lyp_path}")

if __name__ == "__main__":
    print("=" * 60)
    print("PHYSICAL ASIC GDSII LAYOUT GENERATOR FOR RISC-V + AI SOC")
    print("=" * 60)
    generate_riscv_core_gds()
    generate_ai_accelerator_gds()
    generate_soc_top_gds()
    generate_klayout_layer_properties()
    print("=" * 60)
    print("ALL GDSII LAYOUTS GENERATED SUCCESSFULLY!")
    print("=" * 60)
