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
        from redis_cache import RedisCache
        import json
        client = RedisCache.get_client()
        pubsub = client.pubsub()
        pubsub.subscribe("task_updates")
        
        print("DEBUG: WebSocket Manager listening to Redis 'task_updates'...")
        
        while True:
            try:
                # Use a non-blocking check or a small timeout
                message = await asyncio.to_thread(pubsub.get_message, ignore_subscribe_messages=True, timeout=1.0)
                if message and message['type'] == 'message':
                    data = json.loads(message['data'])
                    post_id = data.get("post_id")
                    if post_id:
                        await self.broadcast_status(post_id, data)
            except Exception as e:
                print(f"DEBUG: Redis listener error: {e}")
            await asyncio.sleep(0.1)

manager = ConnectionManager()
