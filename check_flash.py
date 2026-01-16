import json

def try_load(enc):
    try:
        with open('models.json', 'r', encoding=enc) as f:
            return json.load(f)
    except:
        return None

data = try_load('utf-8') or try_load('utf-16') or try_load('latin-1')

if data:
    for model in data.get('models', []):
        if 'gemini-1.5-flash' in model['name']:
            print(json.dumps(model, indent=2))
else:
    print("FAILED TO LOAD")
