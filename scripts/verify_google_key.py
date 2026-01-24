import requests
import json
import base64
import os

API_KEY = "AIzaSyDzyKA_uYVtRszxZRkx_FMKgg79ZGvt3cY" 

# Target Model: Imagen 4.0 (Upgrade from 3!)
# Endpoint matches what the ListModels call showed for 'predict' method
url = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict?key={API_KEY}"
headers = {"Content-Type": "application/json"}
payload = {
    "instances": [
        {"prompt": "Professional studio photography of a whole raw chicken breast, isolated on a pure white background, soft lighting, 4k resolution, high detail"}
    ],
    "parameters": {
        "sampleCount": 1,
        "aspectRatio": "1:1"
    }
}

print(f"Attempting to generate with Imagen 4.0...")
response = requests.post(url, headers=headers, json=payload)

if response.status_code == 200:
    print("✅ Success! Image generated.")
    try:
        result = response.json()
        if "predictions" in result:
             encoded_image = result["predictions"][0]["bytesBase64Encoded"]
             output_path = "google_test_chicken.png"
             with open(output_path, "wb") as f:
                 f.write(base64.b64decode(encoded_image))
             print(f"✅ Saved to {output_path}")
        else:
             print("Response received but unexpected format.")
             print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Result parsing error: {e}")
        print(response.text)
else:
    print(f"❌ Failed: {response.status_code}")
    print(response.text)
