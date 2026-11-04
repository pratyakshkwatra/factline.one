import os
import json
import asyncio
import redis.asyncio as redis
from dotenv import load_dotenv
from logger import get_logger

load_dotenv()
logger = get_logger("Queue")

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
        logger.info("Enqueued forensic task for post #%s", post_id)

    @classmethod
    async def stop(cls):
        if cls._redis:
            await cls._redis.close()
