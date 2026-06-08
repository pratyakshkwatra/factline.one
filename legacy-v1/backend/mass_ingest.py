import csv
import os
import requests
import time
import json
from google import genai
from google.genai import types
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from dotenv import load_dotenv
import io

load_dotenv()

LIAR_DATA_URL = "https://raw.githubusercontent.com/Tariq60/LIAR-PLUS/master/dataset/tsv/test2.tsv"

def ingest_mass():
    client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
    qdrant = QdrantClient(host=os.getenv("QDRANT_HOST", "localhost"), port=6333)
    
    col_name = "truth_base"
    
    try:
        collections = qdrant.get_collections().collections
        if not any(c.name == col_name for c in collections):
            qdrant.create_collection(
                collection_name=col_name,
                vectors_config=VectorParams(size=3072, distance=Distance.COSINE)
            )
    except Exception as e:
        print(f"Qdrant connection error: {e}")
        return

    data_dir = os.getenv("DATA_CACHE_DIR", ".")
    local_path = os.path.join(data_dir, "liar_dataset.tsv")
    
    if os.path.exists(local_path):
        print(f"Loading LIAR Dataset from cache: {local_path}")
        with open(local_path, "r", encoding="utf-8") as f:
            content = f.read()
    else:
        print(f"Downloading LIAR Dataset from {LIAR_DATA_URL}...")
        response = requests.get(LIAR_DATA_URL)
        if response.status_code != 200:
            print("Failed to download dataset.")
            return
        content = response.content.decode('utf-8')
        os.makedirs(data_dir, exist_ok=True)
        with open(local_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Dataset cached to {local_path}")

    reader = csv.reader(io.StringIO(content), delimiter='\t')
    
    limit = 1
    for i, row in enumerate(reader):
        if i >= limit: break
        if len(row) < 3: continue
        
        statement = row[2]
        label = row[1]
        context = row[12] if len(row) > 13 else "General News"
        speaker = row[3] if len(row) > 3 else "Unknown"
        
        category = context.split(",")[0].lower() if "," in context else context.lower()
        if "health" in category: img_tag = "medicine"
        elif "tax" in category or "budget" in category: img_tag = "money"
        elif "military" in category or "war" in category: img_tag = "conflict"
        elif "climate" in category or "energy" in category: img_tag = "environment"
        else: img_tag = "news"

        print(f"[{i}/{limit}] Ingesting: {statement[:30]}...")
        
        # Immediate embedding and upsert
        embedding = None
        for retry in range(2):
            try:
                emb_res = client.models.embed_content(
                    model="gemini-embedding-001",
                    contents=statement
                )
                embedding = emb_res.embeddings[0].values
                break
            except Exception as e:
                if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                    # For embeddings, 429 usually means daily quota hit
                    print(f"!! QUOTA EXHAUSTED on row {i} !! Free Tier limit reached.")
                    # If we already have some data, we can just stop or wait longer
                    print("Waiting 10s before skipping to next attempt (just in case it's a burst limit)...")
                    time.sleep(10)
                else:
                    print(f"Embedding error row {i}: {e}")
                    break
        
        if embedding:
            payload = {
                "text": statement,
                "label": label,
                "subject": context,
                "speaker": speaker,
                "category": category,
                "image_tag": img_tag,
                "explanation": f"Forensic audit on {speaker}'s claim regarding {context}.",
                "source": "Factline Matrix (PolitiFact Data)"
            }
            
            try:
                qdrant.upsert(
                    collection_name=col_name,
                    points=[PointStruct(
                        id=i + 2000,
                        vector=embedding,
                        payload=payload
                    )]
                )
                print(f"-> Linked record {i} to Factline Matrix.")
            except Exception as e:
                print(f"Upsert failed for row {i}: {e}")
            
            # small throttle to be friendly to APIs
            time.sleep(0.5)

    print(f"Mass-ingested stream complete.")

if __name__ == "__main__":
    try:
        ingest_mass()
    except Exception as e:
        print(f"INGESTOR_FATAL_ERROR: {str(e)}")
