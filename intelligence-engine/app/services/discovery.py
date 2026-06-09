import asyncio
import aiohttp
import yaml
from loguru import logger
from sqlalchemy.orm import Session
from app.models.database import CandidateItem, Source

from app.services.discovery_providers.direct import DirectProvider
from app.services.discovery_providers.search import SearchProvider
from app.services.discovery_providers.social import SocialProvider

def load_yaml(path: str) -> dict:
    try:
        with open(path, "r") as f:
            return yaml.safe_load(f) or {}
    except Exception:
        return {}

def ensure_sources_in_db(db: Session, config: dict):
    """Parses sources.yaml and inserts/updates Source models."""
    existing_names = {s.name for s in db.query(Source).all()}
    existing_urls = {s.url for s in db.query(Source).all() if s.url}
    
    added_names = set()
    added_urls = set()
    
    # Process RSS
    for cat, feeds in config.get("rss", {}).items():
        for feed in feeds:
            name = feed["name"]
            url = feed.get("url", "")
            if name not in existing_names and name not in added_names and url not in existing_urls and url not in added_urls:
                db.add(Source(id=name, name=name, url=url, category=cat, source_type="rss"))
                added_names.add(name)
                added_urls.add(url)
                
    # Process Research
    for feed in config.get("research", []):
        name = feed["name"]
        url = feed.get("api_endpoint", "")
        if name not in existing_names and name not in added_names and url not in existing_urls and url not in added_urls:
            db.add(Source(id=name, name=name, url=url, category="research", source_type="api"))
            added_names.add(name)
            added_urls.add(url)
            
    db.commit()

async def async_run_discovery(db: Session):
    sources_config = load_yaml("config/sources.yaml")
    topics_config = load_yaml("config/topics.yaml").get("topics", [])
    searches_config = load_yaml("config/searches.yaml").get("searches", {})
    
    ensure_sources_in_db(db, sources_config)
    
    providers = [
        DirectProvider(sources_config),
        SearchProvider(searches_config, topics_config),
        SocialProvider(sources_config.get("reddit", {}))
    ]
    
    logger.info(f"Starting Multi-Layer Discovery with {len(providers)} providers...")
    
    all_results = []
    async with aiohttp.ClientSession() as session:
        tasks = [p.discover(session) for p in providers]
        provider_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for res_group in provider_results:
            if isinstance(res_group, Exception):
                logger.error(f"Provider failed: {res_group}")
                continue
            all_results.extend(res_group)
            
    return process_results(db, all_results)

def process_results(db: Session, results: list):
    new_items_count = 0
    metrics = []
    
    # Track URLs we've added in this specific run to prevent constraint violations
    # before db.commit() is called.
    added_urls_this_run = set()
    
    for res in results:
        if isinstance(res, Exception) or not res:
            continue
            
        source = res.get("source", "unknown")
        items = res.get("items", [])
        status = res.get("status", "failed")
        time_sec = res.get("time", 0.0)
        
        added = 0
        for item in items:
            if item.url in added_urls_this_run:
                continue
                
            exists = db.query(CandidateItem).filter(CandidateItem.url == item.url).first()
            if not exists:
                db.add(item)
                added_urls_this_run.add(item.url)
                new_items_count += 1
                added += 1
                
        metrics.append({
            "source": source[:28] + '..' if len(source) > 30 else source,
            "status": status,
            "time_sec": round(time_sec, 2),
            "candidates": added
        })
        
    db.commit()
    
    # Render Metrics Table
    logger.info("="*65)
    logger.info("DISCOVERY PIPELINE METRICS")
    logger.info("="*65)
    logger.info(f"{'Source':<30} | {'Status':<15} | {'Time (s)':<8} | {'New'}")
    logger.info("-" * 65)
    for m in metrics:
        logger.info(f"{m['source']:<30} | {m['status']:<15} | {m['time_sec']:<8} | {m['candidates']}")
    logger.info("="*65)
    
    total_sources = len(metrics)
    failed_sources = sum(1 for m in metrics if m["status"] == "failed")
    
    logger.info(f"Total Sources Processed: {total_sources}")
    logger.info(f"Failed Sources: {failed_sources}")
    logger.info(f"Total New Candidates: {new_items_count}")
    logger.info("="*65)
    
    return new_items_count

def run_discovery(db: Session):
    return asyncio.run(async_run_discovery(db))
