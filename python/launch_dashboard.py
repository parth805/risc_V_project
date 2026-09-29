#!/usr/bin/env python3
"""
===============================================================================
 File: python/launch_dashboard.py
 Description: Launches the Unified Interactive SoC & AI Accelerator Dashboard
===============================================================================
"""

import webbrowser
import os
from pathlib import Path

def main():
    repo_root = Path(__file__).resolve().parent.parent
    dashboard_file = repo_root / "reports" / "soc_dashboard.html"
    
    if not dashboard_file.exists():
        print(f"[ERROR] Dashboard file not found at: {dashboard_file}")
        return
        
    file_uri = dashboard_file.as_uri()
    print("\n" + "="*80)
    print("      LAUNCHING UNIFIED RISC-V AI ACCELERATOR SOC DASHBOARD ENVIRONMENT     ")
    print("="*80)
    print(f" Dashboard URL: {file_uri}\n")
    
    webbrowser.open(file_uri)
    print("[INFO] Opened dashboard in default browser.")
    print("="*80 + "\n")

if __name__ == "__main__":
    main()
