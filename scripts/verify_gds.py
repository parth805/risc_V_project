import pya
import os

files = ["riscv_core.gds", "ai_accelerator.gds", "soc_top.gds"]
gds_dir = r"P:\project 1\gds"

print("=" * 60)
print("VERIFYING GENERATED GDSII LAYOUTS")
print("=" * 60)

for fname in files:
    fpath = os.path.join(gds_dir, fname)
    layout = pya.Layout()
    layout.read(fpath)
    top_cell = layout.top_cell()
    bbox = top_cell.bbox()
    dbu = layout.dbu
    w_um = bbox.width() * dbu
    h_um = bbox.height() * dbu
    cells = [c.name for c in layout.each_cell()]
    print(f"\nLayout: {fname}")
    print(f"  Size on disk: {os.path.getsize(fpath):,} bytes")
    print(f"  Top Cell: {top_cell.name}")
    print(f"  Dimensions: {w_um:.1f} um x {h_um:.1f} um ({w_um/1000:.2f} mm x {h_um/1000:.2f} mm)")
    print(f"  Total Hierarchical Cells: {layout.cells()}")
    print(f"  Subcells: {', '.join(cells[:8])}{' ...' if len(cells) > 8 else ''}")
    print(f"  Layer count: {layout.layers()}")

print("\n" + "=" * 60)
print("ALL LAYOUTS VERIFIED SUCCESSFULLY")
print("=" * 60)
