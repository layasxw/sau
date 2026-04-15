from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from typing import Optional
from dotenv import load_dotenv
import json
import os

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

# ── Symptom Extraction ────────────────────────────────────────────────────────

class SymptomRequest(BaseModel):
    text: str

@app.post("/symptoms")
def extract_symptoms(request: SymptomRequest):
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """You are a medical data extraction assistant.
Extract symptoms from user text and return ONLY a valid JSON object:
{
  "mood": "one of: Great Good, Okay, Low, Bad",
  "notes": "general comments or empty string",
  "symptoms": {
    "Symptom Name in English": severity as integer 1-5
  }
}
Rules:
- symptom names in English, capitalized
- severity 1-5
- return ONLY JSON, nothing else"""},
            {"role": "user", "content": request.text}
        ]
    )
    return json.loads(response.choices[0].message.content)


# ── AI Recovery Advisor ───────────────────────────────────────────────────────

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

RED FLAGS — если есть любой из этих симптомов, укажи risk как high:
- кровь в стуле или рвоте
- острая боль в животе
- температура выше 38.5°C
- непрекращающаяся рвота
- резкая потеря веса

Верни ТОЛЬКО валидный JSON без markdown:
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
    return json.loads(clean)


class SymptomAnalysisRequest(BaseModel):
    symptoms: dict
    mood: str
    notes: Optional[str] = None

@app.post("/analyze-symptoms")
def analyze_symptoms(request: SymptomAnalysisRequest):
    prompt = f"""
Симптомы пациента сегодня: {request.symptoms}
Настроение: {request.mood}
Заметки: {request.notes or 'нет'}
"""
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Ты — экспертная система по реабилитации после рака желудка.

RED FLAGS — если есть кровь, острая боль, температура выше 38.5, рвота — укажи risk как high.

Верни ТОЛЬКО валидный JSON без markdown:
{
  "risk": "low" или "medium" или "high",
  "summary": "одно предложение об общем состоянии",
  "advice": "конкретная рекомендация что делать сегодня",
  "reminder": "одно напоминание которое стоит добавить например Выпить 8 стаканов воды"
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    raw = response.choices[0].message.content
    clean = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(clean)

class MealAnalysisRequest(BaseModel):
    meals: list
    total_calories: int
    total_protein: float
    total_carbs: float
    total_fat: float

@app.post("/analyze-meal")
def analyze_meal(request: MealAnalysisRequest):
    prompt = f"""
Приемы пищи сегодня: {request.meals}
Итого калорий: {request.total_calories}
Белки: {request.total_protein}г
Углеводы: {request.total_carbs}г
Жиры: {request.total_fat}г
"""
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Ты — диетолог для пациентов после рака желудка.
Анализируй питание и давай конкретные рекомендации.

Верни ТОЛЬКО валидный JSON без markdown:
{
  "rating": "good" или "low" или "high",
  "summary": "одно предложение об общем питании сегодня",
  "advice": "конкретная рекомендация что добавить или убрать"
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    raw = response.choices[0].message.content
    clean = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(clean)

class ReminderSuggestionRequest(BaseModel):
    symptoms: Optional[list] = None
    meals: Optional[list] = None
    mood: Optional[str] = None

@app.post("/suggest-reminders")
def suggest_reminders(request: ReminderSuggestionRequest):
    prompt = f"""
Симптомы сегодня: {request.symptoms or 'нет данных'}
Приемы пищи: {request.meals or 'нет данных'}
Настроение: {request.mood or 'нет данных'}
"""
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Ты — помощник по реабилитации после рака желудка.
На основе симптомов и питания предложи 2-3 мягких напоминания для пациента.

Правила:
- Никаких точных цифр (не пиши "выпей 8 стаканов", пиши "пей воду регулярно")
- Только безопасные общие рекомендации
- Короткие и понятные

Верни ТОЛЬКО валидный JSON без markdown:
{
  "reminders": [
    {"title": "Короткое название", "description": "Краткое описание"},
    {"title": "Короткое название", "description": "Краткое описание"}
  ]
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    raw = response.choices[0].message.content
    clean = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(clean)