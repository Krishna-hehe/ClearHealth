import json

def try_load(enc):
    try:
        with open('models.json', 'r', encoding=enc) as f:
            return json.load(f)
    except:
        return None

data = try_load('utf-8') or try_load('utf-16') or try_load('latin-1')

if data:
    # Filter for stable, non-experimental models
    stable_models = []
    for m in data.get('models', []):
        if 'generateContent' in m['supportedGenerationMethods']:
            name = m['name']
            # Prefer stable models without 'exp' or 'preview'
            if 'gemini' in name.lower() and 'exp' not in name and 'preview' not in name:
                stable_models.append(name)
    
    print("Stable Gemini models:")
    for m in stable_models[:10]:
        print(m)
    
    print("\nAll generation models (first 20):")
    all_models = [m['name'] for m in data.get('models', []) if 'generateContent' in m['supportedGenerationMethods']]
    for m in all_models[:20]:
        print(m)
else:
    print("FAILED TO LOAD")
