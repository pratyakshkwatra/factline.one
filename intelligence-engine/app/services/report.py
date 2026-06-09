import uuid
from sqlalchemy.orm import Session
from loguru import logger
from sqlalchemy import Column, String, ForeignKey, Text
from app.models.database import Base, CandidateItem, engine
from app.services.extraction import Claim
from app.core.llm import query_llm

class Report(Base):
    __tablename__ = "reports"
    id = Column(String, primary_key=True, index=True)
    candidate_id = Column(String, ForeignKey("candidate_items.id"))
    title = Column(String)
    summary = Column(Text)
    verdict = Column(String)
    public_url = Column(String, nullable=True)

Base.metadata.create_all(bind=engine)

def generate_reports(db: Session):
    logger.info("Starting report generation...")
    candidates = db.query(CandidateItem).filter(CandidateItem.status == "investigated").all()
    
    generated = 0
    for item in candidates:
        claims = db.query(Claim).filter(Claim.candidate_id == item.id).all()
        if not claims:
            continue
            
        claims_text = "\n".join([f"- {c.claim_text}" for c in claims])
        prompt = f"Generate a short fact-checking report for the following claims:\n{claims_text}\n\nInclude a title, summary, and a final verdict (Verified, Likely True, Uncertain, Likely False, False). Format as JSON with keys 'title', 'summary', 'verdict'."
        response = query_llm(prompt, system_prompt="You are an expert fact-checker. Output ONLY valid JSON.")
        
        try:
            if response:
                import json
                res = json.loads(response)
                title = res.get("title")
                summary = res.get("summary")
                verdict = res.get("verdict")
                
                if title and summary and verdict:
                    report = Report(id=str(uuid.uuid4()), candidate_id=item.id, title=title, summary=summary, verdict=verdict)
                    db.add(report)
                    item.status = "reported"
                    generated += 1
                else:
                    logger.warning(f"Incomplete JSON from LLM: {response}")
            else:
                logger.warning("LLM response empty. Skipping report.")
        except Exception as e:
            logger.error(f"Failed to generate report: {e}")
        
    db.commit()
    logger.info(f"Report generation complete. Generated {generated} reports.")
    return generated
