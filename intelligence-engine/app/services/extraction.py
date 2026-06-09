import uuid
from sqlalchemy.orm import Session
from loguru import logger
from sqlalchemy import Column, String, Float, ForeignKey
from app.models.database import Base, CandidateItem, InvestigationInput, OriginalPost, engine
from app.core.llm import query_llm

class Claim(Base):
    __tablename__ = "claims"
    id = Column(String, primary_key=True, index=True)
    candidate_id = Column(String, ForeignKey("candidate_items.id"), nullable=True)
    input_id = Column(String, ForeignKey("investigation_inputs.id"), nullable=True)
    claim_text = Column(String)
    claim_type = Column(String)
    confidence = Column(Float, nullable=True)
    status = Column(String, default="selected")

Base.metadata.create_all(bind=engine)

def extract_claims(db: Session):
    logger.info("Starting claim extraction...")
    
    extracted_count = 0
    
    # 1. Process Human-Guided Investigation Inputs
    pending_inputs = db.query(InvestigationInput).filter(InvestigationInput.status == "pending").all()
    for inv_input in pending_inputs:
        logger.info(f"Extracting claims for Human Input ID: {inv_input.id}")
        
        # Gather text from OriginalPost and comments
        post = db.query(OriginalPost).filter(OriginalPost.input_id == inv_input.id).first()
        content = post.content if post else inv_input.notes or ""
        
        prompt = f"Extract the core factual claims from this text. Return a list of claims separated by the '|' character. Text: {content}"
        response = query_llm(prompt, system_prompt="You extract factual, verifiable claims from text.")
        
        if response:
            claims_text = response.split("|")
            for ct in claims_text:
                if ct.strip():
                    new_claim = Claim(
                        id=str(uuid.uuid4()),
                        input_id=inv_input.id,
                        claim_text=ct.strip(),
                        claim_type="explicit"
                    )
                    db.add(new_claim)
                    extracted_count += 1
        
        inv_input.status = "running"
        db.commit()

    # 2. Process Autonomous Discovery Candidates (Optional Module)
    top_candidates = db.query(CandidateItem).filter(CandidateItem.status == "ranked").order_by(CandidateItem.opportunity_score.desc()).limit(5).all()
    
    for item in top_candidates:
        logger.info(f"Extracting claims for Discovery Candidate: {item.title}")
        prompt = f"Extract the core factual claims from this text. Return a list of claims separated by the '|' character. Text: {item.clean_text}"
        response = query_llm(prompt, system_prompt="You extract factual, verifiable claims from text.")
        
        if response:
            claims_text = response.split("|")
            for ct in claims_text:
                if ct.strip():
                    new_claim = Claim(
                        id=str(uuid.uuid4()),
                        candidate_id=item.id,
                        claim_text=ct.strip(),
                        claim_type="explicit"
                    )
                    db.add(new_claim)
                    extracted_count += 1
        
        item.status = "investigated"
        
    db.commit()
    logger.info(f"Extraction complete. Extracted {extracted_count} claims from {len(top_candidates)} items.")
    return extracted_count
