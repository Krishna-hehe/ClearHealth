import requests

api_key = "AIzaSyAmlnKCQ7QSpsGKro9rrnpKTSKua6WYZaA"

# Test models that might have better free tier quotas
models_to_test = [
    "gemini-1.5-flash-8b",  # Smaller, might have better quotas
    "gemini-pro",           # Older stable model
    "gemini-1.0-pro",       # Even older, might have better quotas
]

print("Testing models for quota availability:\n")
for model in models_to_test:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {"contents": [{"parts": [{"text": "Hello"}]}]}
    
    try:
        r = requests.post(url, json=payload, timeout=5)
        if r.status_code == 200:
            print(f"✓ {model}: SUCCESS - This model works!")
        elif r.status_code == 429:
            print(f"✗ {model}: QUOTA EXCEEDED")
        elif r.status_code == 404:
            print(f"✗ {model}: NOT AVAILABLE")
        else:
            print(f"? {model}: Status {r.status_code}")
    except Exception as e:
        print(f"✗ {model}: ERROR - {str(e)[:50]}")
