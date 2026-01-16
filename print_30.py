import json

def try_load(enc):
    try:
        with open('models.json', 'r', encoding=enc) as f:
            return json.load(f)
    except:
        return None

data = try_load('utf-8') or try_load('utf-16') or try_load('latin-1')

if data:
    models = [m['name'] for m in data.get('models', []) if 'generateContent' in m['supportedGenerationMethods']]
    print(f"Total generateContent models: {len(models)}")
    for m in models[:30]:
        print(m)
else:
    print("FAILED TO LOAD")
