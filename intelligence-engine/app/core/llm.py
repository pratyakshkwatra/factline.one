import json
import urllib.request
from loguru import logger
from app.core.config import settings

def query_llm(prompt: str, model: str = settings.MODEL_SMALL, system_prompt: str = "You are an AI assistant.", temperature: float = 0.7) -> str:
    url = f"{settings.LM_STUDIO_URL}/chat/completions"
    headers = {
        "Content-Type": "application/json"
    }
    data = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": temperature
    }
    
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
        with urllib.request.urlopen(req, timeout=60) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result["choices"][0]["message"]["content"].strip()
    except Exception as e:
        logger.warning(f"LLM request failed (Is LM Studio running on {settings.LM_STUDIO_URL}?): {e}")
        return ""
