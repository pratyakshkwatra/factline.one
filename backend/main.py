import sys
import os
import asyncio
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '.')))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from routes import auth, post, game

os.makedirs("uploads", exist_ok=True)

app = FastAPI(
    title="Factline API",
    description="Factline Backend",
    version="1.0.0",
)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    print(f"DEBUG: Validation error on {request.url}: {exc.errors()}")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "message": "Validation Error"},
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.staticfiles import StaticFiles

app.include_router(auth.router, tags=["Auth"])
app.include_router(post.router, prefix="/posts", tags=["Posts"])
app.include_router(game.router, tags=["Game"]) 

from database import SessionLocal, engine, Base
from seed import seed_forensic_news
from websocket import manager

@app.on_event("startup")
async def startup_event():
    import time
    from sqlalchemy import text
    
    max_retries = 10
    retry_count = 0
    connected = False
    
    while retry_count < max_retries and not connected:
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            connected = True
        except Exception as e:
            retry_count += 1
            print(f"Waiting for DB connection... (Attempt {retry_count}/{max_retries}): {e}")
            await asyncio.sleep(2)

    if not connected:
        print("CRITICAL: SQL Connection failed. Application might fail.")

    # 2. Create tables if not exist
    Base.metadata.create_all(bind=engine)

    # 3. Perform manual migrations for new columns
    try:
        with engine.connect() as conn:
            # Post columns
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS refined_body TEXT"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS news_outlet_id INTEGER"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS counter_narrative TEXT"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS inconsistency_highlights TEXT"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS verifiable_alternatives JSON"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS forensic_artifacts JSON"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS latitude FLOAT"))
            conn.execute(text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS longitude FLOAT"))
            
            # NewsOutlet columns
            conn.execute(text("ALTER TABLE news_outlets ADD COLUMN IF NOT EXISTS bias TEXT"))
            conn.execute(text("ALTER TABLE news_outlets ADD COLUMN IF NOT EXISTS official_url TEXT"))
            conn.execute(text("ALTER TABLE news_outlets ADD COLUMN IF NOT EXISTS img_url TEXT"))
            
            conn.commit()
            print("DB Migrations (ALTER TABLE) completed successfully.")
    except Exception as e:
        print(f"DB Migration Warning (Non-critical if tables fresh): {e}")
    
    loop = asyncio.get_running_loop()
    manager.set_loop(loop)
    
    # Start Redis Listener
    loop.create_task(manager.listen_to_redis())
    
    print("DEBUG: Registered Routes:")
    for route in app.routes:
        methods = getattr(route, "methods", "WS")
        print(f"DEBUG: Route {route.path} [{methods}] -> {route.name}")

    db = SessionLocal()
    try:
        seed_forensic_news(db)
    finally:
        db.close()

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

from fastapi import WebSocket, WebSocketDisconnect
from websocket import manager

@app.websocket("/ws/posts/{post_id}")
async def websocket_endpoint(websocket: WebSocket, post_id: int):
    await manager.connect(websocket, post_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, post_id)

@app.get("/")
async def root():
    return {"message": "Welcome to the Factline API"}
