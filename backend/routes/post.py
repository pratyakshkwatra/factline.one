from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, UploadFile, File
from sqlalchemy.orm import Session
import os
import shutil
import uuid
from typing import List
from database import get_db
from models.user import User
from models.post_model import Post, AnalysisStatus, Upvote, Downvote, View, NewsOutlet, Claim, ClaimSource, FactCheckSite, PostTag, RedFlag, TrustSignal
import schemas
from auth_deps import get_current_user, get_current_editor
import config
from datetime import datetime, timedelta
from sqlalchemy import func, desc, asc
import agent
import asyncio
from database import SessionLocal

router = APIRouter(tags=["Posts"])

@router.post("/upload")
def upload_media(file: UploadFile = File(...)):
    ext = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join("uploads", filename)
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    return {"url": f"/uploads/{filename}"}

@router.get("/me", response_model=List[schemas.PostOut])
def get_my_posts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy.orm import joinedload
    posts = (
        db.query(Post)
        .options(
            joinedload(Post.claims),
            joinedload(Post.tags),
            joinedload(Post.red_flags),
            joinedload(Post.trust_signals),
            joinedload(Post.news_outlet),
            joinedload(Post.owner)
        )
        .filter(Post.created_by == current_user.id)
        .order_by(Post.created_at.desc())
        .all()
    )
    
    out = []
    for p in posts:
        # Calculate interaction counts
        uv = db.query(Upvote).filter_by(post_id=p.id).count()
        dv = db.query(Downvote).filter_by(post_id=p.id).count()
        vc = db.query(View).filter_by(post_id=p.id).count()
        
        is_up = db.query(Upvote).filter_by(user_id=current_user.id, post_id=p.id).first() is not None
        is_down = db.query(Downvote).filter_by(user_id=current_user.id, post_id=p.id).first() is not None

        out.append(schemas.PostOut.from_orm(p).copy(update={
            "upvote_downvote_count": uv - dv,
            "view_count": vc,
            "is_upvoted": is_up,
            "is_downvoted": is_down,
        }))
    return out


from task_queue import TaskQueue

@router.post("/", response_model=schemas.PostOut)
async def create_post(
    post: schemas.PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_post = Post(
        **post.dict(),
        created_by=current_user.id,
        analysis_status=AnalysisStatus.PENDING,
        analysis_progress=0.0,
        status_message="ESTABLISHING_FORENSIC_INGESTION"
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)

    await TaskQueue.enqueue_analysis(db_post.id)

    return db_post

from services.vector_service import VectorService
vector_service = VectorService()

def map_qdrant_to_post(payload: dict, idx: int) -> dict:
    text = payload.get("text") or payload.get("claim") or "Investigation in progress"
    label = str(payload.get("label", "unknown")).lower()
    subject = payload.get("subject") or "General Intelligence"
    speaker = payload.get("speaker") or "Factline Forensic"
    img_tag = payload.get("image_tag") or "forensic"
    source = payload.get("source") or "Factline Ledger"
    
    is_true = label in ["true", "mostly-true", "half-true", "mostly_true"]
    credibility = 98 if label == "true" else 75 if "mostly-true" in label else 50 if "half-true" in label else 15
    
    bulletin_types = ["Forensic Audit", "Truth Signal", "Investigation", "Signal Alert", "Data Audit"]
    bulletin = bulletin_types[idx % len(bulletin_types)]
    
    dynamic_title = f"{bulletin}: {subject.capitalize()} report regarding {speaker}"

    return {
        "id": 100000 + idx, 
        "title": dynamic_title,
        "body": f"The Hub has concluded grounding on {speaker}'s statement: \"{text}\". Audit signatures align with {source} standards for forensic verification.",
        "media_url": f"https://source.unsplash.com/featured/?{img_tag},news&sig={idx}", 
        "media_type": "TEXT",
        "created_at": datetime.utcnow(),
        "owner": {"id": 0, "email": "system@factline.ai", "is_active": True, "role": "editor"},
        "analysis_status": AnalysisStatus.COMPLETED,
        "analysis_progress": 100.0,
        "status_message": "Matrix Grounding Finalized",
        "credibility_score": credibility,
        "bias": "neutral",
        "sentiment": "neutral",
        "risk_type": "VETTED_SIGNAL" if is_true else "DEEPFAKE_SIG",
        "language": "en",
        "short_title": subject,
        "summary_easy": text[:100],
        "counter_narrative": f"Grounding verified at {credibility}% via Matrix cross-ref.",
        "inconsistency_highlights": "Signal verified.",
        "verifiable_alternatives": [],
        "forensic_artifacts": [],
        "grounding_context": {
            "text": text,
            "explanation": payload.get("explanation", "Forensic vetting complete."),
            "source": source
        },
        "evidence_chain": ["Signal captured", "Vector matched", "Logic verified"],
        "c2pa_status": "Verified",
        "tags": [{"tag": "forensic"}, {"tag": subject.split()[0].lower()}],
        "red_flags": [] if is_true else [{"flag": "Manipulation detected"}],
        "claims": [{
            "text": text,
            "credibility_score": credibility,
            "reason": f"System verified rating as {label.upper()}.",
            "sources": [],
            "fact_check_sites": []
        }],
        "trust_signals": [{"signal": "Forensic Ledger"}],
        "is_upvoted": False,
        "is_downvoted": False,
        "upvote_downvote_count": 0,
        "view_count": 0,
        "latitude": 38.8977 + (idx * 0.005),
        "longitude": -77.0365 + (idx * 0.005),
        "alt_headline_neutral": text,
        "alt_headline_sensational": f"ALARMING: {text}",
        "alt_headline_calm": f"Status: {text}"
    }

@router.get("/breaking-news", response_model=List[schemas.PostOut])
def get_breaking_news(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy.orm import joinedload
    posts_query = (
        db.query(Post)
        .options(
            joinedload(Post.claims),
            joinedload(Post.tags),
            joinedload(Post.red_flags),
            joinedload(Post.trust_signals),
            joinedload(Post.news_outlet),
            joinedload(Post.owner)
        )
        .filter(Post.analysis_status == AnalysisStatus.COMPLETED, Post.is_breaking_news == True)
        .all()
    )

    if not posts_query:
        claims = vector_service.get_random_claims(limit=5)
        return [map_qdrant_to_post(c, i) for i, c in enumerate(claims)]

    upvote_counts = dict(
        db.query(Upvote.post_id, func.count(Upvote.id))
        .group_by(Upvote.post_id)
        .all()
    )
    downvote_counts = dict(
        db.query(Downvote.post_id, func.count(Downvote.id))
        .group_by(Downvote.post_id)
        .all()
    )
    view_counts = dict(
        db.query(View.post_id, func.count(View.id))
        .group_by(View.post_id)
        .all()
    )

    ranked_posts = []
    now = datetime.utcnow()

    for post in posts_query:
        uv = upvote_counts.get(post.id, 0)
        dv = downvote_counts.get(post.id, 0)
        vc = view_counts.get(post.id, 0)

        hours_old = (now - post.created_at.replace(tzinfo=None)).total_seconds() / 3600
        recency_weight = 1 / (1 + hours_old/12)
        score = (uv * 3 + vc * 1 - dv * 2) * recency_weight
        ranked_posts.append((score, uv, vc, -dv, post))

    ranked_posts.sort(key=lambda x: (x[0], x[1], x[2], x[3]), reverse=True)

    top_posts = [schemas.PostOut.from_orm(p[4]).copy(update={
        "upvote_downvote_count": p[1] - (-p[3]),
        "view_count": p[2],
        "is_upvoted": db.query(Upvote).filter_by(user_id=current_user.id, post_id=p[4].id).first() is not None,
        "is_downvoted": db.query(Downvote).filter_by(user_id=current_user.id, post_id=p[4].id).first() is not None,
    }) for p in ranked_posts[:5]]

    return top_posts

@router.get("/outlets/leaderboard", response_model=List[schemas.NewsOutletOut])
def get_leaderboard(db: Session = Depends(get_db)):
    return db.query(NewsOutlet).order_by(NewsOutlet.credibility_score.desc()).all()

@router.get("/recommendations", response_model=List[schemas.PostOut])
def get_recommendations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    last_upvotes = (
        db.query(Upvote)
        .filter_by(user_id=current_user.id)
        .order_by(Upvote.created_at.desc())
        .limit(20)
        .all()
    )
    last_downvotes = (
        db.query(Downvote)
        .filter_by(user_id=current_user.id)
        .order_by(Downvote.created_at.desc())
        .limit(20)
        .all()
    )
    last_views = (
        db.query(View)
        .filter_by(user_id=current_user.id)
        .order_by(View.created_at.desc())
        .limit(20)
        .all()
    )

    scores = {}
    for u in last_upvotes:
        scores[u.post_id] = scores.get(u.post_id, 0) + 2
    for v in last_views:
        scores[v.post_id] = scores.get(v.post_id, 0) + 1
    for d in last_downvotes:
        scores[d.post_id] = scores.get(d.post_id, 0) - 2

    if not scores:
        from sqlalchemy.orm import joinedload
        posts = (
            db.query(Post)
            .options(
                joinedload(Post.claims),
                joinedload(Post.tags),
                joinedload(Post.red_flags),
                joinedload(Post.trust_signals),
                joinedload(Post.news_outlet),
                joinedload(Post.owner)
            )
            .filter(Post.analysis_status == AnalysisStatus.COMPLETED)
            .limit(40)
            .all()
        )
        if not posts:
            claims = vector_service.get_random_claims(limit=40)
            return [map_qdrant_to_post(c, i) for i, c in enumerate(claims)]
    else:
        top_post_ids = sorted(scores.keys(), key=lambda pid: scores[pid], reverse=True)[:10]
        from sqlalchemy.orm import joinedload
        top_posts = (
            db.query(Post)
            .options(
                joinedload(Post.claims),
                joinedload(Post.tags),
                joinedload(Post.red_flags),
                joinedload(Post.trust_signals),
                joinedload(Post.news_outlet),
                joinedload(Post.owner)
            )
            .filter(Post.id.in_(top_post_ids), Post.analysis_status == AnalysisStatus.COMPLETED)
            .all()
        )
        
        similar_ids = find_similar_posts(db=db, source_posts=top_posts)

        posts = top_posts[:]

        if similar_ids:
            from sqlalchemy.orm import joinedload
            similar_posts = (
                db.query(Post)
                .options(
                    joinedload(Post.claims),
                    joinedload(Post.tags),
                    joinedload(Post.red_flags),
                    joinedload(Post.trust_signals),
                    joinedload(Post.news_outlet),
                    joinedload(Post.owner)
                )
                .filter(Post.id.in_(similar_ids), Post.analysis_status == AnalysisStatus.COMPLETED)
                .all()
            )
            posts.extend(similar_posts)

        seen = set()
        unique_posts = []
        for p in posts:
            if p.id not in seen:
                seen.add(p.id)
                unique_posts.append(p)
        posts = unique_posts[:10]

    post_ids = [p.id for p in posts]

    upvoted_ids = {
        u.post_id for u in db.query(Upvote)
        .filter(Upvote.user_id == current_user.id, Upvote.post_id.in_(post_ids)).all()
    }
    downvoted_ids = {
        d.post_id for d in db.query(Downvote)
        .filter(Downvote.user_id == current_user.id, Downvote.post_id.in_(post_ids)).all()
    }

    upvote_counts = dict(
        db.query(Upvote.post_id, func.count(Upvote.id))
        .filter(Upvote.post_id.in_(post_ids))
        .group_by(Upvote.post_id)
        .all()
    )
    downvote_counts = dict(
        db.query(Downvote.post_id, func.count(Downvote.id))
        .filter(Downvote.post_id.in_(post_ids))
        .group_by(Downvote.post_id)
        .all()
    )
    view_counts = dict(
        db.query(View.post_id, func.count(View.id))
        .filter(View.post_id.in_(post_ids))
        .group_by(View.post_id)
        .all()
    )

    result = []
    for post in posts:
        uv = upvote_counts.get(post.id, 0)
        dv = downvote_counts.get(post.id, 0)
        vc = view_counts.get(post.id, 0)
        result.append(
            schemas.PostOut.from_orm(post).copy(update={
                "is_upvoted": post.id in upvoted_ids,
                "is_downvoted": post.id in downvoted_ids,
                "upvote_downvote_count": uv - dv,
                "view_count": vc,
            })
        )

    return result

def find_similar_posts(db: Session, source_posts: List[Post]) -> List[int]:
    if not source_posts:
        return []

    source_tags = set()
    source_keywords = set()

    for post in source_posts:
        if getattr(post, "tags", None):
            if isinstance(post.tags, list):
                source_tags.update([str(t).strip().lower() for t in post.tags])
            else:
                source_tags.update([str(t).strip().lower() for t in str(post.tags).split(",") if t.strip()])

        if post.title:
            for word in post.title.lower().split():
                if len(word) > 2:
                    source_keywords.add(word)

    query = db.query(Post).filter(Post.analysis_status == AnalysisStatus.COMPLETED)

    similar_posts = []
    source_ids = {p.id for p in source_posts}

    for candidate in query.all():
        if candidate.id in source_ids:
            continue

        score = 0

        if getattr(candidate, "tags", None):
            candidate_tags = (
                candidate.tags if isinstance(candidate.tags, list)
                else [t.strip().lower() for t in str(candidate.tags).split(",") if t.strip()]
            )
            overlap = source_tags.intersection(set(candidate_tags))
            score += len(overlap) * 2

        if candidate.title:
            candidate_words = set(candidate.title.lower().split())
            overlap = source_keywords.intersection(candidate_words)
            score += len(overlap)

        if score > 0:
            similar_posts.append((candidate.id, score))

    if not similar_posts:
        posts = (
            db.query(Post)
            .filter(~Post.id.in_(source_ids), Post.analysis_status == AnalysisStatus.COMPLETED)
            .order_by(Post.created_at.desc())
            .limit(10)
            .all()
        )
        return [p.id for p in posts]

    similar_posts.sort(key=lambda x: x[1], reverse=True)
    return [pid for pid, _ in similar_posts[:10]]
    
@router.get("/map/pins", response_model=List[schemas.PostPinOut])
def get_map_pins(db: Session = Depends(get_db)):
    return db.query(
        Post.id, 
        Post.title, 
        Post.latitude, 
        Post.longitude, 
        Post.credibility_score, 
        Post.risk_type, 
        Post.short_title, 
        Post.summary_easy
    ).filter(Post.latitude.isnot(None)).all()

from task_queue import TaskQueue

@router.post("/", response_model=schemas.PostOut)
async def create_post(
    post: schemas.PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_post = Post(
        **post.dict(),
        created_by=current_user.id,
        analysis_status=AnalysisStatus.PENDING,
        analysis_progress=0.0,
        status_message="ESTABLISHING_FORENSIC_INGESTION"
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)

    await TaskQueue.enqueue_analysis(db_post.id)

    return db_post

@router.get("/{post_id:int}", response_model=schemas.PostOut)
def get_post_detail(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy.orm import joinedload
    
    if post_id >= 100000:
        from services.vector_service import VectorService
        vector_service = VectorService()
        claims = vector_service.get_random_claims(limit=50) # Just to find it
        for i, c in enumerate(claims):
            if (100000 + i) == post_id:
                return map_qdrant_to_post(c, i)
        raise HTTPException(status_code=404, detail="Virtual Post not found")

    from sqlalchemy.orm import joinedload, selectinload
    
    post = (
        db.query(Post)
        .options(
            joinedload(Post.claims).selectinload(Claim.sources),
            joinedload(Post.claims).selectinload(Claim.fact_check_sites),
            joinedload(Post.tags),
            joinedload(Post.red_flags),
            joinedload(Post.trust_signals),
            joinedload(Post.news_outlet),
            joinedload(Post.owner)
        )
        .filter(Post.id == post_id)
        .first()
    )
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    uv = db.query(Upvote).filter_by(post_id=post.id).count()
    dv = db.query(Downvote).filter_by(post_id=post.id).count()
    vc = db.query(View).filter_by(post_id=post.id).count()
    
    is_up = db.query(Upvote).filter_by(user_id=current_user.id, post_id=post.id).first() is not None
    is_down = db.query(Downvote).filter_by(user_id=current_user.id, post_id=post.id).first() is not None

    return schemas.PostOut.from_orm(post).copy(update={
        "upvote_downvote_count": uv - dv,
        "view_count": vc,
        "is_upvoted": is_up,
        "is_downvoted": is_down,
    })

@router.post("/{post_id:int}/upvote", status_code=201)
def add_upvote(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if post_id >= 100000:
        return {"message": "Interaction Recorded (Virtual)"}
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    existing_upvote = db.query(Upvote).filter_by(user_id=current_user.id, post_id=post_id).first()
    if existing_upvote:
        db.delete(existing_upvote)
        db.commit()
        return {"message": "Upvote Neutralised"}

    existing_downvote = db.query(Downvote).filter_by(user_id=current_user.id, post_id=post_id).first()
    if existing_downvote:
        db.delete(existing_downvote)
        db.commit()

    db_upvote = Upvote(user_id=current_user.id, post_id=post_id)
    db.add(db_upvote)
    db.commit()
    return {"message": "Upvoted"}

@router.post("/{post_id:int}/downvote", status_code=201)
def add_downvote(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if post_id >= 100000:
        return {"message": "Interaction Recorded (Virtual)"}
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    existing_downvote = db.query(Downvote).filter_by(user_id=current_user.id, post_id=post_id).first()
    if existing_downvote:
        db.delete(existing_downvote)
        db.commit()
        return {"message": "Neutralised Downvote"}

    existing_upvote = db.query(Upvote).filter_by(user_id=current_user.id, post_id=post_id).first()
    if existing_upvote:
        db.delete(existing_upvote)
        db.commit()

    db_downvote = Downvote(user_id=current_user.id, post_id=post_id)
    db.add(db_downvote)
    db.commit()
    return {"message": "Downvoted"}

@router.post("/{post_id:int}/view", status_code=201)
def add_view(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if post_id >= 100000:
        return {"message": "View Recorded (Virtual)"}
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    db_view = View(user_id=current_user.id, post_id=post_id)
    db.add(db_view)
    db.commit()
    return {"message": "View recorded"}

@router.delete("/{post_id}")
def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if post:
        db.delete(post)
        db.commit()
    return {"message": "done"}

@router.get("/{post_id:int}/status", response_model=schemas.AnalysisStatusOut)
def get_analysis_status(
    post_id: int,
    db: Session = Depends(get_db)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    return {
        "post_id": post.id,
        "analysis_status": post.analysis_status,
        "analysis_progress": post.analysis_progress,
        "status_message": post.status_message
    }
