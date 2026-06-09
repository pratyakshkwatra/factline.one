import typer
import requests
from rich.console import Console
from loguru import logger
from sqlalchemy.exc import OperationalError
from typing import Optional

from app.models.database import SessionLocal, init_db
from app.services.discovery import run_discovery
from app.services.ranking import rank_candidates
from app.services.extraction import extract_claims
from app.services.investigation import run_investigation
from app.services.report import generate_reports

app = typer.Typer(help="Factline Intelligence Engine (FIE) CLI")
console = Console()

def notify_ui():
    try:
        requests.post("http://localhost:8000/api/v1/notify", timeout=1)
    except Exception:
        pass # Ignore if API isn't running

@app.command()
def run():
    """
    Executes the entire Factline pipeline: Discovery -> Ranking -> Extraction -> Investigation -> Report Generation.
    """
    console.print("[bold blue]Starting Factline Intelligence Pipeline...[/bold blue]")
    
    try:
        init_db()
    except OperationalError as e:
        console.print("[red]Database connection failed. Is PostgreSQL running?[/red]")
        logger.error(e)
        return

    db = SessionLocal()
    try:
        # Phase 1: Discovery
        console.print("[bold cyan]1. Discovery Phase[/bold cyan]")
        new_items = run_discovery(db)
        console.print(f"[green]✓ Discovery complete. Found {new_items} new items.[/green]")
        notify_ui()

        # Phase 2: Ranking
        console.print("\n[bold cyan]2. Ranking Phase[/bold cyan]")
        ranked_items = rank_candidates(db)
        console.print(f"[green]✓ Ranking complete. Scored {ranked_items} opportunities.[/green]")
        notify_ui()

        # Phase 3: Extraction
        console.print("\n[bold cyan]3. Claim Extraction Phase[/bold cyan]")
        extracted_claims = extract_claims(db)
        console.print(f"[green]✓ Extraction complete. Found {extracted_claims} claims.[/green]")
        notify_ui()

        # Phase 4: Investigation & Evidence Collection
        console.print("\n[bold cyan]4. Investigation & Evidence Collection[/bold cyan]")
        investigated = run_investigation(db)
        console.print(f"[green]✓ Investigation complete. Collected evidence for {investigated} claims.[/green]")
        notify_ui()

        # Phase 5: Report Generation
        console.print("\n[bold cyan]5. Report Generation Phase[/bold cyan]")
        reports = generate_reports(db)
        console.print(f"[green]✓ Report generation complete. Created {reports} transparency reports.[/green]")
        notify_ui()

    finally:
        db.close()
        
    console.print("\n[bold blue]Pipeline execution cycle complete![/bold blue]")

@app.command()
def investigate(url: Optional[str] = typer.Argument(None, help="Optional URL to automatically fetch and investigate")):
    """
    Start a new human-guided investigation. Provides an interactive prompt if no URL is specified.
    """
    console.print("[bold blue]Factline Investigation Engine[/bold blue]")
    
    from app.models.database import SessionLocal, InvestigationInput, SubmittedUrl, OriginalPost, OriginalComment
    import uuid
    from datetime import datetime
    
    db = SessionLocal()
    
    try:
        if url:
            console.print(f"[cyan]Automatically fetching and investigating URL: {url}[/cyan]")
            
            new_input_id = str(uuid.uuid4())
            new_input = InvestigationInput(
                id=new_input_id,
                input_type="url",
                status="pending",
                created_at=datetime.utcnow()
            )
            db.add(new_input)
            
            submitted_url = SubmittedUrl(id=str(uuid.uuid4()), input_id=new_input_id, url=url)
            db.add(submitted_url)
            
            db.commit()
            console.print("[green]Investigation task submitted to queue.[/green]")
        else:
            console.print("[bold yellow]Interactive Investigation Mode[/bold yellow]")
            console.print("Paste your context below to begin an investigation. Press Enter to skip optional fields.")
            
            input_url = typer.prompt("URL (optional)", default="", show_default=False)
            post_content = typer.prompt("Post content", default="", show_default=False)
            comments = typer.prompt("Comments (optional)", default="", show_default=False)
            notes = typer.prompt("Investigation notes (optional)", default="", show_default=False)
            
            console.print("\n[bold cyan]Submitting investigation...[/bold cyan]")
            
            new_input_id = str(uuid.uuid4())
            new_input = InvestigationInput(
                id=new_input_id,
                input_type="mixed",
                status="pending",
                notes=notes,
                created_at=datetime.utcnow()
            )
            db.add(new_input)
            
            if input_url:
                db.add(SubmittedUrl(id=str(uuid.uuid4()), input_id=new_input_id, url=input_url))
            
            if post_content:
                db.add(OriginalPost(id=str(uuid.uuid4()), input_id=new_input_id, content=post_content))
                
            db.commit()
            console.print("[green]Investigation task submitted to queue.[/green]")
            notify_ui()
            
    except Exception as e:
        console.print(f"[red]Error submitting investigation: {e}[/red]")
        db.rollback()
    finally:
        db.close()

@app.command()
def dashboard():
    """Launches the local dashboard analyst workstation."""
    console.print("[yellow]Please use the root launcher: ./factline serve[/yellow]")

@app.command()
def serve():
    """Launches both backend and dashboard services."""
    console.print("[yellow]Please use the root launcher: ./factline serve[/yellow]")

@app.command()
def sync():
    """Exports approved reports to the public dashboard data directory as JSON."""
    console.print("[bold blue]Syncing reports to public dashboard JSON...[/bold blue]")
    try:
        from app.models.database import SessionLocal, CandidateItem
        from app.services.report import Report
        from app.services.extraction import Claim
        from app.services.investigation import Evidence
        import os
        import json

        db = SessionLocal()
        reports = db.query(Report).filter(Report.public_url.isnot(None)).all()
        
        data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "..", "factline.one", "public", "data")
        os.makedirs(data_dir, exist_ok=True)
        
        index_data = []
        synced = 0
        
        for r in reports:
            slug = r.public_url.split("/r/")[-1] if r.public_url and "/r/" in r.public_url else r.id
            
            # Formatting published_at properly if needed
            published_at = r.created_at.isoformat() if hasattr(r, 'created_at') and r.created_at else ""
            
            public_payload = {
                "id": r.id,
                "slug": slug,
                "title": r.title,
                "summary": r.summary,
                "verdict": r.verdict,
                "published_at": published_at,
                "public_url": r.public_url
            }
            
            # Fetch Candidate
            candidate = db.query(CandidateItem).filter(CandidateItem.id == r.candidate_id).first()
            candidate_payload = {}
            if candidate:
                candidate_payload = {
                    "url": candidate.url,
                    "title": candidate.title,
                    "source_name": candidate.source_name,
                    "screenshot_path": candidate.screenshot_path
                }
                
            # Fetch Claims & Evidence
            claims = db.query(Claim).filter(Claim.candidate_id == r.candidate_id).all()
            claims_payload = []
            for c in claims:
                evidence_list = db.query(Evidence).filter(Evidence.claim_id == c.id).all()
                evidence_payload = []
                for ev in evidence_list:
                    evidence_payload.append({
                        "url": ev.url,
                        "extracted_text": ev.extracted_text,
                        "source_score": ev.source_score,
                        "screenshot_path": ev.screenshot_path
                    })
                claims_payload.append({
                    "claim_text": c.claim_text,
                    "evidence": evidence_payload
                })
            
            # The full JSON file format
            full_payload = {
                "internal_id": r.id,
                "public": public_payload,
                "candidate": candidate_payload,
                "claims": claims_payload
            }
            
            # Write individual slug JSON
            slug_path = os.path.join(data_dir, f"{slug}.json")
            with open(slug_path, "w", encoding="utf-8") as f:
                json.dump(full_payload, f, indent=2)
                
            index_data.append(public_payload)
            synced += 1
            
        # Write index.json containing all reports
        index_path = os.path.join(data_dir, "index.json")
        with open(index_path, "w", encoding="utf-8") as f:
            json.dump(index_data, f, indent=2)
            
        db.close()
        console.print(f"[green]✓ Successfully synced {synced} reports to JSON in public/data.[/green]")
    except Exception as e:
        console.print(f"[red]Failed to sync: {e}[/red]")

@app.command()
def status():
    """Checks system status."""
    console.print("[bold blue]Checking Factline system status...[/bold blue]")
    try:
        from app.models.database import SessionLocal
        from sqlalchemy import text
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        console.print("[green]✓ PostgreSQL Database: Online[/green]")
    except Exception:
        console.print("[red]✗ PostgreSQL Database: Offline[/red]")
        
    try:
        import requests
        res = requests.get("http://localhost:8000/api/v1/candidates", timeout=2)
        if res.status_code == 200:
            console.print("[green]✓ Intelligence Engine API: Online (http://localhost:8000)[/green]")
        else:
            console.print("[yellow]⚠ Intelligence Engine API: Unexpected Response[/yellow]")
    except Exception:
        console.print("[red]✗ Intelligence Engine API: Offline[/red]")

if __name__ == "__main__":
    app()
