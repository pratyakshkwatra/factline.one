from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import os
import numpy as np

class VectorService:
    def __init__(self):
        host = os.getenv("QDRANT_HOST", "localhost")
        port = int(os.getenv("QDRANT_PORT", 6333))
        self.client = QdrantClient(host=host, port=port)
        self.collection_name = "truth_base"
        self._ensure_collection()

    def _ensure_collection(self):
        collections = self.client.get_collections().collections
        exists = any(c.name == self.collection_name for c in collections)
        if not exists:
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=3072, distance=Distance.COSINE),
            )

    def search_truth(self, query_vector: list, limit: int = 1):
        try:
            results = self.client.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=limit,
                with_payload=True
            )
            if results:
                return results[0].payload
            return None
        except Exception:
            return None

    def seed_truth(self, items: list, embedding_func):
        points = []
        for i, item in enumerate(items):
            emb = embedding_func(item['text'])
            points.append(PointStruct(
                id=i,
                vector=emb,
                payload=item
            ))
        self.client.upsert(
            collection_name=self.collection_name,
            points=points
        )
    def get_random_claims(self, limit: int = 5):
        try:
            results = self.client.scroll(
                collection_name=self.collection_name,
                limit=limit,
                with_payload=True
            )
            return [r.payload for r in results[0]]
        except Exception:
            return []
