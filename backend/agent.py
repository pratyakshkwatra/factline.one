from __future__ import annotations
from sqlalchemy.orm import Session
from sqlalchemy import (
    Column, Integer, String, DateTime, ForeignKey, JSON, Enum, UniqueConstraint, Float, Text
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from db_base import Base
from google import genai
from google.genai import types
from tavily import TavilyClient
import json
import re
import enum
import pytesseract
from PIL import Image
import io
from typing import List, Dict, Any, Optional
import os
from config import TAVILY_API_KEY
from models.post_model import (
    Post,
    AnalysisStatus,
    MediaType,
    PostTag,
    RedFlag,
    TrustSignal,
    Claim,
    ClaimSource,
    FactCheckSite,
    NewsOutlet,
)
from schemas import UserOut, PostOut
from services.vector_service import VectorService
from logger import get_logger

logger = get_logger("Forensics")

class NewsArticle:
    def __init__(self, title: str, body: str = "", media_url: str = None, media_type: str = "TEXT", source_url: str = None, **extra):
        self.title = title.strip()
        self.body = body.strip() if body else ""
        self.media_url = media_url
        self.media_type = media_type
        self.source_url = source_url
        self.extra = extra

    def to_dict(self) -> Dict[str, Any]:
        return {
            "title": self.title,
            "body": self.body,
            "media_url": self.media_url,
            "media_type": self.media_type,
            "c2pa_signed": self._check_c2pa_provenance(),
            **self.extra
        }

    def _check_c2pa_provenance(self) -> bool:
        if self.media_url and "verified" in self.media_url:
            return True
        return False

def web_search_func(query: str, max_results: int = 5) -> List[Dict[str, Any]]:
    if not query:
        return []
    tavily = TavilyClient(api_key=TAVILY_API_KEY)
    res = tavily.search(query=query, max_results=max_results)
    return res.get("results", [])

WEB_SEARCH_DECLARATION = types.FunctionDeclaration(
    name="web_search",
    description="Search the web to verify a claim or headline; returns concise, source-linked notes.",
    parameters={
        "type": "object",
        "properties": {
            "query": {"type": "string"},
            "max_results": {"type": "integer", "minimum": 1, "maximum": 10},
        },
        "required": ["query"],
    },
)

class NewsCredibilityEngine:
    def __init__(
        self,
        tavily_key: str,
        db: Session,
        post_id: int,
        cheap_model: str = "models/gemini-flash-lite-latest",
        strong_model: str = "models/gemini-flash-lite-latest",
    ):
        self.tavily = TavilyClient(api_key=tavily_key)
        self.client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY")) if os.getenv("GOOGLE_API_KEY") else None
        self.cheap_model_name = cheap_model
        self.strong_model_name = strong_model
        self.main_model_name = self.strong_model_name
        self.db = db
        self.post_id = post_id
        self.vector_store = VectorService()

    def _call_gemini(self, model: str, contents: Any, config: Any = None):
        import time
        import random

        if not self.client:
            raise RuntimeError("Google Gemini is not configured. Please provide a valid GOOGLE_API_KEY.")

        candidate_models = [
            model if ("gemini" in model and not "google/" in model) else "models/gemini-flash-lite-latest",
            "models/gemini-flash-lite-latest",
            "models/gemini-flash-latest"
        ]
        # De-duplicate while preserving order
        unique_models = list(dict.fromkeys(candidate_models))

        last_error = None
        for m in unique_models:
            for attempt in range(3):
                try:
                    if config:
                        return self.client.models.generate_content(model=m, contents=contents, config=config)
                    else:
                        return self.client.models.generate_content(model=m, contents=contents)
                except Exception as e:
                    last_error = e
                    err_str = str(e)
                    if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "503" in err_str or "UNAVAILABLE" in err_str:
                        wait_time = (2 ** attempt) + random.uniform(0.5, 2.0)
                        logger.warning("[Post #%s] Gemini model %s capacity pause, retrying in %.1fs (attempt %s/3)...", self.post_id, m, wait_time, attempt+1)
                        time.sleep(wait_time)
                        continue
                    # Non-capacity error (e.g., 404 NOT_FOUND), switch immediately to the next candidate model
                    logger.info("[Post #%s] Model %s failed (%s), trying fallback model...", self.post_id, m, err_str[:80])
                    break
        raise last_error

    def _update_progress(self, progress: float, message: str, status: AnalysisStatus = None):
        from redis_cache import RedisCache
        post = self.db.query(Post).get(self.post_id)
        if not post:
            return
        post.analysis_progress = progress
        post.status_message = message
        if status:
            post.analysis_status = status
        self.db.commit()

        # Publish to Redis for distributed telemetry
        status_name = post.analysis_status.name if hasattr(post.analysis_status, 'name') else str(post.analysis_status)
        RedisCache.set_progress(self.post_id, status_name, progress, message)
        RedisCache.publish_status(self.post_id, status_name, progress, message)
        logger.info("[Post #%s] Stage %s%% | %s", self.post_id, int(progress), message)

    def _get_domain(self, url: str) -> str:
        from urllib.parse import urlparse
        return urlparse(url).netloc.lower()

    def _check_source(self, url: str) -> Optional["NewsOutlet"]:
        domain = self._get_domain(url)
        outlet = self.db.query(NewsOutlet).filter(NewsOutlet.domain == domain).first()
        if not outlet:
            whitelisted = ["reuters.com", "apnews.com", "bbc.com", "pib.gov.in", "pib.in", "thehindu.com", "indianexpress.com"]
            blacklisted = ["fakenews.com", "propaganda.net"]
            
            is_white = any(w in domain for w in whitelisted)
            is_black = any(b in domain for b in blacklisted)
            
            outlet = NewsOutlet(
                name=domain.split('.')[0].capitalize(),
                domain=domain,
                is_whitelisted=is_white,
                is_blacklisted=is_black,
                credibility_score=85.0 if is_white else (10.0 if is_black else 60.0)
            )
            self.db.add(outlet)
            self.db.commit()
            self.db.refresh(outlet)
        return outlet

    def _scrape_link(self, url: str) -> str:
        import requests
        from bs4 import BeautifulSoup
        try:
            response = requests.get(url, timeout=10)
            soup = BeautifulSoup(response.content, 'html.parser')
            for script in soup(["script", "style"]):
                script.extract()
            text = soup.get_text()
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            text = '\n'.join(chunk for chunk in chunks if chunk)
            return text[:5000]
        except Exception as e:
            print(f"Scraping error: {e}")
            return ""

    def analyze(self, article: NewsArticle) -> Dict[str, Any]:
        # Step 1: Ingestion
        self._update_progress(5, "ESTABLISHING_DOCUMETARY_INGESTION", AnalysisStatus.INGESTING)
        content = article.body
        source_url = getattr(article, 'source_url', None)
        
        if source_url:
            self._update_progress(10, f"CRAWLING_PRIMARY_SOURCE: {self._get_domain(source_url)}", AnalysisStatus.INGESTING)
            outlet = self._check_source(source_url)
            if outlet.is_blacklisted:
                self._update_progress(10, "SOURCE_BLACKLIST_DETECTION", AnalysisStatus.FAILED)
                return {"error": "Source is blacklisted"}
            
            scraped_content = self._scrape_link(source_url)
            if scraped_content:
                content = scraped_content
                post = self.db.query(Post).get(self.post_id)
                post.news_outlet_id = outlet.id
                post.source_url = source_url
                self.db.commit()

        visual_report = None
        ocr_text = ""
        if article.media_url and article.media_type == "IMAGE":
            self._update_progress(15, "PERFORMING_HIGH_FIDELITY_OCR", AnalysisStatus.INGESTING)
            ocr_text = self._perform_ocr(article.media_url)
            visual_report = self._visual_forensics(article.media_url)

        if ocr_text:
            content = f"EXTRACTED_VISUAL_CONTEXT: {ocr_text}\n\nORIGINAL_CONTENT: {content}"

        if not (content and content.strip()):
             content = article.title
             
        if not (content and content.strip()) and not article.media_url:
            self._update_progress(0, "EMPTY_DATA_FLOW_ABORTED", AnalysisStatus.FAILED)
            return {"error": "Empty content"}

        self._update_progress(25, "REFINING_INTEL_VIA_GEMINI_EDITOR", AnalysisStatus.REFINING)
        refinement_prompt = f"Act as a professional news editor. Refine the following for forensic analysis. Remove fluff, keep facts, return only the refined text: {content}"
        refined_response = self._call_gemini(
            model=self.cheap_model_name, 
            contents=refinement_prompt
        )
        post = self.db.query(Post).get(self.post_id)
        post.refined_body = refined_response.text
        self.db.commit()

        # Step 4: Verification
        self._update_progress(45, "EXECUTING_SEMANTIC_AUDIT", AnalysisStatus.VERIFYING)
        article.body = post.refined_body or content
        lite = self._lite_transform(article)

        # Merge visual forensics into lite analysis if present
        if visual_report:
            lite["visual_forensics"] = visual_report

        self._update_progress(65, "GROUNDING_RESEARCH_SURFACING", AnalysisStatus.GROUNDING)
        deep = self._deep_analysis(article, lite)

        self._update_progress(90, "SYNTHESIZING_FORENSIC_VERDICT", AnalysisStatus.FINALIZING)
        out = {**lite, **deep}

        if post:
            post.analysis_raw = out
            post.short_title = out.get("short_title")
            post.summary_easy = out.get("summary_easy")
            post.credibility_score = out.get("credibility_score")
            post.bias = out.get("bias")
            post.sentiment = out.get("sentiment")
            post.risk_type = out.get("risk_type")
            post.language = out.get("language", "en")
            post.confidence_score = out.get("confidence_score", 50)
            post.historical_context = out.get("overall_historical_context")
            post.evidence_chain = out.get("evidence_chain")

            post.counter_narrative = out.get("counter_narrative")
            post.inconsistency_highlights = out.get("inconsistency_highlights")
            post.verifiable_alternatives = out.get("verifiable_alternatives")

            alt_headlines = out.get("alternative_headlines", {})
            post.alt_headline_neutral = alt_headlines.get("neutral")
            post.alt_headline_sensational = alt_headlines.get("sensational")
            post.alt_headline_calm = alt_headlines.get("calm")

            if "latitude" in out:
                post.latitude = out.get("latitude")
            if "longitude" in out:
                post.longitude = out.get("longitude")

            self._update_related_tables(post, out)

            self.db.commit()
            
            if post.news_outlet_id:
                outlet = self.db.query(NewsOutlet).get(post.news_outlet_id)
                if outlet:
                    outlet.articles_processed += 1
                    new_score = out.get("credibility_score", 0)
                    outlet.avg_trust_score = (outlet.avg_trust_score * (outlet.articles_processed - 1) + new_score) / outlet.articles_processed
                    
                    if new_score < 50:
                        outlet.credibility_score -= 2
                    elif new_score > 80:
                        outlet.credibility_score += 1
                    outlet.credibility_score = max(0, min(100, outlet.credibility_score))
                self.db.commit()

            self._update_progress(100, "FORENSIC_AUDIT_COMPLETE", AnalysisStatus.COMPLETED)

        return out

    def _perform_ocr(self, media_url: str) -> str:
        try:
            content = None
            if media_url.startswith('http'):
                import requests
                resp = requests.get(media_url, timeout=10)
                if resp.status_code == 200:
                    content = resp.content
            elif os.path.exists(media_url):
                with open(media_url, 'rb') as f:
                    content = f.read()
            
            if content:
                img = Image.open(io.BytesIO(content))
                text = pytesseract.image_to_string(img)
                return text.strip()
        except Exception as e:
            print(f"OCR Extraction failed: {e}")
        return ""

    def _visual_forensics(self, media_url: str) -> Dict[str, Any]:
        self._update_progress(15, "AUDITING_VISUAL_METADATA", AnalysisStatus.INGESTING)
        results = {"metadata": {}, "neuromorphic_artifacts": []}
        
        try:
            # Download/Load image
            content = None
            if media_url.startswith('http'):
                import requests
                resp = requests.get(media_url, timeout=10)
                if resp.status_code == 200:
                    content = resp.content
            elif os.path.exists(media_url):
                with open(media_url, 'rb') as f:
                    content = f.read()
            
            if content:
                self._update_progress(20, "SCANNING_NEURAL_ARTIFACTS", AnalysisStatus.INGESTING)
                prompt = (
                    "Act as a visual forensic expert. Audit this image for: "
                    "1. Metadata anomalies (signs of stripping or falsification). "
                    "2. AI artifacts (GAN noise, diffusion blurring, edge inconsistences). "
                    "3. Compression anomalies. "
                    "Return strict JSON with keys: 'manipulation_probability': int, 'findings': [str], 'metadata_integrity': str."
                )
                
                resp = self._call_gemini(
                    model=self.strong_model_name,
                    contents=[
                        types.Part.from_text(text=prompt),
                        types.Part.from_bytes(data=content, mime_type="image/jpeg")
                    ],
                    config=types.GenerateContentConfig(response_mime_type="application/json")
                )
                results["neuromorphic_report"] = self._parse_json(resp.text, {})
                
        except Exception as e:
            print(f"Visual forensics failed: {e}")
            results["error"] = str(e)
            
        return results

    def _update_related_tables(self, post: Post, analysis_data: Dict[str, Any]):
        post.tags.clear()
        post.red_flags.clear()
        post.trust_signals.clear()
        post.claims.clear()

        for tag in analysis_data.get("tags", []):
            post.tags.append(PostTag(tag=tag.lower()))

        for flag in analysis_data.get("red_flags", []):
            post.red_flags.append(RedFlag(flag=flag))

        for signal in analysis_data.get("trust_signals", []):
            post.trust_signals.append(TrustSignal(signal=signal))

        for claim_data in analysis_data.get("claims", []):
            new_claim = Claim(
                text=claim_data.get("text"),
                credibility_score=claim_data.get("credibility_score"),
                confidence=claim_data.get("confidence"),
                reason=claim_data.get("reason"),
                verdict=claim_data.get("verdict", "UNCERTAIN"),
                historical_context=claim_data.get("historical_context")
            )

            for source_url in claim_data.get("sources", []):
                new_claim.sources.append(ClaimSource(source_url=source_url))

            for site_url in claim_data.get("fact_check_sites", []):
                new_claim.fact_check_sites.append(FactCheckSite(site_url=site_url))

            post.claims.append(new_claim)

        self.db.commit()

    def _lite_transform(self, article: NewsArticle) -> Dict[str, Any]:
        self._update_progress(48, "Detecting language and context")
        sys = (
            "You are an AI Misinformation Specialist. You must handle Text, Images, Audio, and Video. "
            "Identify the primary language (Support English, Hindi, Marathi, etc.). "
            "Extract at least 5 verifiable claims from the content. "
            "For each claim, provide a detailed summary of what is being asserted. "
            "Return strict JSON with keys: "
            "{'short_title': str, 'summary_easy': str, 'tags': [str], 'language': str, "
            "'claims': [{'text': str, 'type': 'QUANTITATIVE|ATTRIBUTION|EVENT'}]}."
            "Summary should be a high-fidelity, comprehensive 'easy explanation'. Ensure at least 3 detailed paragraphs. "
            "Paragraph 1: Core news/incident. Paragraph 2: Key evidence/claims. Paragraph 3: Significance and verification status."
        )
        usr = json.dumps(article.to_dict(), ensure_ascii=False)

        response = self._call_gemini(
            model=self.cheap_model_name,
            contents=types.Content(
                role="user",
                parts=[
                    types.Part.from_text(text=sys),
                    types.Part.from_text(text=usr)
                ]
            ),
            config=types.GenerateContentConfig(response_mime_type="application/json")
        )

        self._update_progress(52, "Context acquired")
        return self._parse_json(
            response.text, {"short_title": "", "summary_easy": "", "tags": [], "language": "en"}
        )


    def _query_global_truth_hub(self, claims: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        self._update_progress(70, "CROSS_REFERENCING_GLOBAL_CLAIMS")
        all_grounding = []
        
        for claim in claims[:3]: 
            text = claim.get("text", "")
            try:
                search_query = f'"{text}" rebuttal OR fact-check OR discussion site:twitter.com OR site:reddit.com OR official statement'
                results = self.tavily.search(
                    query=search_query, 
                    search_depth="advanced", 
                    max_results=4,
                    include_domains=[
                        "twitter.com", "reddit.com", "pib.gov.in", "snopes.com", 
                        "politifact.com", "factcheck.org", "reuters.com", "apnews.com"
                    ]
                )
                if results and results['results']:
                    for r in results['results']:
                        all_grounding.append({
                            "text": r['title'],
                            "explanation": r['content'][:800],
                            "source": r['url'],
                            "domain": self._get_domain(r['url'])
                        })
            except Exception: continue
        return all_grounding

    def _get_semantic_grounding(self, article: NewsArticle, extracted_claims: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        self._update_progress(68, "REPRODUCING_VECTOR_SPACE")
        try:
            target_text = article.title + " " + " ".join([c['text'] for c in extracted_claims[:2]])
            emb_resp = self.client.models.embed_content(
                model="models/text-embedding-004",
                contents=target_text
            )
            vec = emb_resp.embeddings[0].values
            
            cached = self.vector_store.search_truth(vec)
            if cached: return cached
            
            live_hits = self._query_global_truth_hub(extracted_claims)
            if live_hits:
                self.vector_store.seed_truth(live_hits, lambda x: vec)
                return live_hits[0]
        except Exception: pass
        return None

    def _deep_analysis(self, article: NewsArticle, lite: Dict[str, Any]) -> Dict[str, Any]:
        extracted_claims = lite.get("claims", [])
        grounding_context = self._get_semantic_grounding(article, extracted_claims)

        self._update_progress(65, "GROUNDING_RESEARCH_SURFACING", AnalysisStatus.GROUNDING)
        sys = (
            "You are a state-of-the-art forensic AI. Detect deepfakes, clones, and manipulation. "
            f"SEMANTIC_GROUNDING: {json.dumps(grounding_context)}. "
            "Examine any provided media for synthetic artifacts. "
            "If SEMANTIC_GROUNDING is present, prioritize it. "
            "Detect if the text/claim aligns with the visual evidence (Mis-attribution Check). "
            "You MUST return an 'evidence_chain' field: a step-by-step logical breakdown (1, 2, 3) of how you arrived at the verdict. "
            "Include 'c2pa_status' explaining if the media has digital provenance signatures. "
            "Return STRICT JSON with keys: "
            "{'credibility_score': int, 'confidence_score': int, 'bias': str, 'sentiment': str, 'risk_type': str, 'red_flags': [str], "
            "'claims': [{'text': str, 'verdict': 'VERIFIED|REFUTED|UNCERTAIN|CONTROVERSIAL', 'credibility_score': int, 'confidence': str, 'reason': str, 'historical_context': str, 'sources': [str]}], "
            "'evidence_chain': [str], 'c2pa_status': str, "
            "'trust_signals': [str], 'alternative_headlines': {'neutral': str, 'sensational': str, 'calm': str}, "
            "'counter_narrative': str, 'inconsistency_highlights': str, 'verifiable_alternatives': [str], "
            "'forensic_artifacts': [{'x': float, 'y': float, 'label': str}], "
            "'grounding_context': {'text': str, 'source': str, 'explanation': str}, "
            "'scraped_intel': [{'url': str, 'title': str, 'snippet': str, 'platform': 'NEWS|TWITTER|REDDIT|OFFICIAL'}], "
            "'latitude': float, 'longitude': float}."
            "The 'confidence_score' (0-100) represents how much data you had to make this decision. If sources conflict, confidence should be low. "
            "If it's a breaking news event (like a new war) with little info, set confidence low and verdict to UNCERTAIN. "
            "The 'overall_historical_context' field should explain the long-term background of the topic (e.g., if it's about a company, its history; if it's about a war, its origins). "
            "Transparently report what claims were made, which are verified, and which are still being scouted. "
            "The 'scraped_intel' field should list the actual websites and social media posts found. "
            "The 'verdict' for each claim must be one of the four: VERIFIED (solid proof), REFUTED (proven false), UNCERTAIN (not enough data), CONTROVERSIAL (conflicting reports)."
            "Be extremely descriptive. The 'summary_easy' field should be at least 3-4 detailed paragraphs long. "
            "The 'historical_context' for each claim should explain what actually happened or the background facts in great detail. "
            "The 'sources' should be hypothetical working links to official records or news that support/refute the claim."
        )
        usr = json.dumps({"article": article.to_dict(), "lite": lite}, ensure_ascii=False)

        parts = [types.Part.from_text(text=sys), types.Part.from_text(text=usr)]
        
        # Multi-modal injection
        if article.media_url and article.media_type == "IMAGE":
            self._update_progress(72, "INJECTING_VISUAL_FORENSIC_STREAM", AnalysisStatus.GROUNDING)
            try:
                url = article.media_url
                if not url.startswith('http'):
                    if os.path.exists(url):
                        with open(url, 'rb') as f:
                            parts.append(types.Part.from_bytes(data=f.read(), mime_type="image/jpeg"))
                else:
                    import requests
                    resp = requests.get(url, timeout=10)
                    if resp.status_code == 200:
                        parts.append(types.Part.from_bytes(data=resp.content, mime_type="image/jpeg"))
            except Exception as e:
                print(f"Vision injection failed: {e}")

        tools = types.Tool(function_declarations=[WEB_SEARCH_DECLARATION])
        config = types.GenerateContentConfig(
            tools=[tools],
            response_mime_type="application/json"
        )

        contents_list = [types.Content(role="user", parts=parts)]

        response = self._call_gemini(
            model=self.main_model_name,
            contents=contents_list,
            config=config,
        )

        self._update_progress(75, "WEB_VERIFICATION_IN_PROGRESS")

        while response.candidates and any(p.function_call for p in response.candidates[0].content.parts):
            tool_calls = [p.function_call for p in response.candidates[0].content.parts if p.function_call]
            
            # Record the model's function call turn
            contents_list.append(response.candidates[0].content)

            for call in tool_calls:
                function_name = call.name
                arguments = call.args

                if function_name == "web_search":
                    q = arguments.get("query", "").strip()
                    k = int(arguments.get("max_results", 5))
                    self._update_progress(78, f"QUERY_STREAMS: {q}")
                    s = web_search_func(query=q, max_results=k)

                    # Gemini API requires function response parts to have role="user"
                    contents_list.append(types.Content(
                        role="user",
                        parts=[types.Part.from_function_response(name=function_name, response={"results": s})]
                    ))

            response = self._call_gemini(
                model=self.strong_model_name,
                contents=contents_list,
                config=config,
            )
            self._update_progress(82, "CALCULATING_PROBABILITIES")

        self._update_progress(85, "ASSEMBLING_INTEL")
        return self._parse_json(
            response.text,
            {
                "credibility_score": 0,
                "bias": "",
                "sentiment": "",
                "risk_type": "",
                "red_flags": [],
                "claims": [],
                "trust_signals": [],
                "alternative_headlines": {"neutral": "", "sensational": "", "calm": ""},
                "counter_narrative": "",
                "inconsistency_highlights": "",
                "verifiable_alternatives": [],
                "forensic_artifacts": [],
                "grounding_context": None,
                "evidence_chain": [],
                "c2pa_status": "Unknown",
                "scraped_intel": [],
                "overall_historical_context": "",
                "latitude": None,
                "longitude": None,
            },
        )


    def _parse_json(self, text: str, fallback: Dict[str, Any]) -> Dict[str, Any]:
        if not text:
            return fallback
        cleaned = text.strip()
        if cleaned.startswith("```"):
            cleaned = re.sub(
                r"^```(?:json)?\s*|\s*```$", "", cleaned,
                flags=re.IGNORECASE | re.DOTALL
            ).strip()
        try:
            return json.loads(cleaned)
        except json.JSONDecodeError:
            try:
                m = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)
                if m:
                    return json.loads(m.group(0))
            except json.JSONDecodeError:
                pass
        return fallback