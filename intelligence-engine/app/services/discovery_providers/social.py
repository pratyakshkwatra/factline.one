import os
import time
import uuid
from datetime import datetime
from loguru import logger
from app.models.database import CandidateItem
from app.services.discovery_providers.base import BaseDiscoveryProvider

class SocialProvider(BaseDiscoveryProvider):
    def __init__(self, reddit_config: dict):
        self.config = reddit_config
        
    async def fetch_subreddit(self, subreddit, weight):
        items = []
        start_time = time.time()
        try:
            client_id = os.getenv("REDDIT_CLIENT_ID")
            client_secret = os.getenv("REDDIT_CLIENT_SECRET")
            
            if not client_id or not client_secret or client_id == "your_client_id":
                raise ValueError("Reddit OAuth credentials not provided in .env")

            import asyncpraw
            reddit = asyncpraw.Reddit(
                client_id=client_id,
                client_secret=client_secret,
                user_agent=os.getenv("REDDIT_USER_AGENT", "macOS:factline.engine:v2.0 (by /u/factline)")
            )
            sub = await reddit.subreddit(subreddit)
            
            async for submission in sub.hot(limit=5):
                items.append(CandidateItem(
                    id=str(uuid.uuid4()),
                    source_type="reddit",
                    source_name=f"r/{subreddit}",
                    url=f"https://reddit.com{submission.permalink}",
                    title=submission.title,
                    content=submission.selftext,
                    clean_text=submission.selftext,
                    author=str(submission.author),
                    engagement=submission.score + submission.num_comments,
                    timestamp=datetime.utcfromtimestamp(submission.created_utc),
                    status="discovered",
                    source_metadata={
                        "score": submission.score,
                        "comment_count": submission.num_comments,
                        "subreddit": subreddit,
                        "category_weight": weight
                    }
                ))
            await reddit.close()
            status = "success"
        except Exception as e:
            logger.warning(f"PRAW failed on r/{subreddit}: {e}. Skipping.")
            status = "failed"
            
        return {"source": f"r/{subreddit}", "items": items, "status": status, "time": time.time() - start_time}

    async def discover(self, session):
        import asyncio
        tasks = []
        for cat_name, cat_data in self.config.items():
            weight = cat_data.get("weight", 1.0)
            for sub in cat_data.get("subreddits", [])[:3]: # Limit 3 per category
                tasks.append(self.fetch_subreddit(sub, weight))
                
        return await asyncio.gather(*tasks, return_exceptions=True)
