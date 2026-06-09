import time
import uuid
from datetime import datetime
import feedparser
from loguru import logger
from app.models.database import CandidateItem
from app.services.discovery_providers.base import BaseDiscoveryProvider

class DirectProvider(BaseDiscoveryProvider):
    def __init__(self, sources_config: dict):
        self.sources = []
        for cat, feeds in sources_config.get("rss", {}).items():
            self.sources.extend(feeds)
        for cat, feeds in sources_config.get("research", {}).items():
            self.sources.extend(feeds)
            
    async def fetch_feed(self, session, feed):
        items = []
        start_time = time.time()
        try:
            url = feed.get('url') or feed.get('api_endpoint')
            if not url:
                return {"source": feed['name'], "items": [], "status": "failed", "time": 0}
                
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                'Accept': 'application/rss+xml, application/xml, text/xml, */*'
            }
            async with session.get(url, headers=headers, timeout=15) as response:
                response.raise_for_status()
                content = await response.text()
                
                parsed = feedparser.parse(content)
                for entry in parsed.entries[:5]:
                    title = entry.get('title', '')
                    link = entry.get('link', '')
                    desc = entry.get('description', '') or entry.get('summary', '')
                    
                    items.append(CandidateItem(
                        id=str(uuid.uuid4()),
                        source_type="direct",
                        source_name=feed['name'],
                        url=link,
                        title=title,
                        content=desc,
                        clean_text=desc,
                        author=feed['name'],
                        timestamp=datetime.utcnow(),
                        status="discovered",
                        source_metadata={"category": "direct"}
                    ))
            status = "success"
        except Exception as e:
            logger.warning(f"Failed Direct Source {feed['name']}: {e}")
            status = "failed"
            
        elapsed = time.time() - start_time
        return {"source": feed['name'], "items": items, "status": status, "time": elapsed}

    async def discover(self, session):
        import asyncio
        tasks = [self.fetch_feed(session, f) for f in self.sources]
        return await asyncio.gather(*tasks, return_exceptions=True)
