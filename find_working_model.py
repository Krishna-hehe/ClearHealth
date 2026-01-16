import requests
import json

api_key = "AIzaSyAgDei3WdrI4R1eKHYI3yi4lcYGqdEBvew"

# First, get list of all models
print("Fetching available models...")
list_url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
list_response = requests.get(list_url)

if list_response.status_code == 200:
    data = list_response.json()
    models = [m['name'] for m in data.get('models', []) if 'generateContent' in m.get('supportedGenerationMethods', [])]
    
    print(f"\nFound {len(models)} models with generateContent support")
    print("\nTesting each model for quota availability...\n")
    
    working_models = []
    for model_name in models[:15]:  # Test first 15
        model = model_name.replace('models/', '')
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        payload = {"contents": [{"parts": [{"text": "hi"}]}]}
        
        try:
            r = requests.post(url, json=payload, timeout=3)
            if r.status_code == 200:
                print(f"✓ {model}: WORKING!")
                working_models.append(model)
            elif r.status_code == 429:
                print(f"✗ {model}: Quota exceeded")
            elif r.status_code == 404:
                print(f"✗ {model}: Not found")
            else:
                print(f"? {model}: Status {r.status_code}")
        except Exception as e:
            print(f"✗ {model}: Error")
    
    if working_models:
        print(f"\n✓✓✓ WORKING MODELS FOUND: {working_models}")
    else:
        print("\n✗✗✗ NO WORKING MODELS - All have quota limits")
else:
    print(f"Failed to list models: {list_response.status_code}")
