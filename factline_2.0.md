# FACTLINE INTELLIGENCE ENGINE (FIE)
## Human-Guided Intelligence Investigation Platform
### Complete System Specification (V2.1)

---

# 1. PRODUCT VISION
Factline is a local-first intelligence investigation platform. It is not a social media discovery engine, RSS reader, or autonomous content farm. The user discovers potentially interesting content and provides the starting signal. Factline performs the investigation, recursive evidence collection, source analysis, verification, report generation, and publication.
The final product features:
- Transparent investigation reports
- Evidence-backed conclusions
- Publicly shareable research
- Full source transparency

---

# 2. CORE PRINCIPLE & FLOW
1. **User finds & submits content**: Reddit/X post, news article, LinkedIn post, Hacker News discussion, YouTube video, government statement, research paper, or forum discussion.
2. **Factline investigates**: Crawls, gathers evidence recursively, and verifies.
3. **Factline outputs**: Generates a report, a shareable comment, and publishes findings.

---

# 3. PRIMARY GOALS
- Investigate claims & verify information
- Collect evidence & build evidence graphs
- Generate transparent reports & concise comments
- Maintain institutional memory & provide full source traceability
*Note: Factline does not depend on discovering content automatically.*

---

# 4. SYSTEM ARCHITECTURE
`User Input` ➔ `Investigation Engine` ➔ `Local DB (PostgreSQL)` ➔ `Local Dashboard` ➔ `Human Review` ➔ `Public SQLite DB` ➔ `Public Dashboard`

---

# 5. INVESTIGATION INPUTS
- **URLs**: Reddit/X posts, news articles, research papers, government releases.
- **Raw Text**: Copied posts, discussions, or comments.
- **Screenshots**: Tweets, posts, comments, or articles.
- **Mixed Inputs**: Combination of URL + Comments + Notes + Screenshots.

---

# 6. CLI & COMMANDS
- **Primary Command**: `factline investigate` (interactive mode prompts for URL, post, comments, notes)
- **Direct Command**: `factline investigate <url>`
- **Management Commands**:
  - `factline dashboard`: Launch analyst workspace.
  - `factline serve`: Start backend & dashboard services.
  - `factline sync`: Export approved reports to public SQLite.
  - `factline status`: Check system health.
  - `factline config`: View configuration.
*Note: Discovery is optional; investigation is primary.*

---

# 7. PIPELINE
`Submission` ➔ `Content Extraction` ➔ `Claim Extraction` ➔ `Investigation Planning` ➔ `Query Generation` ➔ `Evidence Collection` ➔ `Recursive Investigation` ➔ `Evidence Graph Construction` ➔ `Verification` ➔ `Report Generation` ➔ `Comment Generation` ➔ `Publication`

---

# 8. CLAIM EXTRACTION
- **Extract**: Explicit, implicit, numerical, financial, geopolitical, and scientific claims.
- **Store**: Claim text, entities, confidence, claim type, and origin source.

---

# 9. INVESTIGATION PLANNING
For every claim, determine:
- Evidence required & primary, government, or research sources.
- Contradictions and entities to investigate.
- Generate search, browsing, and verification tasks.

---

# 10. SEARCH GENERATION
Generate targeted search queries (e.g., Claim: *"OpenAI released GPT-6"* ➔ Queries: *"OpenAI GPT-6 official announcement"*, *"OpenAI GPT-6 release Reuters"*, etc.).
- **Search Providers**: Google (via Playwright), DuckDuckGo, Bing.

---

# 11. PLAYWRIGHT INVESTIGATION ENGINE
First-class subsystem with capabilities:
- **Search**: DuckDuckGo, Google, Bing.
- **Extraction**: Article text, metadata, screenshot capture, links, and structured content.
- **Recursive Crawling**: Visit discovered sources, follow citations, references, and linked evidence.

---

# 12. EVIDENCE COLLECTION
Collect and store everything (no evidence discarded):
- News articles, government documents, research papers, official statements, press releases, blog/forum posts.
- Referenced links, screenshots, metadata, and raw HTML.

---

# 13. RECURSIVE INVESTIGATION
- **Loop**: Starting from a single post: `Search` ➔ `Collect Evidence` ➔ `Extract Entities/References` ➔ `Generate New Searches` ➔ `Collect More Evidence` ➔ `Repeat`.
- **Stop Conditions**: Confidence threshold reached, evidence saturation reached, or depth limit reached.

---

# 14. EVIDENCE GRAPH
- **Nodes**: Claims, Sources, Evidence, Entities, Reports, Investigations.
- **Edges**: `supports`, `contradicts`, `references`, `mentions`, `derived_from`, `reported_by`, `related_to`.
*Note: The Graph is a first-class object.*

---

# 15. VERIFICATION ENGINE
- **Outputs**: Supporting/contradicting evidence, open questions, unknowns, risk factors, confidence score, and verdict.
- **Verdicts**: `Verified`, `Likely True`, `Uncertain`, `Disputed`, `Likely False`, `False`.

---

# 16. REPORT GENERATION
Reports contain:
- Executive Summary & Original Submission (with comments)
- Investigation Summary, Claims, Evidence Timeline
- Supporting & Contradicting Evidence, Evidence Graph, Source Audit
- Confidence Analysis, Verdict, Research Notes, Transparency Section, and Generated Comments.

---

# 17. COMMENT GENERATION
Purpose: Drive readers to the report (not replace it).
- **Format**: Concise, communicates uncertainty, links to report.
- **Example**: *"I investigated this claim using primary sources, government releases, research papers, and independent reporting. Current assessment: Likely True (84% confidence). Full evidence audit: https://reports.factline.xyz/r/example"*

---

# 18. LOCAL DASHBOARD
The analyst workstation UI containing:
- **Home**: Active/completed investigations, published reports, recent activity, metrics.
- **New Investigation**: Form accepting URL, text, comments, screenshots, and notes.
- **Queue**: States: `Pending`, `Running`, `Completed`, `Published`, `Failed`.
- **Workspace**: Shows original post, claims, searches, sources, screenshots, evidence graph, contradictions, confidence, verdict, generated comments, and draft report.
- **Evidence Explorer**: Search/filter all evidence by source, date, investigation, confidence, entity.
- **Report Review**: Review, edit metadata, approve, reject, generate publication URL.
- **Publish Queue**: Manage publication workflow.
- **Memory Explorer**: Browse claims, entities, investigations, relationships, historical reports.

---

# 19. DATABASE (PostgreSQL Tables)
`investigation_inputs`, `submitted_urls`, `submitted_posts`, `submitted_comments`, `uploaded_images`, `investigations`, `claims`, `entities`, `sources`, `evidence`, `screenshots`, `search_queries`, `search_results`, `reports`, `comments`, `graph_nodes`, `graph_edges`, `relationships`.

---

# 20. MEMORY (Qdrant Vector DB)
Stores: claims, entities, evidence, reports, investigations.
Capabilities: Similarity search, entity linking, historical context, investigation reuse.

---

# 21. LOCAL MODEL STRATEGY (LM Studio)
- **MODEL_SMALL**: Classification, Tagging, Entity Extraction, Search Generation.
- **MODEL_MEDIUM**: Claim Extraction, Investigation Planning, Evidence Analysis, Contradiction Detection.
- **MODEL_LARGE**: Verification, Report Generation, Comment Generation.

---

# 22. PUBLICATION WORKFLOW
`Investigation` ➔ `Report` ➔ `Review` ➔ `Approve` ➔ `factline sync` ➔ `Public SQLite` ➔ `Home Server` ➔ `Public Dashboard`

---

# 23. PUBLIC DATABASE (SQLite)
Approved reports only. Never stores internal notes, draft investigations, private data, or reasoning traces.

---

# 24. PUBLIC DASHBOARD
Research publication platform (not an admin dashboard):
- **Homepage**: Latest & trending reports, search, categories.
- **Report Page**: Title, summary, verdict, confidence, original submission, timeline, evidence, sources, screenshots, evidence graph, related reports, transparency section.

---

# 25. URL SYSTEM
- **PUBLIC_BASE_URL**: e.g., `https://reports.factline.xyz`
- **Report URLs**: `https://reports.factline.xyz/r/{slug}`

---

# 26. OPTIONAL DISCOVERY MODULE
- Supports monitoring: RSS, news, government sources, research sources, Reddit, search queries.
- May generate investigation suggestions, but user-submitted investigation remains the primary workflow.

---

# 27. PERFORMANCE TARGETS
- **Volume**: 1–20 investigations per run; 50–500 evidence items per investigation.
- **Concurrency**: 5+ concurrent browser workers.
- **Speed**: Full investigation (5–20 mins), Report generation (< 2 mins), Real-time dashboard updates.

---

# 28. FINAL PRODUCT DEFINITION
Factline is a human-guided intelligence investigation platform that transforms a single URL, post, discussion, or claim into a transparent, evidence-backed investigation report through recursive web research, source verification, evidence graph construction, and human-reviewed publication.
