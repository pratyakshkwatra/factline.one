from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr
from datetime import datetime
from models.post_model import AnalysisStatus

class PostTag(BaseModel):
    tag: str
    class Config:
        from_attributes = True

class RedFlag(BaseModel):
    flag: str
    class Config:
        from_attributes = True

class TrustSignal(BaseModel):
    signal: str
    class Config:
        from_attributes = True

class ClaimSource(BaseModel):
    source_url: str
    class Config:
        from_attributes = True

class FactCheckSite(BaseModel):
    site_url: str
    class Config:
        from_attributes = True

class Claim(BaseModel):
    text: str
    credibility_score: Optional[int] = None
    confidence: Optional[str] = None
    reason: Optional[str] = None
    verdict: Optional[str] = None
    historical_context: Optional[str] = None
    sources: List[ClaimSource] = []
    fact_check_sites: List[FactCheckSite] = []
    class Config:
        from_attributes = True

class AnalysisStatusOut(BaseModel):
    post_id: int
    analysis_status: Optional[AnalysisStatus] = AnalysisStatus.PENDING
    analysis_progress: Optional[float] = 0.0
    status_message: Optional[str] = "Not started"
    
    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class RefreshToken(BaseModel):
    refresh_token: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class UserOut(UserBase):
    id: int
    is_active: bool
    role: str

    class Config:
        from_attributes = True

class NewsOutletOut(BaseModel):
    id: int
    name: str
    domain: str
    is_whitelisted: bool
    is_blacklisted: bool
    credibility_score: float
    bias: Optional[str] = None
    official_url: Optional[str] = None
    img_url: Optional[str] = None
    articles_processed: int
    avg_trust_score: float
    class Config:
        from_attributes = True

class PostBase(BaseModel):
    title: str
    body: Optional[str]
    media_url: Optional[str] = None
    media_type: str = "TEXT"

class PostCreate(PostBase):
    source_url: Optional[str] = None

class PostOut(PostBase):
    id: int
    created_at: datetime
    owner: UserOut
    language: Optional[str] = "en"
    
    refined_body: Optional[str] = None
    source_url: Optional[str] = None
    news_outlet: Optional[NewsOutletOut] = None

    analysis_status: Optional[AnalysisStatus] = AnalysisStatus.PENDING
    analysis_progress: Optional[float] = 0.0
    status_message: Optional[str] = "Not started"
    short_title: Optional[str] = None
    summary_easy: Optional[str] = None
    credibility_score: Optional[int] = None
    confidence_score: Optional[int] = None
    bias: Optional[str] = None
    sentiment: Optional[str] = None
    risk_type: Optional[str] = None

    
    counter_narrative: Optional[str] = None
    inconsistency_highlights: Optional[str] = None
    verifiable_alternatives: Optional[List[str]] = None
    forensic_artifacts: Optional[List[Dict[str, Any]]] = None
    grounding_context: Optional[Dict[str, Any]] = None
    evidence_chain: Optional[List[str]] = None
    c2pa_status: Optional[str] = None

    alt_headline_neutral: Optional[str] = None
    alt_headline_sensational: Optional[str] = None
    alt_headline_calm: Optional[str] = None
    
    analysis_raw: Optional[Dict[str, Any]] = None

    tags: List[PostTag] = []
    red_flags: List[RedFlag] = []
    claims: List[Claim] = []
    trust_signals: List[TrustSignal] = []

    latitude: Optional[float] = None
    longitude: Optional[float] = None

    is_upvoted: bool = False
    is_downvoted: bool = False

    upvote_downvote_count: int = 0
    view_count: int = 0

    class Config:
        from_attributes = True

class GameQuery(BaseModel):
    country: Optional[str] = "us"

class GameArticle(BaseModel):
    title: str
    body: str
    is_fake: bool
    source_url: str
