from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

app = FastAPI(
    title="Factline Intelligence Engine API",
    description="Backend API for the FIE Local Dashboard",
    version="2.0.0",
)

# CORS configuration for the dashboards
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up Factline Intelligence Engine...")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to Factline V2 Intelligence Engine"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
