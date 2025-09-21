#!/usr/bin/env python3
"""Quick viewer for pollution visualizations"""

import webbrowser
import os
from PIL import Image

print("🌡️  HealthMap AI - Pollution Visualization Viewer\n")

# Check if files exist
files = {
    "Static Heatmap": "pollution_heatmap_static.png",
    "Interactive Map": "pollution_heatmap_interactive.html",
    "3D Surface Plot": "pollution_heatmap_3d.html"
}

print("Available visualizations:")
for i, (name, filename) in enumerate(files.items(), 1):
    if os.path.exists(filename):
        print(f"  {i}. {name} ✅")
    else:
        print(f"  {i}. {name} ❌ (not found)")

print("\nWhich visualization would you like to view?")
print("  1 - Static Heatmap (PNG image)")
print("  2 - Interactive Map (opens in browser)")
print("  3 - 3D Surface Plot (opens in browser)")
print("  4 - View all")
print("  0 - Exit")

choice = input("\nEnter your choice (0-4): ")

if choice == "1":
    if os.path.exists(files["Static Heatmap"]):
        Image.open(files["Static Heatmap"]).show()
        print("✅ Opening static heatmap...")
elif choice == "2":
    if os.path.exists(files["Interactive Map"]):
        webbrowser.open(f"file://{os.path.abspath(files['Interactive Map'])}")
        print("✅ Opening interactive map in browser...")
elif choice == "3":
    if os.path.exists(files["3D Surface Plot"]):
        webbrowser.open(f"file://{os.path.abspath(files['3D Surface Plot'])}")
        print("✅ Opening 3D visualization in browser...")
elif choice == "4":
    print("✅ Opening all visualizations...")
    if os.path.exists(files["Static Heatmap"]):
        Image.open(files["Static Heatmap"]).show()
    if os.path.exists(files["Interactive Map"]):
        webbrowser.open(f"file://{os.path.abspath(files['Interactive Map'])}")
    if os.path.exists(files["3D Surface Plot"]):
        webbrowser.open(f"file://{os.path.abspath(files['3D Surface Plot'])}")
else:
    print("Exiting...")