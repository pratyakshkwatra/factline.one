import os
import json
import time
import traceback
import redis
import agent
from database import SessionLocal
from models.post_model import Post, AnalysisStatus
from task_queue import REDIS_URL, QUEUE_NAME
from dotenv import load_dotenv
from logger import get_logger

load_dotenv()
logger = get_logger("Worker")

def run_worker():
    logger.info("Connecting to Redis at %s...", REDIS_URL)
    client = redis.from_url(REDIS_URL, decode_responses=True)
    logger.info("Connected to Redis successfully. Listening on '%s'...", QUEUE_NAME)
    
    # Check Google Gemini connection
    try:
        from google import genai
        if os.getenv("GOOGLE_API_KEY"):
            genai_client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
            logger.info("Google Gemini engine active (models/gemini-flash-latest).")
        else:
            logger.warning("GOOGLE_API_KEY is not set.")
    except Exception as e:
        logger.warning("Gemini discovery note: %s", e)

    while True:
        try:
            result = client.brpop(QUEUE_NAME, timeout=5)
            if not result:
                time.sleep(0.2)
                continue
                
            _, data_raw = result
            try:
                data = json.loads(data_raw)
                post_id = data.get("post_id")
                if not post_id:
                    continue
                
                logger.info("Forensic task dequeued for post #%s. Commencing multi-stage analysis...", post_id)
                process_analysis(post_id)
                logger.info("Forensic task finished for post #%s.", post_id)
                
            except json.JSONDecodeError:
                logger.error("Failed to decode queue message: %s", data_raw)
            except Exception as e:
                logger.error("Error processing task for post #%s: %s", post_id, e)
        except redis.exceptions.TimeoutError:
            continue
        except Exception as loop_e:
            if "timeout" in str(loop_e).lower():
                continue
            logger.warning("Worker loop notice: %s", loop_e)
            time.sleep(2)

def process_analysis(post_id: int):
    db = SessionLocal()
    try:
        post = db.get(Post, post_id)
        if not post: 
            logger.warning("Post #%s not found in database.", post_id)
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
        logger.error("Analysis pipeline failed on post #%s: %s", post_id, e)
    finally:
        db.close()

if __name__ == "__main__":
    run_worker()
