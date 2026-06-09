import os
from playwright.sync_api import sync_playwright
from loguru import logger

def collect_evidence_from_url(url: str, investigation_id: str):
    logger.info(f"Collecting evidence from {url} via Playwright")
    
    screenshot_dir = f"storage/screenshots/{investigation_id}"
    html_dir = f"storage/html/{investigation_id}"
    os.makedirs(screenshot_dir, exist_ok=True)
    os.makedirs(html_dir, exist_ok=True)
    
    screenshot_path = f"{screenshot_dir}/screenshot.png"
    html_path = f"{html_dir}/raw.html"
    
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            page.set_extra_http_headers({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
            page.goto(url, timeout=15000)
            
            title = page.title()
            
            # Store Screenshot
            page.screenshot(path=screenshot_path, full_page=True)
            
            # Store HTML
            raw_html = page.content()
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(raw_html)
                
            # Simple text extraction for DB storage
            text_content = page.evaluate("() => document.body.innerText")
            
            browser.close()
            return title, text_content, html_path, screenshot_path
    except Exception as e:
        logger.error(f"Playwright error on {url}: {e}")
        return "", "", None, None
