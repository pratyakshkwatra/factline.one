import json
from sqlalchemy.orm import Session
from loguru import logger
from app.models.database import CandidateItem
from app.core.llm import query_llm

def score_reddit_candidate(item: CandidateItem) -> float:
    meta = item.source_metadata or {}
    
    score_vel = meta.get("score_velocity", 0)
    comment_vel = meta.get("comment_velocity", 0)
    upvote_ratio = meta.get("upvote_ratio", 1.0)
    crossposts = meta.get("num_crossposts", 0)
    cat_weight = meta.get("category_weight", 1.0)
    
    # Controversy: low upvote ratio but high comment velocity implies intense debate
    controversy_modifier = 1.2 if (upvote_ratio < 0.8 and comment_vel > 10) else 1.0
    
    # Base heuristic out of 10
    base_score = min((score_vel * 0.05) + (comment_vel * 0.2) + (crossposts * 1.5), 8.0)
    
    final_score = base_score * controversy_modifier * cat_weight
    return min(round(final_score, 2), 10.0)

def rank_candidates(db: Session):
    logger.info("Ranking newly discovered candidates...")
    items = db.query(CandidateItem).filter(CandidateItem.status == "discovered").all()
    
    ranked_count = 0
    for item in items:
        # Custom Reddit Scoring Logic
        if item.source_type == "reddit":
            score = score_reddit_candidate(item)
            item.opportunity_score = score
        else:
            # Standard LLM Scoring for RSS
            prompt = f"Evaluate this news item for intelligence potential from 0 to 10. Title: '{item.title}'. Description: '{item.content}'. Return ONLY a valid JSON object with key 'score'."
            response = query_llm(prompt, system_prompt="You are an intelligence ranking engine. Output JSON only.")
            score = 5.0
            try:
                if response:
                    result = json.loads(response)
                    score = float(result.get("score", 5.0))
            except Exception as e:
                logger.warning(f"Failed to parse ranking LLM JSON: {e}") 
            item.opportunity_score = score
            
        item.status = "ranked"
        ranked_count += 1
        
    db.commit()
    logger.info(f"Ranking complete. Scored {ranked_count} items.")
    return ranked_count
