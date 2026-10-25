import pya
import os

gds_dir = r"P:\project 1\gds"
assets_dir = r"P:\project 1\presentation_assets"
os.makedirs(assets_dir, exist_ok=True)

layouts = [
    ("riscv_core.gds", "riscv_core.png"),
    ("ai_accelerator.gds", "ai_accelerator.png"),
    ("soc_top.gds", "soc_top.png")
]

print("=" * 60)
print("EXPORTING HIGH-RESOLUTION LAYOUT SCREENSHOTS FROM KLAYOUT")
print("=" * 60)

for gds_name, img_name in layouts:
    gds_path = os.path.join(gds_dir, gds_name)
    img_path1 = os.path.join(gds_dir, img_name)
    img_path2 = os.path.join(assets_dir, img_name)
    
    view = pya.LayoutView()
    view.load_layout(gds_path, 0)
    view.max_hier()
    view.zoom_fit()
    
    # Save 1600x1600 high resolution PNG
    view.save_image(img_path1, 1600, 1600)
    view.save_image(img_path2, 1600, 1600)
    print(f"[OK] Rendered {gds_name} -> {img_path1} ({os.path.getsize(img_path1):,} bytes)")

print("=" * 60)
print("ALL LAYOUT SCREENSHOTS EXPORTED SUCCESSFULLY")
print("=" * 60)
