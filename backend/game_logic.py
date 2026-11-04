from newsapi import NewsApiClient
from google import genai
from google.genai import types
from config import NEWS_API_KEY, GOOGLE_API_KEY
import random
import re

newsapi = NewsApiClient(api_key=NEWS_API_KEY) if NEWS_API_KEY else None

FALLBACK_REAL_ARTICLES = [
    {
        "title": "Global Renewable Energy Generation Sets Record Milestone in 2026",
        "body": "International energy agencies confirmed that global solar and wind output surpassed 35% of total electricity generation over the past fiscal quarter. The surge was primarily driven by massive decentralized solar initiatives across the European Union and Southeast Asia. Officials noted this transition prevented an estimated 1.2 gigatons of carbon emissions while significantly lowering peak spot energy prices across interconnected grid systems.",
        "is_fake": False,
        "source_url": "https://www.reuters.com/business/energy"
    },
    {
        "title": "Autonomous Deep-Sea Probe Discovers Ancient Oceanic Rift Ecosystem",
        "body": "Marine biologists utilizing next-generation autonomous submersibles mapped an uncharted hydrothermal rift system at a depth of 4,200 meters. The expedition documented dozens of previously uncatalogued chemotrophic organisms thriving in extreme pressure environments. Scientists from the Global Oceanographic Institute confirmed the finding provides pivotal insights into prebiotic mineral synthesis.",
        "is_fake": False,
        "source_url": "https://www.nature.com/articles/oceanography"
    },
    {
        "title": "International Space Consortium Completes Orbital Telecommunications Node",
        "body": "A multilateral aerospace coalition successfully launched and calibrated a high-throughput laser communication array in low Earth orbit. The array delivers low-latency inter-satellite optical routing, bridging remote broadband access for underserved equatorial regions. Ground telemetry stations reported all systems operating within planned operational margins.",
        "is_fake": False,
        "source_url": "https://spacenews.com/orbital-array"
    }
]

def fetch_real_article(country: str) -> dict:
    if not country:
        country = "us"
    if not newsapi:
        return _generate_synthetic_real_article()

    try:
        response = newsapi.get_top_headlines(
            country=country.lower(),
            page_size=10
        )

        articles = response.get("articles", [])
        if not articles:
            print("NewsAPI returned no articles; falling back to synthetic generator.")
            return _generate_synthetic_real_article()
        
        articles_final = []

        for article in articles:
            body = article.get("description") or article.get("content")
            
            if article.get("title") and body and article.get("url"):
                articles_final.append({
                    "title": article.get("title"),
                    "body": body,
                    "is_fake": False,
                    "source_url": article.get("url"),
                })

        if len(articles_final) != 0:
            article_sel = random.choice(articles_final)
            article_sel["is_fake"] = False
            return article_sel
        
        print("No articles with sufficient content found; falling back to synthetic generator.")
        return _generate_synthetic_real_article()

    except Exception as e:
        print(f"Error fetching from NewsAPI: {e}; falling back to synthetic generator.")
        return _generate_synthetic_real_article()

def _generate_synthetic_real_article() -> dict:
    prompt = "Generate a realistic breaking news headline and a 3-paragraph summary about a global event in politics, technology, or science. Format as JSON: {'title': str, 'body': str}. Do not mention you are an AI."
    
    if not GOOGLE_API_KEY:
        return random.choice(FALLBACK_REAL_ARTICLES).copy()

    client = genai.Client(api_key=GOOGLE_API_KEY)
    
    candidate_models = [
        "models/gemini-flash-lite-latest",
        "models/gemini-flash-latest",
        "gemini-2.0-flash",
    ]
    
    for model_name in candidate_models:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(response_mime_type="application/json")
            )
            import json
            data = json.loads(response.text)
            return {
                "title": data['title'],
                "body": data['body'],
                "is_fake": False,
                "source_url": "https://factline.ai/forensic-archive"
            }
        except Exception as e:
            print(f"Synthetic generation with {model_name} failed: {e}")
            continue

    return random.choice(FALLBACK_REAL_ARTICLES).copy()

def doctor_article_with_gemini(article: dict) -> dict:
    if not article or not article.get('body'):
        return None

    prompt = f"""
You are a misinformation generator for an educational fact-checking game. Your task is to rewrite the following news summary to include subtle, believable falsehoods or a slightly altered narrative. The goal is to make it difficult, but not impossible, for a user to tell that it's fake.

RULES:
1. Do not state that you are an AI or that the content is fabricated.
2. Maintain the original tone and style of the summary.
3. The changes should be subtle (e.g., alter a key statistic, change a quote slightly, invent a plausible but fake source).
4. Return ONLY the doctored summary as a single block of text. Do not include the title or any other text.

ORIGINAL ARTICLE TITLE: "{article.get('title', '')}"
ORIGINAL ARTICLE SUMMARY:
---
{article['body']}
---
"""
    if GOOGLE_API_KEY:
        client = genai.Client(api_key=GOOGLE_API_KEY)
        candidate_models = [
            "models/gemini-flash-lite-latest",
            "models/gemini-flash-latest",
            "gemini-2.0-flash",
        ]

        for model_name in candidate_models:
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=types.Content(
                        role="user",
                        parts=[types.Part.from_text(text=prompt)]
                    )
                )
                doctored_body = response.text.strip()
                if doctored_body:
                    return {
                        "title": article['title'],
                        "body": doctored_body,
                        "is_fake": True,
                        "source_url": article.get('source_url', 'https://factline.ai/forensic-archive')
                    }
            except Exception as e:
                print(f"Doctoring with model {model_name} failed: {e}")
                continue

    # Algorithmic subtle doctoring fallback if Gemini is offline
    doctored_text = _algorithmically_doctor_text(article['body'])
    return {
        "title": article['title'],
        "body": doctored_text,
        "is_fake": True,
        "source_url": article.get('source_url', 'https://factline.ai/forensic-archive')
    }

def _algorithmically_doctor_text(text: str) -> str:
    # Subtly alter numbers/percentages/claims
    def alter_number(match):
        val = int(match.group(0))
        delta = random.choice([-5, -3, 4, 12, 25])
        return str(max(1, val + delta))

    modified = re.sub(r'\b\d{2,4}\b', alter_number, text, count=2)
    subtle_injections = [
        " Preliminary whistleblower documents leak conflicting timeline assessments.",
        " Unverified memos suggest internal oversight committees initially disputed these figures.",
        " Anonymous regulatory officials have questioned the baseline verification protocols."
    ]
    return modified + random.choice(subtle_injections)
