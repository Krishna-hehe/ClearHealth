import google.generativeai as genai
import os

api_key = 'AIzaSyB-g1FNoMqM4U0ucRAvw2wyjW9YWNnJsJ0'
genai.configure(api_key=api_key)

print(f"Testing Key: {api_key[:5]}...")

try:
    print("Listing available models...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")
