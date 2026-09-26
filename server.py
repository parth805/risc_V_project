"""
================================================================================
File: server.py
Description: Launches the Live RISC-V AI SoC Visual Studio & Waveform Analyzer
================================================================================
"""

import http.server
import socketserver
import webbrowser
import os
import shutil

PORT = 8080

def main():
    dashboard_src = r"C:\Users\adity\.gemini\antigravity\brain\2aeb373c-a26d-4e6a-be18-b81f751bd06f\dashboard.html"
    target_html = "index.html"
    
    if os.path.exists(dashboard_src):
        shutil.copyfile(dashboard_src, target_html)
        print(f"[INFO] Copied dashboard to {target_html}")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def end_headers(self):
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
            super().end_headers()

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        url = f"http://localhost:{PORT}"
        print("================================================================================")
        print(f"  🚀 RISC-V AI SoC Visual Hardware Studio running at: {url}")
        print("================================================================================")
        print("Press Ctrl+C in terminal to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[INFO] Studio server stopped.")

if __name__ == "__main__":
    main()
