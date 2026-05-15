from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from typing import Optional, List, Dict
from dotenv import load_dotenv
import json
import os
import base64

load_dotenv()

app = FastAPI()

def get_language_name(code: str) -> str:
    mapping = {"en": "English", "ru": "Russian", "kk": "Kazakh"}
    return mapping.get(code, "English")

def translate_text(text: str, target_lang: str) -> str:
    if not text or not text.strip():
        return text
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": f"Translate the following text to {target_lang}. Return ONLY the translation, no extra text."},
                {"role": "user", "content": text}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"Translation error: {e}")
        return text

def translate_json(data: dict, target_lang: str) -> dict:
    if not data:
        return data
    try:
        prompt = f"""Translate all string values in this JSON object to {target_lang}. 
Keep keys exactly as they are. 
Maintain the structure and types.
Return ONLY the JSON object.

JSON:
{json.dumps(data, ensure_ascii=False)}"""

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}]
        )
        translated = safe_json_parse(response.choices[0].message.content)
        return translated if translated else data
    except Exception as e:
        print(f"JSON translation error: {e}")
        return data

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://sau-rehab-app.web.app",
        "https://sau-rehab-app.firebaseapp.com",
        "http://localhost",
        "http://localhost:5000",
        "http://localhost:49196",
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


# Food Photo Recognition 

class FoodRecognitionRequest(BaseModel):
    image: str
    lang: str = "en"

@app.post("/recognize-food")
def recognize_food(request: FoodRecognitionRequest):
    """
    Accepts a base64 image, returns recognized food name + nutrition per 100g.
    Uses Groq LLaMA-4 Vision as primary, falls back to LLaMA-3.2 Vision if needed.
    """
    try:
        img_bytes = base64.b64decode(request.image)
        if img_bytes[:4] == b'\x89PNG':
            mime_type = "image/png"
        else:
            mime_type = "image/jpeg"
        image_url = f"data:{mime_type};base64,{request.image}"
    except Exception:
        return {"error": "Invalid image data"}

    system_prompt = f"""You are a food recognition expert specializing in Central Asian cuisine (Kazakh, Uzbek, Kyrgyz, Tajik, Turkmen) as well as international dishes.

Analyze the food in the image and return ONLY a JSON object with NO extra text:
{{
  "name": "dish name in {request.lang} (use common transliteration for Central Asian dishes if needed)",
  "confidence": 0.0 to 1.0,
  "calories_per_100g": number,
  "protein_per_100g": number,
  "carbs_per_100g": number,
  "fat_per_100g": number,
  "category": "one of: Казахская кухня / ЦА кухня / Protein / Grains / Vegetables / Fruits / Dairy / Soups / Fast food / Other"
}}

Nutrition values must be realistic per 100g of the dish as typically prepared.
If you cannot identify any food in the image, return: {{"error": "No food detected", "confidence": 0.0}}
Never return markdown, never explain, only JSON."""

    # Try llama-4-scout first (best vision), fall back to llama-3.2-11b-vision
    models_to_try = [
        "meta-llama/llama-4-scout-17b-16e-instruct",
        "llama-3.2-11b-vision-preview",
    ]

    for model in models_to_try:
        try:
            response = client.chat.completions.create(
                model=model,
                max_tokens=300,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image_url",
                                "image_url": {"url": image_url},
                            },
                            {
                                "type": "text",
                                "text": system_prompt,
                            },
                        ],
                    }
                ],
            )
            result = safe_json_parse(response.choices[0].message.content)

            if "name" in result and "error" not in result:
                return result

            if result.get("error") == "No food detected":
                return result

        except Exception as e:
            continue

    return {"error": "Recognition failed. Please try another photo."}


# Symptoms 

class SymptomRequest(BaseModel):
    text: str
    lang: str = "en"

@app.post("/symptoms")
def extract_symptoms(request: SymptomRequest):
    input_text = request.text
    process_lang = request.lang
    
    if request.lang == "kk":
        input_text = translate_text(request.text, "English")
        process_lang = "en"

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a medical data extraction assistant.
Extract symptoms from the user's text and return ONLY JSON in {get_language_name(process_lang)}.
IMPORTANT: All values and keys in the JSON MUST be in {get_language_name(process_lang)}.
{{
  "mood": "Great, Good, Okay, Low, or Bad (in {get_language_name(process_lang)})",
  "notes": "brief summary of what the patient said in {get_language_name(process_lang)}",
  "symptoms": {{"Symptom name in {get_language_name(process_lang)}": 1-5}}
}}
Severity scale: 1=very mild, 2=mild, 3=moderate, 4=severe, 5=very severe.
Always respond exclusively in {get_language_name(process_lang)} regardless of input language."""},
            {"role": "user", "content": input_text}
        ]
    )
    result = safe_json_parse(response.choices[0].message.content)
    
    if request.lang == "kk":
        result = translate_json(result, "Kazakh")
    return result


# Symptom Analysis 

class SymptomAnalysisRequest(BaseModel):
    symptoms: Dict[str, int]
    mood: str
    notes: Optional[str] = None
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None
    restrictions: Optional[dict] = None
    lang: str = "en"

@app.post("/analyze-symptoms")
def analyze_symptoms(request: SymptomAnalysisRequest):
    process_lang = "en" if request.lang == "kk" else request.lang
    
    context = ""
    if request.diagnosis:
        diag = translate_text(request.diagnosis, "English") if request.lang == "kk" else request.diagnosis
        context += f"Diagnosis: {diag}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"
    if request.restrictions:
        restr = translate_text(str(request.restrictions), "English") if request.lang == "kk" else str(request.restrictions)
        context += f"Restrictions: {restr}\n"

    notes = translate_text(request.notes, "English") if request.lang == "kk" and request.notes else request.notes
    prompt = f"""{context}
Recent Symptoms: {request.symptoms}
Patient Notes: {notes}"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation support assistant for post-surgical patients.
{SAFETY_RULES}
Give personalized, supportive advice based on the patient's specific diagnosis and recovery stage.
IMPORTANT: Your entire response MUST be in {get_language_name(process_lang)}. Do not use any other language.

Return ONLY JSON:
{{
  "risk": "low|medium|high",
  "summary": "brief summary of current state in 1-2 sentences in {get_language_name(process_lang)}",
  "advice": "specific advice relevant to their diagnosis and recovery day in {get_language_name(process_lang)}",
  "reminder": "one gentle motivational reminder in {get_language_name(process_lang)}",
  "see_doctor": true or false
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    result = safe_json_parse(response.choices[0].message.content)
    if request.lang == "kk":
        result = translate_json(result, "Kazakh")
    return result


# Recovery Advisor 

class AdvisorRequest(BaseModel):
    profile: Optional[dict] = None
    medical: Optional[dict] = None
    recent_symptoms: Optional[list] = None
    recent_meals: Optional[list] = None
    lang: str = "en"

@app.post("/analyze")
def analyze_recovery(request: AdvisorRequest):
    process_lang = "en" if request.lang == "kk" else request.lang
    
    # Translate input if kk
    profile = request.profile
    medical = request.medical
    symptoms = request.recent_symptoms
    meals = request.recent_meals
    
    if request.lang == "kk":
        medical = translate_json(medical, "English")
        symptoms = [translate_json(s, "English") for s in symptoms] if symptoms else symptoms
        meals = [translate_json(m, "English") for m in meals] if meals else meals

    prompt = f"""Patient profile: {profile}
Medical info: {medical}
Recent symptoms: {symptoms}
Recent meals: {meals}"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation expert for post-surgical patients.
{SAFETY_RULES}
IMPORTANT: Your entire response MUST be in {get_language_name(process_lang)}. All text fields must be in {get_language_name(process_lang)}.

Return ONLY JSON:
{{
  "risk": "low|medium|high",
  "status": "overall recovery status in 1-2 sentences in {get_language_name(process_lang)}",
  "concerns": "any concerns based on symptoms and nutrition in {get_language_name(process_lang)}",
  "nutrition": "personalized nutrition advice based on diagnosis in {get_language_name(process_lang)}",
  "activity": "appropriate activity recommendations for recovery stage in {get_language_name(process_lang)}",
  "doctor": "what to discuss at next doctor appointment in {get_language_name(process_lang)}"
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    result = safe_json_parse(response.choices[0].message.content)
    if request.lang == "kk":
        result = translate_json(result, "Kazakh")
    return result


# Meal Analysis 

class MealAnalysisRequest(BaseModel):
    meals: list
    total_calories: int
    total_protein: float
    total_carbs: float
    total_fat: float
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None
    lang: str = "en"

@app.post("/analyze-meal")
def analyze_meal(request: MealAnalysisRequest):
    process_lang = "en" if request.lang == "kk" else request.lang
    
    context = ""
    if request.diagnosis:
        diag = translate_text(request.diagnosis, "English") if request.lang == "kk" else request.diagnosis
        context += f"Diagnosis: {diag}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"

    meals = request.meals
    if request.lang == "kk":
        meals = [translate_json(m, "English") for m in meals]

    prompt = f"""{context}
Meals: {meals}
Calories: {request.total_calories}
Protein: {request.total_protein}g
Carbs: {request.total_carbs}g
Fat: {request.total_fat}g"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a nutrition advisor for post-surgical rehabilitation patients.
{SAFETY_RULES}
Always respond in {get_language_name(process_lang)}.

Return ONLY JSON:
{{
  "rating": "low|good|high",
  "summary": "brief assessment of today's nutrition in 1-2 sentences in {get_language_name(process_lang)}",
  "advice": "specific nutrition advice relevant to their diagnosis and recovery stage in {get_language_name(process_lang)}"
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    result = safe_json_parse(response.choices[0].message.content)
    if request.lang == "kk":
        result = translate_json(result, "Kazakh")
    return result


# Reminder Suggestions 

class ReminderSuggestionRequest(BaseModel):
    symptoms: Optional[Dict[str, int]] = None
    meals: Optional[list] = None
    mood: Optional[str] = None
    diagnosis: Optional[str] = None
    days_since_surgery: Optional[int] = None
    lang: str = "en"

@app.post("/suggest-reminders")
def suggest_reminders(request: ReminderSuggestionRequest):
    process_lang = "en" if request.lang == "kk" else request.lang
    
    context = ""
    if request.diagnosis:
        diag = translate_text(request.diagnosis, "English") if request.lang == "kk" else request.diagnosis
        context += f"Diagnosis: {diag}\n"
    if request.days_since_surgery is not None:
        context += f"Days since surgery: {request.days_since_surgery}\n"

    symptoms = request.symptoms
    meals = request.meals
    mood = request.mood
    
    if request.lang == "kk":
        symptoms = translate_json(symptoms, "English") if symptoms else symptoms
        meals = [translate_text(m, "English") for m in meals] if meals else meals
        mood = translate_text(mood, "English") if mood else mood

    prompt = f"""{context}
Symptoms: {symptoms or 'none'}
Nutrition: {meals or 'none'}
Mood: {mood or 'none'}"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": f"""You are a rehabilitation support assistant.
{SAFETY_RULES}
Suggest 2-3 personalized reminders based on the patient's current state and diagnosis in {get_language_name(process_lang)}.
Always respond in {get_language_name(process_lang)}.

Return ONLY JSON:
{{
  "reminders": [
    {{"title": "short title in {get_language_name(process_lang)}", "description": "brief description in {get_language_name(process_lang)}"}}
  ]
}}"""},
            {"role": "user", "content": prompt}
        ]
    )
    result = safe_json_parse(response.choices[0].message.content)
    if request.lang == "kk":
        result = translate_json(result, "Kazakh")
    return result


# Recovery Score 

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