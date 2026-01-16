import requests

api_key = "AIzaSyAmlnKCQ7QSpsGKro9rrnpKTSKua6WYZaA"
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

response = requests.get(url)
if response.status_code == 200:
    data = response.json()
    for model in data.get("models", []):
        if "gemini" in model['name'].lower() and "generateContent" in model['supportedGenerationMethods']:
            print(f"Model: {model['name']}")
else:
    print(f"Error: {response.status_code}")
