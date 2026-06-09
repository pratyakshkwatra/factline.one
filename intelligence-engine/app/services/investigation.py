import uuid
import json
import urllib.parse
import urllib.request
from datetime import datetime
from sqlalchemy.orm import Session
from loguru import logger
from sqlalchemy import Column, String, ForeignKey, DateTime, Float
from app.models.database import Base, engine, CandidateItem
from app.services.extraction import Claim
from app.core.llm import query_llm
from app.services.browser import collect_evidence_from_url

class InvestigationTask(Base):
    __tablename__ = "investigation_tasks"
    id = Column(String, primary_key=True, index=True)
    claim_id = Column(String, ForeignKey("claims.id"))
    search_query = Column(String)
    status = Column(String)

class Evidence(Base):
    __tablename__ = "evidence"
    id = Column(String, primary_key=True, index=True)
    claim_id = Column(String, ForeignKey("claims.id"))
    url = Column(String)
    extracted_text = Column(String)
    source_score = Column(Float, nullable=True)
    screenshot_path = Column(String, nullable=True)
    html_path = Column(String, nullable=True)
    collection_timestamp = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

def calculate_source_score(url: str) -> float:
    domain = urllib.parse.urlparse(url).netloc.lower()
    tier_1 = ["reuters.com", "apnews.com", "bbc.co.uk", "gov"]
    tier_2 = ["techcrunch.com", "theverge.com", "arstechnica.com"]
    authority_score = 0.5 
    if any(t in domain for t in tier_1):
        authority_score = 1.0
    elif any(t in domain for t in tier_2):
        authority_score = 0.8
    recency_score = 1.0 
    corroboration_score = 0.5 
    overall = (authority_score * 0.5) + (recency_score * 0.3) + (corroboration_score * 0.2)
    return round(overall, 2)

def parse_reddit_comments(url: str, claim_id: str, db: Session):
    if not url.endswith('/'):
        url += '/'
    json_url = f"{url}.json"
    logger.info(f"Parsing Reddit comments for recursive evidence: {json_url}")
    try:
        req = urllib.request.Request(json_url, headers={'User-Agent': 'FactlineBot/3.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            if len(data) < 2:
                return
            comments = data[1].get("data", {}).get("children", [])
            comment_texts = []
            for c in comments[:10]:
                body = c.get("data", {}).get("body", "")
                if body:
                    comment_texts.append(body)
            combined_comments = "\n---\n".join(comment_texts)
            if not combined_comments:
                return
            
            prompt = f"Analyze these Reddit comments discussing a claim. Extract supporting arguments, contradicting arguments, expert commentary, and cited links (URLs). Return ONLY valid JSON with keys: 'supporting', 'contradicting', 'expert', 'links' (list of urls).\n\nComments:\n{combined_comments}"
            response_llm = query_llm(prompt, system_prompt="You extract arguments and URLs from comments. Output JSON only.")
            
            try:
                if response_llm:
                    result = json.loads(response_llm)
                    links = result.get("links", [])
                    if isinstance(links, list):
                        for link in links:
                            if isinstance(link, str) and link.startswith("http"):
                                logger.info(f"Found recursive Reddit link: {link}")
                                task = InvestigationTask(id=str(uuid.uuid4()), claim_id=claim_id, search_query=f"Reddit Citation: {link}", status="planned")
                                db.add(task)
                                db.commit()
                                
                                title, text, html, screenshot = collect_evidence_from_url(link, task.id)
                                if text:
                                    score = calculate_source_score(link)
                                    evidence = Evidence(
                                        id=str(uuid.uuid4()), 
                                        claim_id=claim_id, 
                                        url=link, 
                                        extracted_text=f"Reddit Cited Source\n\n{text[:2000]}",
                                        source_score=score,
                                        html_path=html,
                                        screenshot_path=screenshot,
                                        collection_timestamp=datetime.utcnow()
                                    )
                                    db.add(evidence)
                                    task.status = "completed"
                                else:
                                    task.status = "failed"
                                db.commit()
            except Exception as e:
                logger.error(f"Failed to parse LLM comment extraction: {e}")
    except Exception as e:
        logger.error(f"Failed to fetch Reddit comments: {e}")

def run_investigation(db: Session):
    logger.info("Starting investigation planning and evidence collection...")
    claims = db.query(Claim).limit(5).all()
    
    investigated = 0
    for claim in claims:
        # Check if candidate is from Reddit for recursive comment parsing
        candidate = db.query(CandidateItem).filter(CandidateItem.id == claim.candidate_id).first()
        if candidate and candidate.source_type == "reddit":
            parse_reddit_comments(candidate.url, claim.id, db)
            
        # 1. Investigation Planning
        prompt = f"Given this claim: '{claim.claim_text}', generate 3 to 5 targeted search queries to find evidence verifying or refuting it. Return ONLY a valid JSON object with key 'queries' containing a list of strings."
        response = query_llm(prompt, system_prompt="You generate targeted search queries. Output JSON only.")
        queries = [claim.claim_text] # fallback
        try:
            if response:
                result = json.loads(response)
                queries = result.get("queries", [claim.claim_text])
                if not isinstance(queries, list):
                    queries = [claim.claim_text]
        except Exception as e:
            logger.warning(f"Failed to parse investigation queries LLM JSON: {e}")
            
        for query in queries[:5]:
            task = InvestigationTask(id=str(uuid.uuid4()), claim_id=claim.id, search_query=query, status="planned")
            db.add(task)
            db.commit()
            
            # 2. Evidence Collection
            logger.info(f"Executing search via Playwright for query: {query}")
            search_url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote(query)}"
            title, text, html, screenshot = collect_evidence_from_url(search_url, task.id)
            
            if text:
                score = calculate_source_score(search_url)
                evidence = Evidence(
                    id=str(uuid.uuid4()), 
                    claim_id=claim.id, 
                    url=search_url, 
                    extracted_text=text[:2000],
                    source_score=score,
                    html_path=html,
                    screenshot_path=screenshot,
                    collection_timestamp=datetime.utcnow()
                )
                db.add(evidence)
                task.status = "completed"
                investigated += 1
            else:
                task.status = "failed"
                
            db.commit()
        
    logger.info(f"Investigation phase complete. Collected evidence for {investigated} search queries.")
    return investigated
