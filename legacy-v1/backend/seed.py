from sqlalchemy.orm import Session
from models.post_model import Post, AnalysisStatus, MediaType, PostTag, Claim, TrustSignal, NewsOutlet
from models.user import User, UserRole
from security import get_password_hash
from datetime import datetime
import random

def seed_forensic_news(db: Session):
    # 1. Seed News Outlets first for the leaderboard
    if db.query(NewsOutlet).count() == 0:
        outlets = [
            {"name": "Associated Press", "domain": "apnews.com", "credibility_score": 98.5, "bias": "Neutral", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Associated_Press_logo_2012.svg/1200px-Associated_Press_logo_2012.svg.png"},
            {"name": "Reuters", "domain": "reuters.com", "credibility_score": 97.8, "bias": "Neutral", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Reuters_logo_vertical.svg/1200px-Reuters_logo_vertical.svg.png"},
            {"name": "The New York Times", "domain": "nytimes.com", "credibility_score": 85.0, "bias": "Left-Center", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/The_New_York_Times_logo.svg/1200px-The_New_York_Times_logo.svg.png"},
            {"name": "The Wall Street Journal", "domain": "wsj.com", "credibility_score": 88.2, "bias": "Right-Center", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/WSJ_Logo.svg/1200px-WSJ_Logo.svg.png"},
            {"name": "BBC News", "domain": "bbc.com", "credibility_score": 94.5, "bias": "Neutral", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/BBC_News_2019.svg/1200px-BBC_News_2019.svg.png"},
            {"name": "Al Jazeera", "domain": "aljazeera.com", "credibility_score": 82.1, "bias": "Varies", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Al_Jazeera_logo.svg/1200px-Al_Jazeera_logo.svg.png"},
            {"name": "The Guardian", "domain": "theguardian.com", "credibility_score": 86.4, "bias": "Left-Center", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/The_Guardian_2018.svg/1200px-The_Guardian_2018.svg.png"},
            {"name": "Fox News", "domain": "foxnews.com", "credibility_score": 45.2, "bias": "Right", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Fox_News_Channel_logo.svg/1200px-Fox_News_Channel_logo.svg.png"},
            {"name": "Breitbart", "domain": "breitbart.com", "credibility_score": 15.8, "bias": "Far-Right", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Breitbart_News_logo.svg/1200px-Breitbart_News_logo.svg.png"}
        ]
        for o in outlets:
            outlet = NewsOutlet(
                name=o["name"],
                domain=o["domain"],
                credibility_score=o["credibility_score"],
                bias=o["bias"],
                official_url=f"https://{o['domain']}",
                img_url=o["img_url"]
            )
            db.add(outlet)
        db.commit()
        print("News Outlets Seeded.")

    # 2. Check if pins already exist (we want 5000)
    current_count = db.query(Post).count()
    if current_count >= 5000:
        return

    # Ensure a System Editor exists
    system_user = db.query(User).filter_by(email="system@factline.ai").first()
    if not system_user:
        system_user = User(
            email="system@factline.ai",
            hashed_password=get_password_hash("123"),
            role=UserRole.editor,
            is_active=True
        )
        db.add(system_user)
        db.commit()
        db.refresh(system_user)

    # 3. Seed High-Quality Forensic News
    # Ensure a Test User exists for "My Posts" section
    test_user = db.query(User).filter_by(email="test@user.com").first()
    if not test_user:
        test_user = User(
            email="test@user.com",
            hashed_password=get_password_hash("123"),
            role=UserRole.user,
            is_active=True
        )
        db.add(test_user)
        db.commit()
        db.refresh(test_user)

    news_items = [
        # GLOBAL / BREAKING (HOME PAGE)
        {
            "title": "Quantum Supremacy Claimed: Silicon Valley Startup Reports 10,000x Speedup",
            "body": "A relatively unknown startup in Mountain View claims to have achieved quantum supremacy using a room-temperature photonic processor. While the scientific community is skeptical, the leaked benchmarks have sent tech stocks into a frenzy.",
            "media_url": "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=3000&auto=format&fit=crop",
            "media_type": MediaType.TEXT,
            "short_title": "Quantum Leap",
            "summary_easy": "Skeptical claims of quantum computing speedup.",
            "credibility_score": 42,
            "risk_type": "UNVERIFIED_TECH_CLAIM",
            "tags": ["tech", "quantum", "silicon_valley"],
            "created_by": system_user.id,
            "analysis_raw": {
                "scraped_intel": [
                    {"url": "https://techcrunch.com/quantum", "platform": "NEWS", "title": "Startups claiming supremacy", "snippet": "Several experts doubt the validity of the room-temperature claim."},
                    {"url": "https://reddit.com/r/quantum", "platform": "REDDIT", "title": "Is this legit?", "snippet": "Top comments suggest the benchmarks are heavily padded."}
                ],
                "verdict_reasoning": "Benford's analysis on leaked metrics reveals synthetic distributions."
            },
            "overall_historical_context": "Quantum computing research has been dominated by cryogenic superconducting systems (like Google/IBM). Room-temperature photonic claims are historically associated with high skepticism due to decoherence issues at higher temperatures.",
            "evidence_chain": [
                "Scraped LinkedIn profiles of founders; history of failed ventures found.",
                "Consulted with quantum physicists at MIT; room-temperature photonics is currently theoretical.",
                "Cross-referenced benchmarks; patterns match simulated data."
            ],
            "claims": [
                {
                    "text": "Achieved 10,000x speedup over current supercomputers.",
                    "verdict": "REFUTED",
                    "reason": "Benchmarks provided use synthetic data distributions that do not map to real-world complexity.",
                    "historical_context": "Previous 'supremacy' claims were usually around 50-100x; 10,000x is an unprecedented physical outlier."
                },
                {
                    "text": "Processor operates at room temperature.",
                    "verdict": "UNCERTAIN",
                    "reason": "Startup refused to allow independent thermal auditing of the core.",
                    "historical_context": "Photonic quantum computing is the only viable path for room-temp, but scaling hasn't reached stable qubit counts yet."
                }
            ]
        },
        {
            "title": "Global Trade Accord signed in Tokyo: 20 Nations reach historic agreement",
            "body": "After 14 months of intense negotiations, 20 nations have finalized the Pacific Rim Economic Partnership (PREP). The deal aims to eliminate 95% of tariffs between participating countries.",
            "media_url": "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?q=80&w=3000&auto=format&fit=crop",
            "media_type": MediaType.TEXT,
            "short_title": "Tokyo Accord",
            "summary_easy": "Major 20-nation trade deal finalized in Tokyo.",
            "credibility_score": 96,
            "risk_type": "VERIFIED_GEOPOLITICS",
            "tags": ["finance", "politics", "tokyo"],
            "created_by": system_user.id,
            "overall_historical_context": "The Pacific Rim has seen various trade blocs (TPP, CPTPP) emerge over the last decade. PREP is the most expansive attempt since 2018 to integrate Southeast Asian and South American markets.",
            "analysis_raw": {
                "scraped_intel": [
                    {"url": "https://reuters.com/business", "platform": "NEWS", "title": "Tokyo Accord Details", "snippet": "Official document released by G20 secretariat."},
                    {"url": "https://gov.jp/trade", "platform": "OFFICIAL", "title": "Japanese Ministry of Foreign Affairs", "snippet": "Press release confirming signature."}
                ]
            },
            "evidence_chain": [
                "Verified digital signatures via official government portals.",
                "Corroborated by independent reports from 5 major news bureaus.",
                "Analyzed official G20 transcripts."
            ],
            "claims": [
                {
                    "text": "20 nations are part of the agreement.",
                    "verdict": "VERIFIED",
                    "reason": "Official signatory list released by the Tokyo Secretariat.",
                    "historical_context": "This surpasses the 11 nations in CPTPP, making it the largest regional bloc."
                }
            ]
        },
        # USER POSTS (MY POSTS SECTION)
        {
            "title": "Suspected AI-Generated video of local protests goes viral",
            "body": "A video appearing to show violent clashes in the downtown district has gained millions of views. Factline analysis suggests neural manipulation of the background textures.",
            "media_url": "https://images.unsplash.com/photo-1526628953301-3e589a6a8b74?q=80&w=3000&auto=format&fit=crop",
            "media_type": MediaType.VIDEO,
            "short_title": "Protest Hoax",
            "summary_easy": "Local protest video confirmed as AI-generated deepfake.",
            "credibility_score": 12,
            "risk_type": "DEEPFAKE_MANIPULATION",
            "tags": ["local", "deepfake", "warning"],
            "created_by": test_user.id,
            "overall_historical_context": "Local tensions have been high due to recent zoning laws, providing a fertile ground for 'shallow-fake' and 'deepfake' content to incite actual unrest.",
            "analysis_raw": {
                "scraped_intel": [
                    {"url": "https://twitter.com/search?q=protest", "platform": "TWITTER", "title": "Twitter Discussion", "snippet": "Multiple reports of zero presence at shown location."},
                    {"url": "https://factcheck.org/deepfakes", "platform": "NEWS", "title": "Recent Local Deepfakes", "snippet": "Similar footage surfaced elsewhere."}
                ]
            },
            "evidence_chain": [
                "Neural audit detected 'ghosting' artifacts in crowd movements.",
                "Metadata analysis reveals footage was compiled from 2021 archives.",
                "Spatial verification shows background architectural details do not exist."
            ],
            "claims": [
                {
                    "text": "Violent clashes occurred at Main St and 5th.",
                    "verdict": "REFUTED",
                    "reason": "Live sensor data and localized reports from verified Factline users confirm the intersection was empty during the timestamp.",
                    "historical_context": "Main St and 5th was the site of actual protests in 2021, which explains the source footage found in the archives."
                }
            ]
        },
        {
            "title": "New 'Green-Battery' patent from local university promising 5x capacity",
            "body": "The local Technical University has submitted a patent for a solid-state battery using saltwater electrolytes. It could revolutionize EVs.",
            "media_url": "https://images.unsplash.com/photo-1593941707882-a5bba14938c7?q=80&w=2944&auto=format&fit=crop",
            "media_type": MediaType.TEXT,
            "short_title": "Saltwater Battery",
            "summary_easy": "Innovative saltwater-based battery technology patented.",
            "credibility_score": 82,
            "risk_type": "SCIENCE_GROUNDED",
            "tags": ["science", "energy", "local"],
            "created_by": test_user.id,
            "overall_historical_context": "Saltwater electrolytes (sodium-ion) have been studied for decades as a lithium alternative. Scalability and 'dendrite' formation in solid-state have been the primary bottlenecks.",
            "analysis_raw": {
                "scraped_intel": [
                    {"url": "https://patents.google.com/12345", "platform": "OFFICIAL", "title": "USPTO Patent DB", "snippet": "Patent application for saltwater electrolyte."},
                    {"url": "https://nature.com/energy", "platform": "NEWS", "title": "Solid State Electrolytes", "snippet": "Peer-reviewed study confirms properties."}
                ]
            },
            "evidence_chain": [
                "Found official patent filing in USPTO database.",
                "Cross-referenced with Nature Energy peer-review.",
                "Verified credentials of lead researchers."
            ],
            "claims": [
                {
                    "text": "Battery offers 5x the capacity of current lithium-ion.",
                    "verdict": "VETTED",
                    "reason": "Laboratory results support the density claim, though industrial scalability is still unproven.",
                    "historical_context": "Industry standards state that a 5x jump would put this battery ahead of the 2030 projected energy density targets."
                }
            ]
        },
        {
            "title": "Global Semiconductor Shortage Expected to Ease by Q4 2026",
            "body": "Major fabrication labs in Taiwan and South Korea report record yields of 2nm chips, leading to a projected surplus by year-end.",
            "media_url": "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=2940&auto=format&fit=crop",
            "media_type": MediaType.TEXT,
            "short_title": "Chip Surplus",
            "summary_easy": "Semiconductor supply chain recovering faster than projected.",
            "credibility_score": 90,
            "risk_type": "ECONOMIC_STABILITY",
            "tags": ["tech", "economy", "chips"],
            "created_by": system_user.id,
            "overall_historical_context": "The semiconductor shortage began in 2020 due to supply chain disruptions, leading to inflation in consumer electronics and vehicle production delays globally.",
            "evidence_chain": [
                "Audit of quarterly earnings from TSMC and Samsung.",
                "Verified shipping logs from Port of Kaohsiung.",
                "Confirmation from leading smartphone manufacturers."
            ],
            "claims": [
                {
                    "text": "2nm chip yields have reached 85%.",
                    "verdict": "VERIFIED",
                    "reason": "Internal laboratory reports confirm consistent high-yield production across three shifts.",
                    "historical_context": "Yield rates for 2nm were previously stuck at 40% throughout 2025 due to heat dissipation challenges."
                }
            ]
        },
        {
            "title": "First Successful Human Trial of Neural Link for Spinal Repair Announced",
            "body": "A medical research team in Zurich has successfully restored motor function in a paralyzed patient using a combination of bio-printing and neural-interfaces.",
            "media_url": "https://images.unsplash.com/photo-1530026405186-ed1f139313f8?q=80&w=3087&auto=format&fit=crop",
            "media_type": MediaType.TEXT,
            "short_title": "Spinal Repair",
            "summary_easy": "Breakthrough in neuro-regeneration using hybrid bio-implants.",
            "credibility_score": 95,
            "risk_type": "MEDICAL_BREAKTHROUGH",
            "tags": ["health", "science", "biotech"],
            "created_by": system_user.id,
            "overall_historical_context": "Spinal cord repair has historically been limited by the inability of central nervous system neurons to regenerate after scarring.",
            "evidence_chain": [
                "Peer-reviewed publication in The Lancet.",
                "Live demonstration at the World Neuro-Science Summit.",
                "Independent follow-up by Swiss Health Authorities."
            ],
            "claims": [
                {
                    "text": "Patient regained 70% mobility in lower limbs.",
                    "verdict": "VERIFIED",
                    "reason": "Clinical physiotherapy logs show consistent improvement and sustained limb control over 12 months.",
                    "historical_context": "Previous trials only achieved minor sensory restoration without functional motor control."
                }
            ]
        }
    ]

    for item in news_items:
        if db.query(Post).filter_by(title=item["title"]).first():
            continue
            
        post = Post(
            title=item["title"],
            body=item["body"],
            media_url=item["media_url"],
            media_type=item["media_type"],
            created_by=item["created_by"],
            analysis_status=AnalysisStatus.COMPLETED,
            analysis_progress=100.0,
            status_message="Forensic Audit Verified",
            short_title=item["short_title"],
            summary_easy=item["summary_easy"],
            credibility_score=item["credibility_score"],
            confidence_score=item["credibility_score"], # Match for now
            risk_type=item["risk_type"],
            bias="Neutral",
            sentiment="Objective",
            language="en",
            latitude=38.8977 + random.uniform(-0.1, 0.1),
            longitude=-77.0365 + random.uniform(-0.1, 0.1),
            counter_narrative=f"Verified forensic consensus: {item['summary_easy']}",
            inconsistency_highlights="Analyzed for structural and semantic anomalies.",
            historical_context=item.get("overall_historical_context"),
            analysis_raw=item.get("analysis_raw"),
            evidence_chain=item.get("evidence_chain"),
            is_breaking_news=True,
            forensic_artifacts=[] 
        )
        db.add(post)
        db.commit()
        db.refresh(post)

        # Seed Claims
        for c_data in item.get("claims", []):
            claim = Claim(
                post_id=post.id,
                text=c_data["text"],
                verdict=c_data["verdict"],
                reason=c_data["reason"],
                historical_context=c_data["historical_context"],
                credibility_score=item["credibility_score"] # Simplified
            )
            db.add(claim)
        
        db.commit()
    
    # 4. Mass Seed pins for Heatmap (up to 5000)
    current_pins = db.query(Post).count()
    pins_needed = 5000 - current_pins
    if pins_needed > 0:
        print(f"Generating {pins_needed} forensic pins for Heatmap (Land-Locked)...")
        # Define tighter land clusters (lat, lon, max_spread, avg_credibility)
        land_clusters = [
            (38.9072, -77.0369, 2.0, 75),  # East Coast USA
            (34.0522, -118.2437, 2.0, 70), # West Coast USA
            (51.5074, -0.1278, 1.5, 80),   # UK / London
            (48.8566, 2.3522, 1.5, 85),    # France / Paris
            (35.6895, 139.6917, 1.0, 90),  # Japan / Tokyo
            (20.5937, 78.9629, 3.0, 50),   # Central India
            (28.6139, 77.2090, 1.5, 55),   # North India / Delhi
            (19.0760, 72.8777, 1.5, 55),   # West India / Mumbai
            (-33.8688, 151.2093, 1.5, 85), # Australia / Sydney
            (-23.5505, -46.6333, 2.0, 60), # Brazil / Sao Paulo
            (30.0444, 31.2357, 1.5, 45),   # Egypt / Cairo
            (55.7558, 37.6173, 2.0, 40),   # Russia / Moscow
            (39.9042, 116.4074, 2.0, 45),  # China / Beijing
            (1.3521, 103.8198, 0.5, 95),   # Singapore
            (25.2048, 55.2708, 1.0, 65),   # UAE / Dubai
            (-1.2921, 36.8219, 1.5, 60),   # Kenya / Nairobi
            (37.5665, 126.9780, 1.0, 90),  # South Korea / Seoul
        ]
        
        signal_types = [
            {"title": "Neural Artifact detected in metadata", "summary": "Anomalous frequencies found in image noise floor.", "risk": "AI_GENERATED"},
            {"title": "Cross-platform narrative coordination", "summary": "Bot-net pattern detected in social dissemination.", "risk": "COORDINATED_INAUTHENTIC"},
            {"title": "Temporal inconsistency in source footage", "summary": "Shadow angles do not match reported geolocation time.", "risk": "MANIPULATED_MEDIA"},
            {"title": "Semantic drift from official source", "summary": "Content has diverged significantly from verified press release.", "risk": "MISINFORMATION"},
            {"title": "Vector misalignment in face cluster", "summary": "Potential deepfake detected using facial landmark auditing.", "risk": "DEEPFAKE"},
        ]
        
        for i in range(pins_needed):
            # Only use land clusters to avoid ocean dots
            base_lat, base_lon, spread, avg_cred = random.choice(land_clusters)
            lat = base_lat + random.uniform(-spread, spread)
            lon = base_lon + random.uniform(-spread, spread)
            cred = max(5, min(100, int(random.gauss(avg_cred, 15))))
            sig = random.choice(signal_types)

            post = Post(
                title=f"{sig['title']} #{random.randint(1000, 9999)}",
                body=f"Automated forensic audit detected a potential integrity issue at coordinates {lat:4f}, {lon:4f}.",
                media_type=random.choice([MediaType.TEXT, MediaType.IMAGE, MediaType.VIDEO]),
                created_by=system_user.id,
                analysis_status=AnalysisStatus.COMPLETED,
                analysis_progress=100.0,
                status_message="Automated Signal Grounding",
                short_title=sig['title'][:20],
                summary_easy=sig['summary'],
                credibility_score=cred,
                risk_type=sig['risk'],
                bias="Automated",
                sentiment="Neutral",
                language="en",
                latitude=lat,
                longitude=lon,
                historical_context="Regional forensic telemetry indicates an increase in similar signals over the last 48 hours.",
                evidence_chain=["Spectral analysis completed", "Geolocation cross-referenced", "Neural audit finalized"],
                forensic_artifacts=[],
                is_breaking_news=False
            )
            db.add(post)
            if i % 1000 == 0:
                db.commit()
                print(f"Archiving {i}/{pins_needed} Truth-Signals...")

        db.commit()
        print("Global Heatmap Grounding Sealed.")
