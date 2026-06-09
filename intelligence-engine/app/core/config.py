from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    PORT: int = 8000

    # Database
    DATABASE_URL: str = "postgresql://factline_user:factline_password@localhost:5432/factline_db"
    SQLITE_PUBLIC_DB_PATH: str = "./data/public_dashboard.sqlite"

    # Services
    REDIS_URL: str = "redis://localhost:6379/0"
    QDRANT_URL: str = "http://localhost:6333"

    # Local Model
    LM_STUDIO_URL: str = "http://localhost:1234/v1"
    MODEL_SMALL: str = "meta-llama-3-8b-instruct"
    MODEL_MEDIUM: str = "meta-llama-3-8b-instruct"
    MODEL_LARGE: str = "meta-llama-3-8b-instruct"
    
    PUBLIC_BASE_URL: str = "https://reports.factline.xyz"

    class Config:
        env_file = (".env", "../.env")
        extra = "ignore"

settings = Settings()
