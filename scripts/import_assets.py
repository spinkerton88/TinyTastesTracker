import os
import shutil
import json
import sys

# Usage: python3 import_assets.py <source_dir> <target_assets_dir>

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 import_assets.py <source_dir> <target_assets_dir>")
        sys.exit(1)

    source_dir = sys.argv[1]
    target_dir = sys.argv[2]

    if not os.path.exists(target_dir):
        print(f"Target directory {target_dir} does not exist")
        sys.exit(1)

    print(f"Scanning {source_dir}...")
    
    # List all png files
    all_files = [f for f in os.listdir(source_dir) if f.endswith(".png")]

    for filename in all_files:
        if not filename.startswith("food_"):
            print(f"Skipping {filename}: Does not start with 'food_'")
            continue
            
        asset_name = filename.replace(".png", "")
        print(f"Processing {asset_name}...")

        # Create imageset directory
        asset_path = os.path.join(target_dir, f"{asset_name}.imageset")
        
        # Clean up existing directory to remove stale files
        if os.path.exists(asset_path):
            shutil.rmtree(asset_path)
            
        os.makedirs(asset_path, exist_ok=True)
        
        # Copy source file
        shutil.copy2(os.path.join(source_dir, filename), os.path.join(asset_path, "image.png"))
        
        # Construct JSON
        images_json = []
        
        # Universal (Any Appearance)
        for scale in ["1x", "2x", "3x"]:
            images_json.append({
                "idiom": "universal",
                "scale": scale,
                "filename": "image.png"
            })
            
        contents = {
            "images": images_json,
            "info": {
                "version": 1,
                "author": "xcode"
            }
        }
        
        with open(os.path.join(asset_path, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)

    print("Done importing assets.")

if __name__ == "__main__":
    main()
