# FACTLINE INTELLIGENCE ENGINE (FIE)

## Local-First Autonomous Intelligence, Verification & Publishing Platform

### Complete System Specification

---

## 1. Product Vision

Factline Intelligence Engine (FIE) is a local-first intelligence operating system designed to discover, investigate, verify, document, and publish evidence-backed reports on emerging online discussions. The system continuously scans social media, news, research sources, public web content, and official statements. Its objective is to identify high-value discussions, perform forensic investigations, generate transparent reports, and create concise public-facing comments that direct readers toward detailed evidence pages.

- **Core Principle**: The report is the product; the comment is only a distribution mechanism.
- **System Value**: The pipeline is the core product; the dashboards exist to expose pipeline outputs.

---

## 2. Primary Goals

The system must:

- Discover emerging discussions and detect potentially important claims.
- Rank opportunities worth investigating and gather evidence recursively.
- Verify claims, generate detailed reports, and generate concise evidence-backed comments.
- Store all intelligence locally, publish approved investigations publicly, and build reusable institutional memory.

---

## 3. Hard Requirements

### Cost & Compute

- **Cost**: Operating with effectively zero recurring API costs. Prefer browser scraping, RSS feeds, public APIs, and local inference. Avoid paid APIs (OpenAI, Anthropic, Gemini, paid search APIs).
- **Compute**: Runs entirely on local hardware (primary target: Apple Silicon M5 Max, 36GB Unified Memory).

### Interface Priority

1. Intelligence Pipeline
2. CLI (Command Line Interface)
3. Local Dashboard
4. Public Dashboard

---

## 4. High-Level Architecture

```text
                    FACTLINE

┌──────────────────────────────────────┐
│      Intelligence Pipeline           │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│      Local Intelligence Database     │
│            PostgreSQL                │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│        Local Analyst Dashboard       │
└──────────────────┬───────────────────┘
                   │ (Approve Reports For Publication)
                   ▼
┌──────────────────────────────────────┐
│       Public Publishing Database     │
│              SQLite                  │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│        Public React Dashboard        │
└──────────────────────────────────────┘
```

---

## 5. Technology Stack

- **Backend**: Python 3.13+, FastAPI, Typer, SQLAlchemy 2.x, Pydantic v2, Redis, PostgreSQL, Qdrant, Playwright, LM Studio, Rich, Loguru, Docker Compose, uv
- **Frontend**: React, TypeScript, Vite, Tailwind CSS, shadcn/ui
- **Database**: PostgreSQL (Local Intelligence DB), SQLite (Public Publishing DB)

---

## 6. CLI Design

The CLI must remain extremely simple, avoiding complex command trees and manual worker orchestration.

- `factline run`: Executes the entire pipeline: Discovery → Filtering → Ranking → Investigation → Verification → Report Generation → Comment Generation → Dashboard Update → Storage.
- `factline dashboard`: Launches the local dashboard analyst workstation.
- `factline serve`: Launches both backend and dashboard services.
- `factline sync`: Exports approved reports to the public database.
- `factline status`: Checks system status.
- `factline config`: Views system configuration.

---

## 7. Pipeline Overview

The pipeline consists of 10 major sequential stages:

1. Discovery → 2. Deduplication → 3. Opportunity Ranking → 4. Opportunity Selection → 5. Claim Extraction → 6. Investigation Planning → 7. Evidence Collection → 8. Recursive Investigation → 9. Verification → 10. Report Generation

---

## 8. Discovery Pipeline

- **Sources**: Reddit, RSS feeds, news websites, research repositories, blogs, forums, official/corporate announcements, government releases, and Twitter/X browser sessions.
- **Data Model (`CandidateItem`)**: `id`, `source_type`, `source_name`, `url`, `title`, `content`, `author`, `timestamp`, `engagement`, `raw_html`, `clean_text`, `collection_timestamp`

---

## 9. Deduplication Pipeline

- **Deduplication Targets**: Duplicate posts, mirrored articles, cross-posted content, spam, advertisements, and low-information content.
- **Storage Strategy**: Mark and store duplicate relationships; do not delete duplicates.

---

## 10. Opportunity Ranking Engine

Discovered items receive an **Opportunity Score (0–100)** calculated using signals:

- **Signals**: Newsworthiness, Engagement Velocity, Claim Density, Novelty, Controversy, Research Availability, Verification Potential, Entity Importance, Public Interest, Recency, Historical Significance.

---

## 11. Opportunity Selection

Filter funnel flow example:
`5000 Discovered Items` → `500 Filtered` → `100 Ranked` → `20 Selected for Investigation`

Only selected opportunities enter the investigation stage.

---

## 12. Claim Extraction

- **Extraction Scope**: Explicit, implicit, numerical, scientific, political, financial, and geopolitical claims.
- **Data Model (`Claim`)**: `id`, `claim_text`, `claim_type`, `entities`, `origin_source`, `confidence`

---

## 13. Investigation Planning

For each claim, the system dynamically plans the investigation:

- **Questions**: What evidence is needed? Which sources should be searched? Which contradictions checked? Which entities investigated?
- **Outputs**: Investigation Plan, Search Queries, Research Tasks, Evidence Requirements.

---

## 14. Evidence Collection

- **Scope**: Articles, tweets, Reddit posts/comments, research papers, government documents, press releases, official statements, archived pages, screenshots, and metadata.
- **Rule**: Store EVERYTHING. No evidence is discarded.

---

## 15. Browser Intelligence Layer

Playwright-based browser manager.

- **Capabilities**: Session persistence, cookies, login support, screenshots, HTML/article/metadata/link extraction, content cleaning, caching, retries, rate limiting, and parallel browsing.

---

## 16. Recursive Investigation Engine

The primary investigation loop:

1.  **Analyze**: Ask what remains unknown, unsupported, or contradictory.
2.  **Act**: Generate follow-up queries/tasks and continue recursively.
3.  **Stop Conditions**: Confidence threshold reached, maximum depth reached, or evidence saturation reached.

---

## 17. Evidence Graph

A first-class object produced by every investigation:

- **Nodes**: Claims, Evidence, Sources, Entities, Reports
- **Edges**: `supports`, `contradicts`, `references`, `mentions`, `reported_by`, `derived_from`, `related_to`

---

## 18. Verification Engine

Evaluates the evidence graph to produce: Supporting/Contradicting Evidence, Open Questions, Unknowns, Risk Factors, Verdict, and Confidence Score.

- **Verdicts**: Verified, Likely True, Uncertain, Disputed, Likely False, False

---

## 19. Report Generation

Every generated report contains:

- Executive & Investigation Summaries
- Claims & Evidence Timeline
- Supporting & Contradicting Evidence
- Evidence Graph & Source Audit
- Confidence Analysis & Verdict
- Research Notes, Suggested Comments, and Transparency Section

---

## 20. Comment Generation

Produces short, medium, and long evidence-backed comments to drive readers to the report (not replace it).

- **Example**: _"Multiple independent sources support this claim, though some details remain unverified. Current confidence: 82%. Full evidence audit: https://domain.com/r/slug"_
- **Rules**: Must remain concise, mention uncertainty, and never overstate confidence.

---

## 21. Local Dashboard

The analyst workstation running locally to display complete pipeline activity.

- **1. Run History**: Displays Run ID, Start/End Time, Duration, Items Collected/Investigated, Reports Generated, Errors, and Worker Statistics.
- **2. Discovery Feed**: Displays every discovered item (Title, Source, Author, Timestamp, Engagement, Opportunity Score, Status). Clicking an item shows raw/extracted content, metadata, screenshots, and links.
- **3. Rankings**: Displays ranked opportunities with Final Score, Score Breakdown, Ranking Reasoning, and Investigation Priority.
- **4. Investigation Explorer**: Explores claims, evidence, entities, contradictions, sources, screenshots, timelines, and reasoning.
- **5. Evidence Explorer**: Searches collected evidence with filters for Source, Entity, Date, Investigation, and Confidence.
- **6. Report Review**: Shows full reports, confidence, verdicts, comment variants, source audits, and evidence graphs.
- **7. Publish Queue**: Actions to Approve, Reject, Archive, or Export reports.
- **8. Memory Explorer**: Browses claims, entities, reports, historical investigations, and relationships.

---

## 22. Publication Workflow

`Local Dashboard` → `Review Report` → `Approve Report` → `Add To Publish Queue` → `factline sync` → `Export To Public Database (SQLite)` → `Copy SQLite Database` → `Deploy To Home Server`

---

## 23. Public Database

- **Engine**: SQLite (contains ONLY approved reports; never stores internal notes, failed investigations, raw reasoning, or private data).
- **Tables**: `reports`, `report_sources`, `report_claims`, `report_evidence`, `report_screenshots`, `report_comments`

---

## 24. Public Dashboard

A read-only React-based dashboard for transparency (no intelligence processing/investigation).

- **Homepage**: Latest/trending reports, recent investigations, and search.
- **Report Page**: Headline, summary, verdict, confidence, claims, evidence, sources, screenshots, timeline, related reports, and creation/update dates.
- **Transparency Page**: All evidence, sources, source weights, collection timestamps, and verification methodology.

---

## 25. URL System

- **Base URL**: Configured via `.env` as `PUBLIC_BASE_URL` (e.g., `https://reports.factline.xyz`).
- **Report URLs**: `https://reports.factline.xyz/r/{slug}` (e.g., `https://reports.factline.xyz/r/openai-model-release-7fd3`).

---

## 26. Memory System

Maintains institutional memory for cross-investigation intelligence.

- **Storage**: Qdrant vector database (claims, entities, reports, sources, evidence, relationships).
- **Capabilities**: Similarity Search, Entity Linking, Historical Context, Investigation Reuse, and Relationship Discovery.

---

## 27. Local Model Strategy

All models run locally via LM Studio:

- **Small Models**: Classification, Deduplication, Entity Extraction, Tagging.
- **Medium Models**: Claim Extraction, Investigation Planning, Evidence Analysis.
- **Large Models**: Verification, Report/Comment Generation.

---

## 28. Storage Design

- **PostgreSQL**: Runs, candidates, rankings, investigations, claims, entities, sources, evidence, screenshots, reports, comments, relationships, graph nodes/edges.
- **Qdrant**: Vector collections for claims, reports, entities, and evidence.
- **Redis**: Job queues, worker coordination, and caching.

---

## 29. Performance Targets

- **Discovery & Ranking**: 5000+ items per run.
- **Investigations**: 10–20 high-quality investigations per run.
- **Concurrency**: 5+ concurrent browser workers.
- **Report Generation**: Under 5 minutes per report.
- **System Runtime**: Designed for continuous improvement.

---

## 30. Final Product Definition

Factline Intelligence Engine is a local-first intelligence operating system that discovers, investigates, verifies, documents, and publishes evidence-backed reports. By maintaining institutional memory and providing full transparency, it enables evidence-backed public discourse through detailed forensic reports rather than opaque AI-generated conclusions.
