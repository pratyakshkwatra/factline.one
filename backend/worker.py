import os
import json
import asyncio
import redis.asyncio as redis
import agent
from database import SessionLocal
from models.post_model import Post, AnalysisStatus
from task_queue import REDIS_URL, QUEUE_NAME
from dotenv import load_dotenv

load_dotenv()

async def run_worker():
    print(f"Connecting to Redis at {REDIS_URL}...")
    client = redis.from_url(REDIS_URL, decode_responses=True)
    
    print("Forensic Worker connected to Redis successfully.")
    print(f"Forensic Worker started looking for tasks in queue: {QUEUE_NAME}")
    
    try:
        from google import genai
        genai_client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
        print("Checking available high-fidelity Truth-Signal models...")
        models = genai_client.models.list()
        print(f"Found available models. Ready for inference.")
    except Exception as e:
        print(f"Analytical Model Discovery Failed: {e}")

    try:
        while True:
            # brpop returns (queue_name, data)
            result = await client.brpop(QUEUE_NAME, timeout=0)
            if not result:
                continue
                
            _, data_raw = result
            try:
                data = json.loads(data_raw)
                post_id = data.get("post_id")
                if not post_id:
                    print("Skipping message with no post_id")
                    continue
                
                print(f"Received task for post_id: {post_id}")
                print(f"Starting forensic analysis for post_id: {post_id}")
                
                # Use to_thread for the synchronous database/engine work
                await asyncio.to_thread(process_analysis, post_id)
                print(f"Task finished for post_id: {post_id}")
                
            except json.JSONDecodeError:
                print(f"Failed to decode message: {data_raw}")
            except Exception as e:
                print(f"Error processing task: {e}")
                
    finally:
        await client.close()

def process_analysis(post_id: int):
    db = SessionLocal()
    try:
        post = db.get(Post, post_id)
        if not post: 
            print(f"Post {post_id} not found in database.")
            return

        from config import TAVILY_API_KEY
        engine = agent.NewsCredibilityEngine(TAVILY_API_KEY, db, post_id)
        news_article = agent.NewsArticle(
            title=post.title,
            body=post.body,
            media_url=post.media_url,
            media_type=post.media_type.value if hasattr(post.media_type, 'value') else post.media_type,
            source_url=post.source_url
        )
        engine.analyze(news_article)
    except Exception as e:
        print(f"Worker Error post_id {post_id}: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(run_worker())
