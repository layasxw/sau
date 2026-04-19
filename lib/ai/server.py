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

SAFETY_RULES = """
SAFETY RULES — always follow these:
- Never diagnose conditions or prescribe medications
- Never tell the patient to stop or change doctor-prescribed treatment
- If symptoms are severe (pain 4-5/5, bleeding, vomiting) always say: "Please contact your doctor or go to the hospital immediately"
- Always remind that your advice does not replace medical consultation
- Be supportive and encouraging, not alarming
"""

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
Extract symptoms from the user's text and return ONLY JSON in English:
{
  "mood": "Great, Good, Okay, Low, or Bad",
  "notes": "brief summary of what the patient said",
  "symptoms": {"Symptom name in English": 1-5}
}
Severity scale: 1=very mild, 2=mild, 3=moderate, 4=severe, 5=very severe.
Always respond in English regardless of input language."""},
            {"role": "user", "content": request.text}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Symptom Analysis ──────────────────────────────────────────────────────────

class SymptomAnalysisRequest(BaseModel):
    symptoms: Dict[str, int]
    mood: str
    notes: Optional[str] = None
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None
    restrictions: Optional[dict] = None

@app.post("/analyze-symptoms")
def analyze_symptoms(request: SymptomAnalysisRequest):
    context = ""
    if request.diagnosis:
        context += f"Diagnosis: {request.diagnosis}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"
    if request.restrictions:
        allergies = request.restrictions.get('allergies', [])
        if allergies:
            context += f"Allergies: {', '.join(allergies)}\n"

    prompt = f"""{context}
Symptoms: {request.symptoms}
Mood: {request.mood}
Notes: {request.notes or 'none'}"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation support assistant for post-surgical patients.
{SAFETY_RULES}
Give personalized, supportive advice based on the patient's specific diagnosis and recovery stage.
Always respond in English.

Return ONLY JSON:
{{
  "risk": "low|medium|high",
  "summary": "brief summary of current state in 1-2 sentences",
  "advice": "specific advice relevant to their diagnosis and recovery day",
  "reminder": "one gentle motivational reminder",
  "see_doctor": true or false
}}"""},
            {"role": "user", "content": prompt}
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
Patient profile: {request.profile}
Medical info: {request.medical}
Recent symptoms: {request.recent_symptoms}
Recent meals: {request.recent_meals}
"""
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation expert for post-surgical patients.
{SAFETY_RULES}
Always respond in English.

Return ONLY JSON:
{{
  "risk": "low|medium|high",
  "status": "overall recovery status in 1-2 sentences",
  "concerns": "any concerns based on symptoms and nutrition",
  "nutrition": "personalized nutrition advice based on diagnosis",
  "activity": "appropriate activity recommendations for recovery stage",
  "doctor": "what to discuss at next doctor appointment"
}}"""},
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
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None

@app.post("/analyze-meal")
def analyze_meal(request: MealAnalysisRequest):
    context = ""
    if request.diagnosis:
        context += f"Diagnosis: {request.diagnosis}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"

    prompt = f"""{context}
Meals: {request.meals}
Calories: {request.total_calories}
Protein: {request.total_protein}g
Carbs: {request.total_carbs}g
Fat: {request.total_fat}g"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a nutrition advisor for post-surgical rehabilitation patients.
{SAFETY_RULES}
Always respond in English.

Return ONLY JSON:
{{
  "rating": "low|good|high",
  "summary": "brief assessment of today's nutrition in 1-2 sentences",
  "advice": "specific nutrition advice relevant to their diagnosis and recovery stage"
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Suggest Reminders ─────────────────────────────────────────────────────────

class ReminderSuggestionRequest(BaseModel):
    symptoms: Optional[Dict[str, int]] = None
    meals: Optional[list] = None
    mood: Optional[str] = None
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None

@app.post("/suggest-reminders")
def suggest_reminders(request: ReminderSuggestionRequest):
    context = ""
    if request.diagnosis:
        context += f"Diagnosis: {request.diagnosis}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"

    prompt = f"""{context}
Symptoms: {request.symptoms or 'none'}
Nutrition: {request.meals or 'none'}
Mood: {request.mood or 'none'}"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation support assistant.
{SAFETY_RULES}
Suggest 2-3 personalized reminders based on the patient's current state and diagnosis.
Always respond in English.

Return ONLY JSON:
{{
  "reminders": [
    {{"title": "short title", "description": "brief description"}}
  ]
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    return safe_json_parse(response.choices[0].message.content)


# ── Recovery Score ────────────────────────────────────────────────────────────

class DailyLog(BaseModel):
    date: str
    symptoms: Optional[Dict[str, int]] = None
    mood: Optional[str] = None
    meals: Optional[list] = None
    total_protein: Optional[float] = None

class RecoveryScoreRequest(BaseModel):
    today: DailyLog
    history: Optional[List[DailyLog]] = []

RED_FLAG_SYMPTOMS = {"blood", "vomiting", "bleeding"}

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