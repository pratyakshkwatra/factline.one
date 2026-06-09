import sqlite3
import os
import uuid
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.models.database import SessionLocal, CandidateItem, InvestigationInput, SubmittedUrl, OriginalPost
from app.services.report import Report
from app.services.investigation import InvestigationTask, Evidence
from app.core.config import settings

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                pass

manager = ConnectionManager()

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@router.post("/notify")
async def notify_update():
    import json
    await manager.broadcast(json.dumps({"type": "update", "source": "server"}))
    return {"status": "notified"}

@router.get("/candidates")
def get_candidates(db: Session = Depends(get_db)):
    items = db.query(CandidateItem).order_by(CandidateItem.timestamp.desc()).limit(50).all()
    return {"candidates": items}

@router.get("/investigations")
def get_investigations(db: Session = Depends(get_db)):
    tasks = db.query(InvestigationTask).order_by(InvestigationTask.id.desc()).limit(50).all()
    return {"investigations": tasks}

class InvestigationSubmitRequest(BaseModel):
    url: Optional[str] = None
    post_content: Optional[str] = None
    comments: Optional[str] = None
    notes: Optional[str] = None

@router.post("/investigations/submit")
def submit_investigation(request: InvestigationSubmitRequest, db: Session = Depends(get_db)):
    from datetime import datetime
    new_input_id = str(uuid.uuid4())
    input_type = "url" if request.url and not request.post_content else "mixed"
    
    new_input = InvestigationInput(
        id=new_input_id,
        input_type=input_type,
        status="pending",
        notes=request.notes,
        created_at=datetime.utcnow()
    )
    db.add(new_input)
    
    if request.url:
        db.add(SubmittedUrl(id=str(uuid.uuid4()), input_id=new_input_id, url=request.url))
        
    content = ""
    if request.post_content:
        content += request.post_content + "\n"
    if request.comments:
        content += "Comments:\n" + request.comments
        
    if content.strip():
        db.add(OriginalPost(id=str(uuid.uuid4()), input_id=new_input_id, content=content.strip()))
        
    db.commit()
    import json
    # Use async event loop or simple sync call to broadcast if possible, or just skip
    return {"status": "submitted", "id": new_input_id}

@router.get("/evidence")
def get_evidence(db: Session = Depends(get_db)):
    evidence = db.query(Evidence).order_by(Evidence.collection_timestamp.desc()).limit(50).all()
    return {"evidence": evidence}

@router.get("/reports")
def get_reports(db: Session = Depends(get_db)):
    reports = db.query(Report).all()
    return {"reports": reports}

@router.post("/publish/{report_id}")
def publish_report(report_id: str, db: Session = Depends(get_db)):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        return {"error": "not found"}
    
    # Generate slug
    title_slug = report.title.lower().replace(" ", "-")[:50]
    import re
    title_slug = re.sub(r'[^a-z0-9\-]', '', title_slug)
    unique_hash = str(uuid.uuid4())[:4]
    slug = f"{title_slug}-{unique_hash}"
    public_url = f"{settings.PUBLIC_BASE_URL}/r/{slug}"
    
    # Save to the public dashboard's static directory so it can be served
    db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "public-dashboard", "public", "public_reports.db")
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS public_reports (
            id TEXT PRIMARY KEY,
            slug TEXT UNIQUE,
            title TEXT,
            summary TEXT,
            verdict TEXT,
            public_url TEXT
        )
    ''')
    
    try:
        cursor.execute('''
            INSERT INTO public_reports (id, slug, title, summary, verdict, public_url)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (report.id, slug, report.title, report.summary, report.verdict, public_url))
        conn.commit()
    except sqlite3.IntegrityError:
        pass # Already published
    finally:
        conn.close()
    
    # Store generated URL in main DB
    report.public_url = public_url
    db.commit()
    
    return {"status": "published", "report_id": report_id, "public_url": public_url}
