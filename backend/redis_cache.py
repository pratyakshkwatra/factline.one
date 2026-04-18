import os
import redis
import json
from dotenv import load_dotenv

load_dotenv()

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

class RedisCache:
    _instance = None

    @classmethod
    def get_client(cls):
        if cls._instance is None:
            cls._instance = redis.from_url(REDIS_URL, decode_responses=True)
        return cls._instance

    @classmethod
    def set_progress(cls, post_id: int, status: str, progress: float, message: str):
        client = cls.get_client()
        data = {
            "analysis_status": status,
            "analysis_progress": progress,
            "status_message": message
        }
        client.set(f"post_progress:{post_id}", json.dumps(data), ex=3600)

    @classmethod
    def get_progress(cls, post_id: int):
        client = cls.get_client()
        raw = client.get(f"post_progress:{post_id}")
        return json.loads(raw) if raw else None

    @classmethod
    def cache_leaderboard(cls, data):
        client = cls.get_client()
        client.set("leaderboard", json.dumps(data), ex=300)

    @classmethod
    def publish_status(cls, post_id: int, status: str, progress: float, message: str):
        client = cls.get_client()
        data = {
            "post_id": post_id,
            "analysis_status": status,
            "analysis_progress": progress,
            "status_message": message
        }
        client.publish("task_updates", json.dumps(data))

    @classmethod
    def get_leaderboard(cls):
        client = cls.get_client()
        raw = client.get("leaderboard")
        return json.loads(raw) if raw else None
