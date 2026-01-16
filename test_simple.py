import requests

api_key = "AIzaSyAmlnKCQ7QSpsGKro9rrnpKTSKua6WYZaA"
models_to_test = ["gemini-1.5-flash-8b", "gemini-1.5-pro", "gemini-1.0-pro", "gemini-2.0-flash-exp", "gemini-1.5-flash"]

print("--- START TEST ---")
for model in models_to_test:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {"contents": [{"parts": [{"text": "say 'ok'"}]}]}
    try:
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            print(f"MODEL_{model}_SUCCESS")
        else:
            print(f"MODEL_{model}_FAILED_{response.status_code}")
    except Exception as e:
        print(f"MODEL_{model}_ERROR_{str(e)[:20]}")
print("--- END TEST ---")
