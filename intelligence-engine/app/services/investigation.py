import uuid
import json
import urllib.parse
import urllib.request
from datetime import datetime
from sqlalchemy.orm import Session
from loguru import logger
from sqlalchemy import Column, String, ForeignKey, DateTime, Float
from app.models.database import Base, engine, CandidateItem, InvestigationInput, SubmittedUrl
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

def run_investigation(db: Session, depth_limit: int = 3):
    logger.info(f"Starting Recursive Investigation (Depth Limit: {depth_limit})...")
    claims = db.query(Claim).filter(Claim.status == "selected").limit(5).all()
    
    investigated = 0
    discovered_urls = []
    
    for claim in claims:
        # 1. Investigation Planning
        prompt = f"Given this claim: '{claim.claim_text}', generate 3 to 5 targeted search queries to find evidence. Return ONLY a JSON object with 'queries' (list of strings)."
        response = query_llm(prompt, system_prompt="You generate targeted search queries. Output JSON only.")
        queries = [claim.claim_text] # fallback
        try:
            if response:
                result = json.loads(response)
                queries = result.get("queries", [claim.claim_text])
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
                
                # LAYER 6: RECURSIVE DISCOVERY
                # Extract URLs from the evidence text
                ext_prompt = f"Extract all cited URLs or referenced sources from this text. Return ONLY a JSON object with 'urls' (list of absolute url strings).\nText: {text[:2000]}"
                url_resp = query_llm(ext_prompt, system_prompt="You extract URLs. Output JSON only.")
                try:
                    if url_resp:
                        url_res = json.loads(url_resp)
                        for new_url in url_res.get("urls", []):
                            if new_url.startswith("http"):
                                discovered_urls.append(new_url)
                except Exception:
                    pass
            else:
                task.status = "failed"
                
            db.commit()
            
        claim.status = "investigated"
        db.commit()
        
    # Process Recursive Discovery
    new_candidates = 0
    for url in set(discovered_urls):
        # Check if already processed in SubmittedUrl
        exists = db.query(SubmittedUrl).filter(SubmittedUrl.url == url).first()
        if not exists:
            # Create new InvestigationInput for the recursive link
            new_input_id = str(uuid.uuid4())
            new_input = InvestigationInput(
                id=new_input_id,
                input_type="url",
                status="pending",
                notes=f"Recursively discovered from depth {depth_limit}",
                created_at=datetime.utcnow()
            )
            db.add(new_input)
            
            # Attach the URL
            submitted_url = SubmittedUrl(
                id=str(uuid.uuid4()),
                input_id=new_input_id,
                url=url
            )
            db.add(submitted_url)
            new_candidates += 1
            
    db.commit()
    logger.info(f"Investigation complete. Collected {investigated} pieces of evidence.")
    logger.info(f"Layer 6 Recursive Discovery generated {new_candidates} new investigation inputs.")
    return investigated
