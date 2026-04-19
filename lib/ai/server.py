from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from typing import Optional, List, Dict
from dotenv import load_dotenv
import json
import os

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://sau-rehab-app.web.app",
        "https://sau-rehab-app.firebaseapp.com",
        "http://localhost",
        "http://localhost:5000",
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(
    api_key=os.getenv("GROQ_API_KEY"),
    base_url="https://api.groq.com/openai/v1"
)

# ── SAFE JSON PARSER ──────────────────────────────────────────────────────────

def safe_json_parse(raw: str):
    import re
    clean = raw.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(clean)
    except:
        match = re.search(r'\{.*\}', clean, re.DOTALL)
        if match:
            try:
                return json.loads(match.group())
            except:
                pass
        return {"error": "Invalid AI response", "raw": clean}
    
# ── Symptom Extraction ────────────────────────────────────────────────────────

class SymptomRequest(BaseModel):
    text: str

@app.post("/symptoms")
def extract_symptoms(request: SymptomRequest):
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """You are a medical data extraction assistant.
Extract symptoms and return ONLY JSON:
{
  "mood": "Great, Good, Okay, Low, Bad",
  "notes": "text",
  "symptoms": {"Symptom": 1-5}
}"""},
            {"role": "user", "content": request.text}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── AI Recovery Advisor ───────────────────────────────────────────────────────

class AdvisorRequest(BaseModel):
    profile: Optional[dict] = None
    medical: Optional[dict] = None
    recent_symptoms: Optional[list] = None
    recent_meals: Optional[list] = None

@app.post("/analyze")
def analyze_recovery(request: AdvisorRequest):
    prompt = f"""
Пациент:
{request.profile}
Медицина:
{request.medical}
Симптомы: {request.recent_symptoms}
Питание: {request.recent_meals}
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Ты эксперт по реабилитации.

Верни JSON:
{
  "risk": "low|medium|high",
  "status": "...",
  "concerns": "...",
  "nutrition": "...",
  "activity": "...",
  "doctor": "..."
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Symptom Analysis ──────────────────────────────────────────────────────────

class SymptomAnalysisRequest(BaseModel):
    symptoms: Dict[str, int]
    mood: str
    notes: Optional[str] = None

@app.post("/analyze-symptoms")
def analyze_symptoms(request: SymptomAnalysisRequest):
    prompt = f"""
Симптомы: {request.symptoms}
Настроение: {request.mood}
Заметки: {request.notes or 'нет'}
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Верни JSON:
{
  "risk": "low|medium|high",
  "summary": "...",
  "advice": "...",
  "reminder": "..."
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Meal Analysis ─────────────────────────────────────────────────────────────

class MealAnalysisRequest(BaseModel):
    meals: list
    total_calories: int
    total_protein: float
    total_carbs: float
    total_fat: float

@app.post("/analyze-meal")
def analyze_meal(request: MealAnalysisRequest):
    prompt = f"""
Meals: {request.meals}
Calories: {request.total_calories}
Protein: {request.total_protein}
Carbs: {request.total_carbs}
Fat: {request.total_fat}
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Верни JSON:
{
  "rating": "low|good|high",
  "summary": "...",
  "advice": "..."
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Suggest Reminders ─────────────────────────────────────────────────────────

class ReminderSuggestionRequest(BaseModel):
    symptoms: Optional[Dict[str, int]] = None
    meals: Optional[list] = None
    mood: Optional[str] = None

@app.post("/suggest-reminders")
def suggest_reminders(request: ReminderSuggestionRequest):
    prompt = f"""
Симптомы: {request.symptoms or 'нет'}
Питание: {request.meals or 'нет'}
Настроение: {request.mood or 'нет'}
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": """Дай 2-3 напоминания.

Верни JSON:
{
  "reminders": [
    {"title": "...", "description": "..."}
  ]
}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Recovery Score (NEW) ──────────────────────────────────────────────────────

class DailyLog(BaseModel):
    date: str
    symptoms: Optional[Dict[str, int]] = None
    mood: Optional[str] = None
    meals: Optional[list] = None
    total_protein: Optional[float] = None

class RecoveryScoreRequest(BaseModel):
    today: DailyLog
    history: Optional[List[DailyLog]] = []

RED_FLAG_SYMPTOMS = {"blood", "vomiting", "кровь", "рвота", "bleeding"}

def compute_single_score(log: DailyLog) -> float:
    score = 55.0

    mood_map = {"Great": 20, "Good": 15, "Okay": 10, "Low": 5, "Bad": 0}
    score += mood_map.get(log.mood or "Okay", 10)

    if log.meals:
        score += min(len(log.meals) * 5, 25)
        if (log.total_protein or 0) > 50:
            score += 5

    if log.symptoms:
        score -= min(sum(log.symptoms.values()) * 3, 40)
        for name in log.symptoms:
            if any(flag in name.lower() for flag in RED_FLAG_SYMPTOMS):
                score = min(score, 30)
                break

    return max(0.0, min(100.0, score))


def compute_trend(scores: List[float]) -> float:
    n = len(scores)
    if n < 2:
        return 0.0
    x_mean = (n - 1) / 2
    y_mean = sum(scores) / n
    num = sum((i - x_mean) * (s - y_mean) for i, s in enumerate(scores))
    den = sum((i - x_mean) ** 2 for i in range(n))
    return round(num / den, 1) if den else 0.0


def compute_consistency(history: List[DailyLog]) -> float:
    days = sum(1 for log in history if log.mood or log.symptoms or log.meals)
    return round((days / 7) * 10, 1)


@app.post("/recovery-score")
def recovery_score(request: RecoveryScoreRequest):
    today_score = compute_single_score(request.today)
    history_scores = [compute_single_score(log) for log in request.history]

    trend = compute_trend(history_scores + [today_score])
    consistency = compute_consistency(request.history)

    final_score = max(0, min(100, today_score + consistency))

    prev = history_scores[-1] if history_scores else None
    delta = round(final_score - prev, 1) if prev is not None else None

    label = (
        "Excellent" if final_score >= 80 else
        "Good" if final_score >= 60 else
        "Fair" if final_score >= 40 else
        "Poor"
    )

    return {
        "score": round(final_score),
        "delta": delta,
        "trend": trend,
        "consistency": consistency,
        "label": label,
    }