import uuid
import json
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
import time
import yaml
from loguru import logger
from sqlalchemy.orm import Session
from app.models.database import CandidateItem

RSS_FEEDS = [
    {"name": "Reuters World News", "url": "https://feeds.reuters.com/Reuters/worldNews"},
    {"name": "Reuters Technology", "url": "https://feeds.reuters.com/reuters/technologyNews"},
    {"name": "BBC World", "url": "http://feeds.bbci.co.uk/news/world/rss.xml"},
    {"name": "BBC Technology", "url": "http://feeds.bbci.co.uk/news/technology/rss.xml"},
    {"name": "Associated Press", "url": "https://apnews.com/hub/ap-top-news?output=rss"},
    {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml"},
    {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index"},
    {"name": "TechCrunch", "url": "https://techcrunch.com/feed/"},
    {"name": "Hacker News", "url": "https://hnrss.org/newest"},
]

def load_reddit_config():
    try:
        with open("config/sources.yaml", "r") as f:
            return yaml.safe_load(f).get("reddit", {})
    except Exception as e:
        logger.error(f"Failed to load config/sources.yaml: {e}")
        return {}

def fetch_rss_feed(feed):
    items = []
    logger.info(f"Fetching RSS feed: {feed['name']}")
    try:
        req = urllib.request.Request(feed['url'], headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            xml_data = response.read()
            root = ET.fromstring(xml_data)
            for item in root.findall('.//item')[:5]:
                title = item.findtext('title')
                link = item.findtext('link')
                description = item.findtext('description') or ""
                
                items.append(CandidateItem(
                    id=str(uuid.uuid4()),
                    source_type="rss",
                    source_name=feed['name'],
                    url=link,
                    title=title,
                    content=description,
                    clean_text=description,
                    author=feed['name'],
                    timestamp=datetime.utcnow(),
                    status="discovered",
                    source_metadata={"category": "rss"}
                ))
    except Exception as e:
        logger.error(f"Failed to fetch feed {feed['name']}: {e}")
    return items

def fetch_reddit_subreddit(subreddit, category_weight):
    items = []
    endpoints = ["hot.json", "new.json", "rising.json", "top.json?t=day"]
    for ep in endpoints:
        url = f"https://www.reddit.com/r/{subreddit}/{ep}"
        logger.info(f"Fetching Reddit endpoint: {url}")
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'FactlineBot/3.0'})
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode('utf-8'))
                children = data.get("data", {}).get("children", [])
                
                current_time = datetime.now(timezone.utc).timestamp()
                
                for child in children[:5]: # limit to prevent mass inserts
                    post = child.get("data", {})
                    title = post.get("title", "")
                    body = post.get("selftext", "")
                    score = post.get("score", 0)
                    comments = post.get("num_comments", 0)
                    author = post.get("author", "")
                    permalink = f"https://www.reddit.com{post.get('permalink', '')}"
                    created_utc = post.get("created_utc", current_time)
                    
                    # Calculate point-in-time velocity
                    age_hours = max((current_time - created_utc) / 3600.0, 0.1)
                    score_velocity = score / age_hours
                    comment_velocity = comments / age_hours
                    
                    metadata = {
                        "score": score,
                        "upvote_ratio": post.get("upvote_ratio", 1.0),
                        "comment_count": comments,
                        "awards": post.get("total_awards_received", 0),
                        "flair": post.get("link_flair_text", ""),
                        "subreddit": subreddit,
                        "subreddit_subscribers": post.get("subreddit_subscribers", 0),
                        "category_weight": category_weight,
                        "ranking_source": ep.split('.')[0],
                        "score_velocity": round(score_velocity, 2),
                        "comment_velocity": round(comment_velocity, 2),
                        "num_crossposts": post.get("num_crossposts", 0)
                    }
                    
                    items.append(CandidateItem(
                        id=str(uuid.uuid4()),
                        source_type="reddit",
                        source_name=f"r/{subreddit}",
                        url=permalink,
                        title=title,
                        content=body,
                        clean_text=body,
                        author=author,
                        engagement=score + comments,
                        timestamp=datetime.utcfromtimestamp(created_utc),
                        status="discovered",
                        source_metadata=metadata
                    ))
            time.sleep(1) # simple rate limit for Reddit API
        except urllib.error.HTTPError as e:
            logger.error(f"HTTP {e.code} on Reddit {url}")
            time.sleep(2)
        except Exception as e:
            logger.error(f"Failed to fetch Reddit {url}: {e}")
    return items

def run_discovery(db: Session):
    logger.info("Starting discovery process from configured sources...")
    new_items_count = 0
    
    # RSS Sources
    for feed in RSS_FEEDS:
        items = fetch_rss_feed(feed)
        for item in items:
            exists = db.query(CandidateItem).filter(CandidateItem.url == item.url).first()
            if not exists:
                db.add(item)
                new_items_count += 1
                
    # Reddit Sources via Config
    reddit_config = load_reddit_config()
    for cat_name, cat_data in reddit_config.items():
        weight = cat_data.get("weight", 1.0)
        subreddits = cat_data.get("subreddits", [])
        
        # limit subreddits during dev to prevent massive runtimes, taking top 3 per category
        for sub in subreddits[:3]: 
            items = fetch_reddit_subreddit(sub, weight)
            for item in items:
                exists = db.query(CandidateItem).filter(CandidateItem.url == item.url).first()
                if not exists:
                    db.add(item)
                    new_items_count += 1
                    
    db.commit()
    logger.info(f"Discovery complete. Added {new_items_count} new candidate items to database.")
    return new_items_count
