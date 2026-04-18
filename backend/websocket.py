from fastapi import WebSocket
from typing import Dict, List
import asyncio

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
        
        client = redis.from_url(REDIS_URL, decode_responses=True)
        pubsub = client.pubsub()
        await pubsub.subscribe("task_updates")
        
        print("DEBUG: WebSocket Manager listening to Redis 'task_updates' (ASYNCHRONOUS)...")
        
        try:
            async for message in pubsub.listen():
                if message and message['type'] == 'message':
                    try:
                        data = json.loads(message['data'])
                        post_id = data.get("post_id")
                        if post_id:
                            # Use current loop for broadcasting
                            await self.broadcast_status(int(post_id), data)
                    except Exception as json_e:
                        print(f"DEBUG: JSON Parse Error in WebSocket Listener: {json_e}")
        except Exception as e:
            print(f"DEBUG: Async Redis listener error: {e}")
        finally:
            await pubsub.unsubscribe("task_updates")
            await client.close()

manager = ConnectionManager()
