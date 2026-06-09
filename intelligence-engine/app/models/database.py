from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Text, Float, create_engine, JSON
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class CandidateItem(Base):
    __tablename__ = "candidate_items"

    id = Column(String, primary_key=True, index=True)
    source_type = Column(String, index=True) # e.g. "rss", "reddit", "twitter"
    source_name = Column(String)
    url = Column(String, unique=True, index=True)
    title = Column(String)
    content = Column(Text)
    author = Column(String)
    timestamp = Column(DateTime)
    engagement = Column(Integer, default=0)
    raw_html = Column(Text, nullable=True)
    clean_text = Column(Text)
    collection_timestamp = Column(DateTime, default=datetime.utcnow)
    source_metadata = Column(JSON, nullable=True)
    
    # Ranking
    opportunity_score = Column(Float, nullable=True)
    status = Column(String, default="discovered") # discovered, ranked, selected, investigated, duplicate

def init_db():
    Base.metadata.create_all(bind=engine)
