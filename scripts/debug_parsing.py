import re

CONSTANTS_PATH = "TinyTastesTracker/Core/Utilities/Constants.swift"

try:
    with open(CONSTANTS_PATH, 'r') as f:
        content = f.read()
        blocks = content.split("FoodItem(")[1:] 
        
        print(f"Found {len(blocks)} blocks")
        
        for i, block in enumerate(blocks):
            id_match = re.search(r'id:\s*"([^"]+)"', block)
            name_match = re.search(r'name:\s*"([^"]+)"', block)
            cat_match = re.search(r'category:\s*\.([a-z]+)', block)
            
            if id_match and name_match:
                print(f"[{i}] ID: {id_match.group(1)} | Name: {name_match.group(1)} | Cat: {cat_match.group(1) if cat_match else 'Unknown'}")
            else:
                print(f"[{i}] FAILED extraction")

except Exception as e:
    print(f"Error: {e}")
