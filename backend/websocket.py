from fastapi import WebSocket
from typing import Dict, List
import asyncio
from logger import get_logger

logger = get_logger("WebSocket")

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}
        self.loop = None

    def set_loop(self, loop):
        self.loop = loop

    async def connect(self, websocket: WebSocket, post_id: int):
        await websocket.accept()
        if post_id not in self.active_connections:
            self.active_connections[post_id] = []
        self.active_connections[post_id].append(websocket)

    def disconnect(self, websocket: WebSocket, post_id: int):
        if post_id in self.active_connections:
            self.active_connections[post_id].remove(websocket)
            if not self.active_connections[post_id]:
                del self.active_connections[post_id]

    async def broadcast_status(self, post_id: int, status_update: dict):
        if post_id in self.active_connections:
            tasks = [
                connection.send_json(status_update)
                for connection in self.active_connections[post_id]
            ]
            if tasks:
                await asyncio.gather(*tasks)

    async def listen_to_redis(self):
        import redis.asyncio as redis
        from redis_cache import REDIS_URL
        import json

        while True:
            client = None
            pubsub = None
            try:
                client = redis.from_url(REDIS_URL, decode_responses=True)
                pubsub = client.pubsub()
                await pubsub.subscribe("task_updates")
                logger.info("Listening to Redis 'task_updates' for live client broadcasts...")

                while True:
                    try:
                        message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
                        if message and message.get('type') == 'message':
                            data = json.loads(message['data'])
                            post_id = data.get("post_id")
                            if post_id:
                                await self.broadcast_status(int(post_id), data)
                        await asyncio.sleep(0.05)
                    except asyncio.CancelledError:
                        raise
                    except json.JSONDecodeError:
                        pass
                    except Exception as msg_e:
                        logger.debug("Message parse notice: %s", msg_e)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.warning("Redis pubsub reconnection required: %s (retrying in 5s)", e)
                await asyncio.sleep(5)
            finally:
                if pubsub:
                    try:
                        await pubsub.unsubscribe("task_updates")
                        await pubsub.close()
                    except Exception:
                        pass
                if client:
                    try:
                        await client.aclose()
                    except Exception:
                        pass

manager = ConnectionManager()
