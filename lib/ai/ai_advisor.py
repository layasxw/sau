from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
import os
from dotenv import load_dotenv
from typing import Optional
import json as json_lib


load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(
    api_key=os.getenv("GROQ_API_KEY"),
    base_url="https://api.groq.com/openai/v1"
)

class AdvisorRequest(BaseModel):
    profile: Optional[dict] = None
    medical: Optional[dict] = None
    recent_symptoms: Optional[list] = None
    recent_meals: Optional[list] = None

@app.post("/analyze")
def analyze_recovery(request: AdvisorRequest):
    profile = request.profile or {}
    medical = request.medical or {}
    symptoms = request.recent_symptoms or []
    meals = request.recent_meals or []

    prompt = f"""
Данные пациента:
- Имя: {profile.get('fullName', 'неизвестно')}
- Возраст: {profile.get('age', 'неизвестно')}
- Диагноз: {medical.get('diagnosis', 'неизвестно')}
- Дата операции: {medical.get('surgeryDate', 'не указана')}
- История болезни: {medical.get('medicalHistory', 'нет данных')}

Последние симптомы: {symptoms}
Последние приемы пищи: {meals}

Проанализируй состояние пациента и дай рекомендации.
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Ты — экспертная система по реабилитации после рака желудка.
            Основывайся на протоколах ESMO и ERAS.

            🚨 RED FLAGS — если есть любой из этих симптомов, укажи risk как high и срочно рекомендуй врача:
            - кровь в стуле или рвоте
            - острая боль в животе  
            - температура выше 38.5°C
            - непрекращающаяся рвота
            - резкая потеря веса

            Верни ТОЛЬКО валидный JSON без markdown, без пояснений:
            {
            "risk": "low" или "medium" или "high",
            "status": "одно предложение об общем состоянии",
            "concerns": "ключевые проблемы одним предложением",
            "nutrition": "рекомендация по питанию одним предложением",
            "activity": "рекомендация по активности одним предложением",
            "doctor": "когда обратиться к врачу одним предложением"
            }"""},
            {"role": "user", "content": prompt}
        ]
    )

    raw = response.choices[0].message.content
    clean = raw.replace("```json", "").replace("```", "").strip()
    parsed = json_lib.loads(clean)
    return parsed