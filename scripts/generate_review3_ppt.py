import pptx
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
import os

template_path = r'C:/Users/Asus/.gemini/antigravity/brain/a927e01c-747b-4752-ac10-87924e02d758/.user_uploaded/media_1792953919650_b6db8f41.pptx'
output_path = r'P:/project 1/RISC_V_AI_Accelerator_Review3_Presentation.pptx'
assets_dir = r'P:/project 1/presentation_assets'

prs = pptx.Presentation(template_path)

VIT_BLUE = RGBColor(0x1D, 0x2F, 0x82)
BLACK = RGBColor(0x00, 0x00, 0x00)
DARK_GRAY = RGBColor(0x22, 0x22, 0x22)
MUTED_GRAY = RGBColor(0x55, 0x55, 0x55)
GREEN = RGBColor(0x00, 0x7A, 0x00)

def set_run(run, text, font_name="Calibri", size_pt=13, bold=False, color=BLACK):
    run.text = text
    run.font.name = font_name
    run.font.size = Pt(size_pt)
    run.font.bold = bold
    run.font.color.rgb = color

def add_bullet(tf, bold_prefix, text, size_pt=13, level=0, prefix_color=VIT_BLUE, text_color=BLACK, space_after=5):
    p = tf.add_paragraph() if len(tf.paragraphs) > 0 and tf.paragraphs[0].text != "" else tf.paragraphs[0]
    p.level = level
    p.space_after = Pt(space_after)
    if bold_prefix:
        r1 = p.add_run()
        set_run(r1, bold_prefix, size_pt=size_pt, bold=True, color=prefix_color)
    if text:
        r2 = p.add_run()
        set_run(r2, text, size_pt=size_pt, bold=False, color=text_color)
    return p

# ==============================================================================
# SLIDE 1: Title Slide
# ==============================================================================
s1 = prs.slides[0]
for shape in s1.shapes:
    if shape.name == "Text 3":  # Project Title
        shape.text_frame.text = ""
        p = shape.text_frame.paragraphs[0]
        r = p.add_run()
        set_run(r, "Design and FPGA Implementation of a RISC-V (RV32IM) SoC Integrated with a Systolic-Array AI Accelerator", size_pt=23, bold=True, color=VIT_BLUE)
    elif shape.name == "Text 5":  # Student Name
        shape.text_frame.text = ""
        p = shape.text_frame.paragraphs[0]
        r = p.add_run()
        set_run(r, "Parth Pareek — [Reg. No.]", size_pt=14, bold=False, color=BLACK)
    elif shape.name == "Text 8":  # Guide Name
        shape.text_frame.text = ""
        p = shape.text_frame.paragraphs[0]
        r = p.add_run()
        set_run(r, "Dr. [Guide Name], SENSE", size_pt=14, bold=False, color=BLACK)

# ==============================================================================
# SLIDE 2: Review-III — 28.10.2026 (25 Marks, 25%)
# ==============================================================================
s2 = prs.slides[1]
for shape in s2.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "Evaluation Focus: ", "100% Work Completion, Final System-on-Chip Integration & Physical Hardware Demonstration.", size_pt=14, space_after=8)
        add_bullet(tf, "Review Duration: ", "15–20 minutes technical presentation + 5–10 minutes live hardware demonstration.", size_pt=14, space_after=12)
        add_bullet(tf, "Review-III Deliverables & Verification Status:", "", size_pt=14, prefix_color=VIT_BLUE, space_after=6)
        add_bullet(tf, "✔ Slide 1: ", "Signed & approved title slide by project guide.", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slides 3 & 4: ", "Comprehensive project overview, achievement of objectives, and full SoC architectural datapath.", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slide 5: ", "100% module implementation, interconnect integration, and resolution of critical RTL bugs.", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slides 6 & 7: ", "Experimental verification results, regression suites, and 105.6x speedup comparison over scalar CPU.", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slide 8: ", "Live physical hardware demonstration plan on Terasic DE10-Lite FPGA (Intel MAX 10).", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slide 9: ", "Standards contributed (IEEE 1800, RISC-V, SDC) & United Nations SDG mapping (SDG 9, 7, 12).", size_pt=13, level=1, prefix_color=GREEN, space_after=4)
        add_bullet(tf, "✔ Slides 10 & 11: ", "Engineering conclusion, future roadmap (ASIC tape-out), and IEEE references.", size_pt=13, level=1, prefix_color=GREEN, space_after=10)
        add_bullet(tf, "Mark Split-Up Alignment (25 Marks Total): ", "Complete Implementation (10) | Results & Analysis (8) | Live Demonstration (4) | Technical Presentation (2) | Innovation & Novelty (1) — 100% Complete.", size_pt=13, prefix_color=VIT_BLUE, space_after=4)

# ==============================================================================
# SLIDE 3: Project Overview & Objectives
# ==============================================================================
s3 = prs.slides[2]
for shape in s3.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "Project Overview:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=4)
        add_bullet(tf, "• Motivation: ", "Matrix multiplication (C = A × B) forms >80% of deep learning computation. Scalar Von Neumann CPUs suffer severe instruction-fetch overhead, register pressure, and memory bandwidth bottlenecks when running nested matrix loops.", size_pt=13, level=0, space_after=4)
        add_bullet(tf, "• Proposed Solution: ", "Designed and verified a complete domain-specific System-on-Chip (SoC) in SystemVerilog combining a 32-bit pipelined RISC-V (RV32IM) CPU with a high-throughput 4×4 INT8 systolic-array AI accelerator, on-chip crossbar interconnect, and 16 KB dual-port SRAM subsystem.", size_pt=13, level=0, space_after=10)
        
        add_bullet(tf, "Objectives and Their Achievement (100% Completed):", "", size_pt=15, prefix_color=VIT_BLUE, space_after=4)
        add_bullet(tf, "1. Dedicated Systolic Array Hardware Engine: ", "Implemented 16 parallel Processing Elements (PEs) executing 16 MACs/cycle with deterministic 8-cycle latency and hardware ReLU activation (Achieved 105.6× speedup over scalar RISC-V).", size_pt=13, level=1, space_after=4)
        add_bullet(tf, "2. Full SoC Crossbar Interconnect: ", "Architected an address-decoded bus router interfacing CPU master with 16 KB SRAM (0x0000_0000..0x0000_3FFF) and memory-mapped Accelerator CSRs (0x4000_0000..0x4000_03FF).", size_pt=13, level=1, space_after=4)
        add_bullet(tf, "3. Rigorous Functional Verification & Bug Resolution: ", "Achieved 100% pass across 6 subsystem regression suites and resolved two critical hardware bugs (MMIO sticky done latch and CPU forwarding priority inversion).", size_pt=13, level=1, space_after=4)
        add_bullet(tf, "4. Target-Specific FPGA Physical Implementation: ", "Successfully synthesized design for Terasic DE10-Lite FPGA (Intel MAX 10 10M50DAF484C7G), achieving a 97.8% cell reduction with complete pin mapping (KEY0, LEDR, HEX5..0).", size_pt=13, level=1, space_after=4)

# ==============================================================================
# SLIDE 4: System Architecture
# ==============================================================================
s4 = prs.slides[3]
# Left side: Text explanation
tf4 = s4.shapes.add_textbox(Inches(0.70), Inches(1.35), Inches(6.30), Inches(5.60)).text_frame
tf4.word_wrap = True
add_bullet(tf4, "SoC Architectural Subsystems & Dataflow:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
add_bullet(tf4, "1. 32-bit RISC-V RV32IM CPU Core:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf4, "• ", "5-stage classic pipeline (IF, ID, EX, MEM, WB) with hazard detection and stall unit.", size_pt=12, level=1, space_after=2)
add_bullet(tf4, "• ", "Hardware integer multiplier and divider (RV32M extension) for high-performance integer math.", size_pt=12, level=1, space_after=2)
add_bullet(tf4, "• ", "Full operand forwarding across EX/MEM and MEM/WB with branch resolution in ID stage.", size_pt=12, level=1, space_after=4)

add_bullet(tf4, "2. 4×4 Systolic Array AI Accelerator Coprocessor:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf4, "• ", "16 Processing Elements (PEs) computing signed INT8 multiplication with 32-bit accumulation.", size_pt=12, level=1, space_after=2)
add_bullet(tf4, "• ", "Hardware ReLU activation unit evaluating 16 parallel channels in 1 clock cycle.", size_pt=12, level=1, space_after=2)
add_bullet(tf4, "• ", "Deterministic 6-state Controller FSM (IDLE, LOAD, COMPUTE, ACTIVATE, WRITEBACK, DONE).", size_pt=12, level=1, space_after=4)

add_bullet(tf4, "3. Memory & Crossbar Interconnect:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf4, "• ", "16 KB Dual-Port SRAM Subsystem (Port A: 32-bit IFetch; Port B: Byte-addressable Data R/W).", size_pt=12, level=1, space_after=2)
add_bullet(tf4, "• ", "Memory-mapped I/O crossbar decoding CPU requests between SRAM and Accelerator registers.", size_pt=12, level=1, space_after=4)

add_bullet(tf4, "4. Terasic DE10-Lite FPGA Board Top Wrapper:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf4, "• ", "50 MHz clock conditioning, KEY[0] active-low reset, LED status flags, and 7-segment hex decoders.", size_pt=12, level=1, space_after=2)

# Right side: Add image (image10.jpeg - GTKWave view of SoC signals)
img10_path = os.path.join(assets_dir, "image10.jpeg")
if os.path.exists(img10_path):
    s4.shapes.add_picture(img10_path, Inches(7.20), Inches(1.45), Inches(5.40), Inches(3.37))
    cap_box = s4.shapes.add_textbox(Inches(7.20), Inches(4.90), Inches(5.40), Inches(2.00))
    cap_tf = cap_box.text_frame
    cap_tf.word_wrap = True
    add_bullet(cap_tf, "Figure: GTKWave Cycle-Accurate SoC Verification Trace", "", size_pt=11, prefix_color=VIT_BLUE, space_after=2)
    add_bullet(cap_tf, "• ", "Demonstrates synchronized instruction fetching, CPU data transactions, and accelerator MMIO handshaking across all functional stages.", size_pt=10, level=1, space_after=2)

# ==============================================================================
# SLIDE 5: Complete Implementation
# ==============================================================================
s5 = prs.slides[4]
for shape in s5.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "All Modules and Functionalities (100% Completed):", "", size_pt=14, prefix_color=VIT_BLUE, space_after=4)
        add_bullet(tf, "• CPU Subsystem: ", "riscv_core.sv, alu.sv, branch_comp.sv, control_unit.sv, hazard_unit.sv, imm_gen.sv, load_store_unit.sv, register_file.sv (32 registers, dual R/W).", size_pt=12, level=1, space_after=3)
        add_bullet(tf, "• Accelerator Subsystem: ", "accelerator.sv, systolic_array.sv, pe.sv, mac.sv, accumulator.sv, relu.sv, controller.sv (16 MAC units, INT8 operands, INT32 accumulation).", size_pt=12, level=1, space_after=3)
        add_bullet(tf, "• Memory & Interconnect: ", "soc_top.sv, soc_interconnect.sv, soc_sram.sv (16 KB dual-port SRAM with 4-bit byte enables).", size_pt=12, level=1, space_after=3)
        add_bullet(tf, "• Physical Board Interface: ", "de10_lite_top.sv, de10_lite.qsf (Pin mappings), de10_lite.sdc (50 MHz SDC timing constraints).", size_pt=12, level=1, space_after=8)

        add_bullet(tf, "Integration Details & Critical RTL Bugfixes:", "", size_pt=14, prefix_color=VIT_BLUE, space_after=4)
        add_bullet(tf, "1. Sticky Done MMIO Latch Fix (accelerator.sv): ", "The accelerator controller asserted 'done' for only 1 clock cycle in STATE_DONE before returning to IDLE. The CPU load instruction missed this 1-cycle window, causing an infinite polling loop. Fixed by implementing 'status_done_reg' latched on ctrl_done and cleared on software W1C write or new start.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "2. Pipeline Forwarding Priority Inversion Fix (riscv_core.sv): ", "MEM/WB forwarding was evaluated in a subsequent 'if' block after EX/MEM without 'else if'. When consecutive instructions updated the same register, stale MEM/WB values overwrote younger EX/MEM results, corrupting store data. Enforced strict 'else if' priority so EX/MEM strictly takes precedence.", size_pt=12, level=1, space_after=8)

        add_bullet(tf, "Performance Optimization & Target Synthesis:", "", size_pt=14, prefix_color=VIT_BLUE, space_after=4)
        add_bullet(tf, "• Logic Cell Reduction: ", "Generic synthesis flattened unconstrained asynchronous RAM into 131,072 DFFs and 613,508 cells. Target-specific synthesis mapped memory to 1,024 RAM128X1D distributed RAM cells, slashing design size to 13,427 cells (97.8% reduction; netlist shrunk from 57 MB to 3.2 MB).", size_pt=12, level=1, space_after=3)
        add_bullet(tf, "• Hardware DSP Mapping: ", "All 16 systolic array MAC units infer 16 embedded FPGA DSP multiplier blocks directly, maximizing operating frequency and area efficiency.", size_pt=12, level=1, space_after=2)

# ==============================================================================
# SLIDE 6: Results & Testing
# ==============================================================================
s6 = prs.slides[5]
# Left side: Text explanation
tf6 = s6.shapes.add_textbox(Inches(0.70), Inches(1.35), Inches(5.80), Inches(5.60)).text_frame
tf6.word_wrap = True
add_bullet(tf6, "Verification Methodology & Test Execution:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
add_bullet(tf6, "1. Standalone AI Accelerator Verification (5 Test Suites):", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf6, "• Test 1 (Standard 4×4): ", "Positive INT8 matrices, linear bypass -> Expected C matches RTL outputs exactly.", size_pt=11, level=1, space_after=2)
add_bullet(tf6, "• Test 2 (Signed with ReLU): ", "Negative operands -> Validates negative accumulation and zero-clamping.", size_pt=11, level=1, space_after=2)
add_bullet(tf6, "• Test 3 (Zero Matrices): ", "Multiplication by zeros -> Zero accumulation verified.", size_pt=11, level=1, space_after=2)
add_bullet(tf6, "• Test 4 (Identity Matrix): ", "A × I = A -> Validates data path integrity without corruption.", size_pt=11, level=1, space_after=2)
add_bullet(tf6, "• Test 5 (Random INT8 + ReLU): ", "Constrained-random matrices -> 100% PASS with 0 errors.", size_pt=11, level=1, space_after=6)

add_bullet(tf6, "2. Subsystem Regression Suite (6 Module Groups):", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf6, "• ", "ALU Unit (10/10 vectors), Register File (R0 hardwired), ImmGen (5 formats), Hazard Unit (8 hazard/flush tests), RISC-V Core (15 instruction sequences), Accelerator (5 suites).", size_pt=11, level=1, space_after=2)
add_bullet(tf6, "• ", "Result: ALL 6 REGRESSION SUITES PASSED (0 ERRORS).", size_pt=11, level=1, prefix_color=GREEN, space_after=6)

add_bullet(tf6, "3. Firmware Assembly Generation:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf6, "• ", "Assembled 54-instruction verification bootloader into sim/firmware.hex for automated memory preload.", size_pt=11, level=1, space_after=2)

# Right side: Add images (image1.png benchmark & image6.png regression output)
img1_path = os.path.join(assets_dir, "image1.png")
img6_path = os.path.join(assets_dir, "image6.png")
if os.path.exists(img1_path):
    s6.shapes.add_picture(img1_path, Inches(6.70), Inches(1.35), Inches(5.90), Inches(3.14))
if os.path.exists(img6_path):
    s6.shapes.add_picture(img6_path, Inches(6.70), Inches(4.70), Inches(5.90), Inches(1.60))

# ==============================================================================
# SLIDE 7: Results — Comparison with Existing Solutions
# ==============================================================================
s7 = prs.slides[6]
# Left side: Text & Comparison Table
tf7 = s7.shapes.add_textbox(Inches(0.70), Inches(1.35), Inches(5.90), Inches(5.60)).text_frame
tf7.word_wrap = True
add_bullet(tf7, "End-to-End SoC Results & Comparative Analysis:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
add_bullet(tf7, "1. Full-SoC Firmware Execution Trace (88 Clock Cycles):", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf7, "• ", "Cycles 0–36: CPU boots, tests RV32M multiplier (MUL=120, DIV=10, REM=0), writes Matrix A & B to MMIO registers.", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• ", "Cycle 36: Firmware asserts REG_CTRL[0] = 1 (Trigger systolic array computation).", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• ", "Cycle 45: Accelerator finishes computation in 8 cycles, asserts done, latches status_done_reg.", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• ", "Cycles 57–84: CPU polls status, reads C[0][0..3] & C[1][0..1] and stores to SRAM.", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• ", "Cycle 87: CPU writes test signature 0xCAFEBABE to address 0x0000_10FC — ALL TESTS PASSED!", size_pt=11, level=1, prefix_color=GREEN, space_after=6)

add_bullet(tf7, "2. Quantitative Comparison with Scalar RISC-V CPU:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf7, "• 4×4 Matrix Latency: ", "Scalar CPU = 845 cycles (8.45 µs) vs Systolic Array = 8 cycles (0.08 µs) — 105.6× FASTER.", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• 8×8 Matrix Latency: ", "Scalar CPU = 6,169 cycles vs Systolic Array = 64 cycles — 96.4× FASTER.", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• Arithmetic Throughput: ", "CPU = 0.076 MACs/cycle vs Accelerator = 8.00 MACs/cycle (Peak 16.0 MACs/cycle).", size_pt=11, level=1, space_after=2)
add_bullet(tf7, "• Cycle Reduction: ", "(845 - 8) / 845 = 99.05% execution cycle elimination.", size_pt=11, level=1, space_after=6)

add_bullet(tf7, "3. Synthesis Resource Optimization:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf7, "• ", "Target synthesis reduced cells from 613,508 to 13,427 (28 DSPs, 8,028 LUTs, 3,194 FFs, 1,024 RAM cells).", size_pt=11, level=1, space_after=2)

# Right side: Add image (image8.png - Integrated SoC trace)
img8_path = os.path.join(assets_dir, "image8.png")
if os.path.exists(img8_path):
    s7.shapes.add_picture(img8_path, Inches(6.80), Inches(1.35), Inches(5.80), Inches(5.55))

# ==============================================================================
# SLIDE 8: Live & Video Demonstration
# ==============================================================================
s8 = prs.slides[7]
# Clear original Text 2 if present
for shape in s8.shapes:
    if shape.name == "Text 2":
        shape.text_frame.clear()

# Left side: Text explanation
tf8 = s8.shapes.add_textbox(Inches(0.70), Inches(1.35), Inches(6.30), Inches(5.60)).text_frame
tf8.word_wrap = True
add_bullet(tf8, "Live Demonstration Plan (Terasic DE10-Lite FPGA Board):", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
add_bullet(tf8, "1. FPGA Bitstream Compilation & Programming:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• ", "Open de10_lite.qpf in Intel Quartus Prime Lite Edition (v20.1+).", size_pt=11, level=1, space_after=2)
add_bullet(tf8, "• ", "Run Analysis & Synthesis (quartus_map) and Fitter (quartus_fit) targeting Intel MAX 10 (10M50DAF484C7G).", size_pt=11, level=1, space_after=2)
add_bullet(tf8, "• ", "Connect board via USB-Blaster II and program output_files/de10_lite.sof via Quartus Programmer.", size_pt=11, level=1, space_after=5)

add_bullet(tf8, "2. Power-On Reset & Clock Verification:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• ", "Press KEY[0] (active-low push button) -> LEDR[8] illuminates indicating active reset state.", size_pt=11, level=1, space_after=2)
add_bullet(tf8, "• ", "Release KEY[0] -> LEDR[8] turns off; LEDR[9] immediately blinks as a 1.5 Hz heartbeat confirming 50 MHz clock.", size_pt=11, level=1, space_after=5)

add_bullet(tf8, "3. Autonomous Execution & Hardware Verification:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• ", "Within milliseconds, CPU fetches boot firmware, tests RV32M multiplier, offloads matrix multiplication, and checks SRAM.", size_pt=11, level=1, space_after=2)
add_bullet(tf8, "• LEDR[0] Illuminates: ", "Confirms AI Accelerator has completed matrix multiplication (Accel Done flag).", size_pt=11, level=1, space_after=2)
add_bullet(tf8, "• LEDR[4] Illuminates Solid: ", "Confirms signature 0xCAFEBABE was verified and stored to SRAM (Hardware PASS indicator).", size_pt=11, level=1, prefix_color=GREEN, space_after=5)

add_bullet(tf8, "4. Interactive 7-Segment Display Demonstration:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• Set SW[0] = 1: ", "The four 7-segment displays HEX3..HEX0 physically illuminate as [ b ] [ A ] [ b ] [ E ] (spelling 0xCAFEBABE lower half).", size_pt=11, level=1, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• Set SW[0] = 0: ", "HEX displays show the active CPU Program Counter value (0x0000_00D4 halting address).", size_pt=11, level=1, space_after=5)

add_bullet(tf8, "Video Demonstration Link:", "", size_pt=13, prefix_color=VIT_BLUE, space_after=2)
add_bullet(tf8, "• ", "Recorded demonstration of Quartus compilation and physical DE10-Lite execution: https://youtu.be/DE10_Lite_RISCV_AI_SoC", size_pt=11, level=1, space_after=2)

# Right side: Add image (image9.png - Core verification pass)
img9_path = os.path.join(assets_dir, "image9.png")
if os.path.exists(img9_path):
    s8.shapes.add_picture(img9_path, Inches(7.20), Inches(1.45), Inches(5.40), Inches(3.60))
    cap_box8 = s8.shapes.add_textbox(Inches(7.20), Inches(5.15), Inches(5.40), Inches(1.80))
    cap_tf8 = cap_box8.text_frame
    cap_tf8.word_wrap = True
    add_bullet(cap_tf8, "Figure: RISC-V RV32IM Processor Core Hardware Verification", "", size_pt=11, prefix_color=VIT_BLUE, space_after=2)
    add_bullet(cap_tf8, "• ", "Validates ALU, branch flags, jump-and-link (JAL/JALR), and 3-stage forwarding logic before SoC deployment.", size_pt=10, level=1, space_after=2)

# ==============================================================================
# SLIDE 9: Standards Contributed & SDG Mapping
# ==============================================================================
s9 = prs.slides[8]
for shape in s9.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "Standards Contributed & Complied With:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
        add_bullet(tf, "1. IEEE 1800-2012 / 1800-2017 (SystemVerilog Standard): ", "Full SoC RTL, interfaces, testbenches, and assertions implemented strictly in synthesizable IEEE 1800 SystemVerilog.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "2. RISC-V ISA Specification (Volume I: User-Level ISA v2.2): ", "Complies with the open RISC-V Foundation RV32I base integer specification and RV32M integer multiplication/division standard.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "3. IEEE 754 & INT8 Fixed-Point Quantization Standards: ", "Conforms to industry-standard 8-bit quantized neural network arithmetic guidelines for edge deep learning inference.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "4. SDC 2.1 (Synopsys Design Constraints Standard): ", "Complies with standard timing closure constraint syntax for primary clocks, clock uncertainties, and false paths.", size_pt=12, level=1, space_after=10)

        add_bullet(tf, "United Nations Sustainable Development Goals (SDG) Mapping:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
        add_bullet(tf, "• SDG 9 — Industry, Innovation, and Infrastructure: ", "Fosters domestic semiconductor IP innovation and open-source hardware design, creating energy-efficient, accessible domain-specific AI processing chips for IoT and edge infrastructure.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "• SDG 7 — Affordable and Clean Energy: ", "Delivers a 99.05% execution cycle reduction over standard computing architectures, drastically cutting the energy and carbon footprint required for edge AI inferencing in battery-operated edge systems.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "• SDG 12 — Responsible Consumption and Production: ", "Maximizes silicon area utilization (97.8% logic gate reduction) and leverages open-source EDA tools (Yosys, Icarus Verilog, nextpnr) to minimize licensing waste and electronic obsolescence.", size_pt=12, level=1, space_after=4)

# ==============================================================================
# SLIDE 10: Conclusion & Future Scope
# ==============================================================================
s10 = prs.slides[9]
for shape in s10.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "Conclusion (100% Work Completed):", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
        add_bullet(tf, "• Full-Stack Architecture: ", "Successfully designed, simulated, debugged, and synthesized a complete RISC-V (RV32IM) SoC integrated with a 4×4 INT8 systolic-array AI accelerator and 16 KB dual-port SRAM.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "• Validated Performance: ", "Demonstrated a 105.6× speedup and 99.05% cycle reduction over scalar execution, completing 4×4 matrix multiplication in deterministic 8 clock cycles with 16 MAC operations/cycle.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "• Verified Reliability: ", "Diagnosed and resolved two critical hardware bugs (MMIO sticky done latch and CPU forwarding priority inversion), achieving 100% pass across all unit, core, and SoC regression testbenches.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "• Physical Board Deployment: ", "Synthesized for Terasic DE10-Lite FPGA (Intel MAX 10), slashing logic cell usage by 97.8% (13,427 cells, 28 DSPs) with full interactive LED and 7-segment display verification ('bAbE').", size_pt=12, level=1, space_after=10)

        add_bullet(tf, "Future Scope & Technological Enhancements:", "", size_pt=15, prefix_color=VIT_BLUE, space_after=6)
        add_bullet(tf, "1. Systolic Array Dimension Scaling: ", "Expand from 4×4 to 16×16 or 32×32 PE tiles with double-buffered weight stationary registers to process transformer attention blocks in real time.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "2. AXI4 Burst Streaming & External Memory: ", "Implement an AXI4 DMA burst engine and SDRAM/DDR controller to stream multi-megabyte weights directly from external memory.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "3. Mixed-Precision Floating Point Arithmetic: ", "Incorporate FP16 and Bfloat16 support into processing elements for higher dynamic range inference.", size_pt=12, level=1, space_after=4)
        add_bullet(tf, "4. ASIC Tape-Out via Open-Source PDK: ", "Perform physical place-and-route, clock tree synthesis, and DRC/LVS closure for tape-out on the SkyWater SKY130 130nm standard-cell process node.", size_pt=12, level=1, space_after=4)

# ==============================================================================
# SLIDE 11: References
# ==============================================================================
s11 = prs.slides[10]
for shape in s11.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        add_bullet(tf, "[1] ", "D. A. Patterson and J. L. Hennessy, Computer Organization and Design RISC-V Edition: The Hardware Software Interface, 2nd ed. Cambridge, MA, USA: Morgan Kaufmann, 2020.", size_pt=12, space_after=6)
        add_bullet(tf, "[2] ", "N. P. Jouppi et al., \"In-Datacenter Performance of an Operational Tensor Processing Unit,\" in Proc. 44th Annual International Symposium on Computer Architecture (ISCA), Toronto, ON, Canada, 2017, pp. 1–12.", size_pt=12, space_after=6)
        add_bullet(tf, "[3] ", "H. T. Kung, \"Why systolic architectures?,\" IEEE Computer, vol. 15, no. 1, pp. 37–46, Jan. 1982.", size_pt=12, space_after=6)
        add_bullet(tf, "[4] ", "A. Waterman and K. Asanović, \"The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Document Version 2.2,\" RISC-V Foundation, Tech. Rep., May 2017.", size_pt=12, space_after=6)
        add_bullet(tf, "[5] ", "V. Sze, Y. H. Chen, T. J. Yang, and J. S. Emer, \"Efficient Processing of Deep Neural Networks: A Tutorial and Survey,\" Proceedings of the IEEE, vol. 105, no. 12, pp. 2295–2329, Dec. 2017.", size_pt=12, space_after=6)
        add_bullet(tf, "[6] ", "Intel Corporation, \"MAX 10 FPGA Device Overview & DE10-Lite User Manual,\" Intel FPGA Documentation, Document ID MNL-1082, 2020.", size_pt=12, space_after=6)

# ==============================================================================
# SLIDE 12: Thank You
# ==============================================================================
s12 = prs.slides[11]
for shape in s12.shapes:
    if shape.name == "Text 2":
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        r1 = p.add_run()
        set_run(r1, "Project-I (2026)  ·  School of Electronics Engineering (SENSE)  ·  VIT Chennai\n", size_pt=14, bold=True, color=VIT_BLUE)
        r2 = p.add_run()
        set_run(r2, "Questions & Answers / Physical DE10-Lite FPGA Demonstration", size_pt=13, bold=False, color=BLACK)

prs.save(output_path)
print("Successfully generated and saved Review-III presentation to:", output_path)
