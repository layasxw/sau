from fastapi import FastAPI
from pydantic import BaseModel
from openai import OpenAI
import json
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

client = OpenAI(
    api_key=os.getenv("GROQ_API_KEY"),
    base_url="https://api.groq.com/openai/v1"
)



class SymptomRequest(BaseModel):
    text: str

@app.post("/symptoms")
def extract_symptoms(request: SymptomRequest):
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "system",
                "content": """You are a medical data extraction assistant.
Extract symptoms from user text and return ONLY a valid JSON object:
{
  "mood": "one of: Good, Okay, Low, Bad",
  "notes": "general comments or empty string",
  "symptoms": {
    "Symptom Name in English": severity as integer 1-10
  }
}
Rules:
- symptom names in English, capitalized
- severity 1-10
- return ONLY JSON, nothing else"""
            },
            {
                "role": "user",
                "content": request.text
            }
        ]
    )
    
    result = json.loads(response.choices[0].message.content)
    return result