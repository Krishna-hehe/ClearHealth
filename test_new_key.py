import requests

api_key = "AIzaSyAgDei3WdrI4R1eKHYI3yi4lcYGqdEBvew"
model = "gemini-2.0-flash"

url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
payload = {"contents": [{"parts": [{"text": "Say 'API key is working!'"}]}]}

print(f"Testing new API key with {model}...")
response = requests.post(url, json=payload, timeout=10)

print(f"\nStatus: {response.status_code}")
if response.status_code == 200:
    print("✓ SUCCESS! API key is working and has available quota!")
    data = response.json()
    if 'candidates' in data and len(data['candidates']) > 0:
        text = data['candidates'][0]['content']['parts'][0]['text']
        print(f"Response: {text}")
elif response.status_code == 429:
    print("✗ QUOTA EXCEEDED - This key also has no quota available")
elif response.status_code == 404:
    print("✗ MODEL NOT FOUND - Need to use a different model")
else:
    print(f"✗ ERROR: {response.text[:200]}")
