import requests

api_key = "AIzaSyAmlnKCQ7QSpsGKro9rrnpKTSKua6WYZaA"
models_to_test = ["gemini-1.5-flash-8b", "gemini-1.5-pro", "gemini-1.0-pro", "gemini-2.0-flash-exp", "gemini-1.5-flash"]

for model in models_to_test:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {"contents": [{"parts": [{"text": "ok"}]}]}
    try:
        r = requests.post(url, json=payload, timeout=5)
        if r.status_code == 200:
            print(f"FOUND_WORKING_MODEL: {model}")
    except:
        pass
