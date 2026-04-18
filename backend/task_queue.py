import os
import json
import asyncio
import redis.asyncio as redis
from dotenv import load_dotenv

load_dotenv()

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
QUEUE_NAME = "news-forensics-queue"

class TaskQueue:
    _redis = None

    @classmethod
    async def get_redis(cls):
        if cls._redis is None:
            cls._redis = redis.from_url(REDIS_URL, decode_responses=True)
        return cls._redis

    @classmethod
    async def enqueue_analysis(cls, post_id: int):
        client = await cls.get_redis()
        await client.lpush(QUEUE_NAME, json.dumps({"post_id": post_id}))
        print(f"Enqueued forensic task to Redis for post_id: {post_id}")

    @classmethod
    async def stop(cls):
        if cls._redis:
            await cls._redis.close()
