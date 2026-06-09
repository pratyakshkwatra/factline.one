import time
import uuid
import urllib.parse
from datetime import datetime
from loguru import logger
from app.models.database import CandidateItem
from app.services.discovery_providers.base import BaseDiscoveryProvider

class SearchProvider(BaseDiscoveryProvider):
    def __init__(self, searches_config: dict, topics_config: list):
        self.searches = searches_config
        self.topics = [t["name"] for t in topics_config]
        
    async def fetch_ddg(self, query):
        items = []
        start_time = time.time()
        url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote(query)}"
        try:
            from playwright.async_api import async_playwright
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                await page.goto(url, timeout=15000)
                
                results = await page.query_selector_all(".result__body")
                for result in results[:5]:
                    title_el = await result.query_selector(".result__title .result__a")
                    snippet_el = await result.query_selector(".result__snippet")
                    
                    title = await title_el.inner_text() if title_el else ""
                    link = await title_el.get_attribute("href") if title_el else ""
                    snippet = await snippet_el.inner_text() if snippet_el else ""
                    
                    if link.startswith("//"):
                        link = "https:" + link
                        
                    items.append(CandidateItem(
                        id=str(uuid.uuid4()),
                        source_type="search",
                        source_name="DuckDuckGo",
                        url=link,
                        title=title,
                        content=snippet,
                        clean_text=snippet,
                        author="search_engine",
                        timestamp=datetime.utcnow(),
                        status="discovered",
                        source_metadata={"query": query, "provider": "DuckDuckGo"}
                    ))
                await browser.close()
            status = "success"
        except Exception as e:
            logger.warning(f"Search failed for '{query}': {e}")
            status = "failed"
            
        return {"source": f"Search: {query}", "items": items, "status": status, "time": time.time() - start_time}

    async def discover(self, session):
        import asyncio
        queries = []
        for cat in self.searches.get("categories", []):
            queries.append(cat)
        for top in self.topics:
            queries.append(f"{top} news")
            
        tasks = [self.fetch_ddg(q) for q in queries[:5]] # limit to 5 to avoid spamming
        return await asyncio.gather(*tasks, return_exceptions=True)
