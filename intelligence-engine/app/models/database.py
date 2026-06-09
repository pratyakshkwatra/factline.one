from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Text, Float, Boolean, create_engine, JSON, ForeignKey, text
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Source(Base):
    __tablename__ = "sources"
    
    id = Column(String, primary_key=True, index=True)
    name = Column(String, index=True)
    url = Column(String, unique=True, index=True)
    category = Column(String, index=True)
    source_type = Column(String, index=True)
    authority_score = Column(Float, default=0.5)
    enabled = Column(Boolean, default=True)
    priority = Column(Integer, default=1)
    update_frequency = Column(Integer, default=3600)
    last_success = Column(DateTime, nullable=True)
    last_failure = Column(DateTime, nullable=True)

class Topic(Base):
    __tablename__ = "topics"
    
    id = Column(String, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    queries = Column(JSON) # List of search strings
    enabled = Column(Boolean, default=True)

class CandidateItem(Base):
    __tablename__ = "candidate_items"

    id = Column(String, primary_key=True, index=True)
    source_id = Column(String, ForeignKey("sources.id"), nullable=True)
    source_type = Column(String, index=True) # e.g. "rss", "reddit", "twitter", "search", "recursive"
    source_name = Column(String)
    url = Column(String, unique=True, index=True)
    title = Column(String)
    content = Column(Text)
    author = Column(String)
    timestamp = Column(DateTime)
    engagement = Column(Integer, default=0)
    raw_html = Column(Text, nullable=True)
    clean_text = Column(Text)
    screenshot_path = Column(String, nullable=True)
    collection_timestamp = Column(DateTime, default=datetime.utcnow)
    source_metadata = Column(JSON, nullable=True)
    
    # Ranking
    opportunity_score = Column(Float, nullable=True)
    status = Column(String, default="discovered") # discovered, ranked, selected, investigated, duplicate

class InvestigationInput(Base):
    __tablename__ = "investigation_inputs"
    id = Column(String, primary_key=True, index=True)
    input_type = Column(String) # url, text, screenshot, mixed
    status = Column(String, default="pending") # pending, running, completed, published, failed
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class OriginalPost(Base):
    __tablename__ = "original_posts"
    id = Column(String, primary_key=True, index=True)
    input_id = Column(String, ForeignKey("investigation_inputs.id"))
    platform = Column(String, nullable=True)
    url = Column(String, nullable=True)
    content = Column(Text)
    author = Column(String, nullable=True)

class OriginalComment(Base):
    __tablename__ = "original_comments"
    id = Column(String, primary_key=True, index=True)
    post_id = Column(String, ForeignKey("original_posts.id"))
    content = Column(Text)
    author = Column(String, nullable=True)

class SubmittedUrl(Base):
    __tablename__ = "submitted_urls"
    id = Column(String, primary_key=True, index=True)
    input_id = Column(String, ForeignKey("investigation_inputs.id"))
    url = Column(String)

class UploadedScreenshot(Base):
    __tablename__ = "uploaded_screenshots"
    id = Column(String, primary_key=True, index=True)
    input_id = Column(String, ForeignKey("investigation_inputs.id"))
    file_path = Column(String)

class InvestigationGraph(Base):
    __tablename__ = "investigation_graphs"
    id = Column(String, primary_key=True, index=True)
    investigation_id = Column(String) # ForeignKey to Investigations table if one exists
    nodes = Column(JSON) # e.g. Claims, Sources, Evidence
    edges = Column(JSON) # e.g. supports, contradicts

def init_db():
    Base.metadata.create_all(bind=engine)
    # Safely apply schema upgrades to existing database
    try:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE candidate_items ADD COLUMN source_id VARCHAR"))
            conn.execute(text("ALTER TABLE candidate_items ADD COLUMN screenshot_path VARCHAR"))
    except Exception as e:
        pass # Columns already exist
