from sqlalchemy import (
    Column, Integer, String, DateTime, ForeignKey, JSON, Enum, UniqueConstraint, Float, Text, Boolean
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from db_base import Base
import enum

class AnalysisStatus(enum.Enum):
    PENDING = "PENDING"
    INGESTING = "INGESTING"
    REFINING = "REFINING"
    VERIFYING = "VERIFYING"
    GROUNDING = "GROUNDING"
    FINALIZING = "FINALIZING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class MediaType(enum.Enum):
    TEXT = "TEXT"
    IMAGE = "IMAGE"
    AUDIO = "AUDIO"
    VIDEO = "VIDEO"

class NewsOutlet(Base):
    __tablename__ = "news_outlets"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, unique=True)
    domain = Column(String, index=True, unique=True)
    is_whitelisted = Column(Boolean, default=True)
    is_blacklisted = Column(Boolean, default=False)
    credibility_score = Column(Float, default=70.0)
    bias = Column(String, nullable=True)
    official_url = Column(String, nullable=True)
    img_url = Column(String, nullable=True)
    articles_processed = Column(Integer, default=0)
    avg_trust_score = Column(Float, default=0.0)

class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    body = Column(Text, nullable=True) 
    refined_body = Column(Text, nullable=True)
    source_url = Column(String, nullable=True)
    media_url = Column(String, nullable=True)
    media_type = Column(Enum(MediaType), default=MediaType.TEXT, nullable=False)
    language = Column(String, default="en", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)

    news_outlet_id = Column(Integer, ForeignKey("news_outlets.id"), nullable=True)
    news_outlet = relationship("NewsOutlet")

    analysis_status = Column(Enum(AnalysisStatus), default=AnalysisStatus.PENDING, nullable=False)
    analysis_progress = Column(Float, default=0.0, nullable=False)  
    status_message = Column(String, default="Not started", nullable=False)  

    short_title = Column(String, index=True, nullable=True)
    summary_easy = Column(Text, nullable=True)
    credibility_score = Column(Integer, index=True, nullable=True)
    confidence_score = Column(Integer, index=True, nullable=True)
    bias = Column(String, nullable=True)
    sentiment = Column(String, nullable=True)
    risk_type = Column(String, nullable=True)
    historical_context = Column(Text, nullable=True)
    is_breaking_news = Column(Boolean, default=False)

    counter_narrative = Column(Text, nullable=True)
    inconsistency_highlights = Column(Text, nullable=True)
    verifiable_alternatives = Column(JSON, nullable=True)
    forensic_artifacts = Column(JSON, nullable=True)
    evidence_chain = Column(JSON, nullable=True)

    alt_headline_neutral = Column(String, nullable=True)
    alt_headline_sensational = Column(String, nullable=True)
    alt_headline_calm = Column(String, nullable=True)
    
    analysis_raw = Column(JSON, nullable=True)

    owner = relationship("User", back_populates="posts")

    upvotes = relationship("Upvote", back_populates="post", cascade="all, delete-orphan")
    downvotes = relationship("Downvote", back_populates="post", cascade="all, delete-orphan")
    views = relationship("View", back_populates="post", cascade="all, delete-orphan")

    tags = relationship("PostTag", back_populates="post", cascade="all, delete-orphan")
    red_flags = relationship("RedFlag", back_populates="post", cascade="all, delete-orphan")
    claims = relationship("Claim", back_populates="post", cascade="all, delete-orphan")
    trust_signals = relationship("TrustSignal", back_populates="post", cascade="all, delete-orphan")

    latitude = Column(Float, nullable=True, index=True)
    longitude = Column(Float, nullable=True, index=True)

class PostTag(Base):
    __tablename__ = "post_tags"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    tag = Column(String, index=True, nullable=False)

    post = relationship("Post", back_populates="tags")

class RedFlag(Base):
    __tablename__ = "red_flags"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    flag = Column(String, nullable=False)

    post = relationship("Post", back_populates="red_flags")

class TrustSignal(Base):
    __tablename__ = "trust_signals"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    signal = Column(String, nullable=False)

    post = relationship("Post", back_populates="trust_signals")

class Claim(Base):
    __tablename__ = "claims"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)

    text = Column(Text, nullable=False)
    credibility_score = Column(Integer, nullable=True)
    confidence = Column(String, nullable=True)  
    reason = Column(Text, nullable=True)
    verdict = Column(String, nullable=True)  # VERIFIED, REFUTED, UNCERTAIN, CONTROVERSIAL
    historical_context = Column(Text, nullable=True)

    post = relationship("Post", back_populates="claims")

    sources = relationship("ClaimSource", back_populates="claim", cascade="all, delete-orphan")
    fact_check_sites = relationship("FactCheckSite", back_populates="claim", cascade="all, delete-orphan")

class ClaimSource(Base):
    __tablename__ = "claim_sources"

    id = Column(Integer, primary_key=True, index=True)
    claim_id = Column(Integer, ForeignKey("claims.id", ondelete="CASCADE"), nullable=False)
    source_url = Column(String, nullable=False)

    claim = relationship("Claim", back_populates="sources")

class FactCheckSite(Base):
    __tablename__ = "fact_check_sites"

    id = Column(Integer, primary_key=True, index=True)
    claim_id = Column(Integer, ForeignKey("claims.id", ondelete="CASCADE"), nullable=False)
    site_url = Column(String, nullable=False)

    claim = relationship("Claim", back_populates="fact_check_sites")

class Upvote(Base):
    __tablename__ = "upvotes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    post = relationship("Post", back_populates="upvotes")
    user = relationship("User", back_populates="upvotes")

    __table_args__ = (UniqueConstraint("user_id", "post_id", name="unique_upvote"),)

class Downvote(Base):
    __tablename__ = "downvotes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    post = relationship("Post", back_populates="downvotes")
    user = relationship("User", back_populates="downvotes")

    __table_args__ = (UniqueConstraint("user_id", "post_id", name="unique_downvote"),)

class View(Base):
    __tablename__ = "views"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    post = relationship("Post", back_populates="views")
    user = relationship("User", back_populates="views")