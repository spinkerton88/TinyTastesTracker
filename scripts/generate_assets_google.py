import requests
import json
import base64
import os
import time

# Configuration
API_KEY = "AIzaSyDzyKA_uYVtRszxZRkx_FMKgg79ZGvt3cY" # Retrieved from plist
MODEL_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict"
OUTPUT_DIR = "generated_assets"

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# List of foods to generate (Missing Items)
foods_to_generate = [
    ("food_apricot", "fresh apricot fruit"),
    ("food_plum", "fresh purple plum")
]

print(f"Starting Google Imagen 4.0 generation for {len(foods_to_generate)} items...")

success_count = 0
fail_count = 0

for food_id, subject in foods_to_generate:
    filename = f"{food_id}.png"
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    # Skip if exists
    if os.path.exists(filepath):
        print(f"Skipping {filename} (already exists)")
        continue

    # Updated Prompt for Gray Background Strategy
    prompt = f"Professional gourmet studio photography of {subject}, centered, isolated on a solid middle gray background, cinematic lighting, rim light to separate from background, 4k resolution, ultra-detailed texture, glistening fresh surface, sharp focus, shot on 100mm macro lens, f/8, highly appetizing"
    
    headers = {"Content-Type": "application/json"}
    payload = {
        "instances": [
            {"prompt": prompt}
        ],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "1:1"
        }
    }
    
    print(f"Generating {filename}...")
    
    try:
        response = requests.post(f"{MODEL_ENDPOINT}?key={API_KEY}", headers=headers, json=payload, timeout=60)
        
        if response.status_code == 200:
            result = response.json()
            if "predictions" in result:
                encoded_image = result["predictions"][0]["bytesBase64Encoded"]
                with open(filepath, "wb") as f:
                    f.write(base64.b64decode(encoded_image))
                print("✅ Saved.")
                success_count += 1
            else:
                 print(f"❌ Unexpected response format: {result}")
                 fail_count += 1
        else:
            print(f"❌ Failed: {response.status_code} - {response.text}")
            fail_count += 1
            
    except Exception as e:
        print(f"❌ Error: {e}")
        fail_count += 1
    
    # Be polite to the API
    time.sleep(2)

print(f"Done! Success: {success_count}, Failed: {fail_count}")
