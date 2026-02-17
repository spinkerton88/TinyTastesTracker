import plistlib
import os

def get_api_key():
    # Try looking relative to script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Go up one level to root, then down to TinyTastesTracker/Resources
    plist_path = os.path.join(script_dir, "..", "TinyTastesTracker", "Resources", "GenerativeAI-Info.plist")
    
    if os.path.exists(plist_path):
        with open(plist_path, 'rb') as fp:
            pl = plistlib.load(fp)
            return pl.get("API_KEY")
    return os.environ.get("GEMINI_API_KEY")

API_KEY = get_api_key()
if not API_KEY:
    print("❌ Error: API_KEY not found in GenerativeAI-Info.plist or environment.")
    exit(1)

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
