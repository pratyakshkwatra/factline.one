import { useState, memo, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { motion, AnimatePresence } from "framer-motion";
import {
  Search,
  Compass,
  BookOpen,
  Clock,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  HelpCircle,
  ArrowRight,
  Database,
  ExternalLink,
  Image as ImageIcon
} from "lucide-react";
import "./index.css";

interface Report {
  id: string;
  slug: string;
  title: string;
  summary: string;
  verdict: string;
  published_at: string;
  public_url: string;
}

interface Evidence {
  url: string;
  extracted_text: string;
  source_score: number;
  screenshot_path: string | null;
}

interface Claim {
  claim_text: string;
  evidence: Evidence[];
}

interface DetailedReport {
  internal_id: string;
  public: Report;
  candidate: {
    url: string;
    title: string;
    source_name: string;
    screenshot_path: string | null;
  };
  claims: Claim[];
}

// --- Helpers ---
const getVerdictColor = (verdict: string) => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v.includes("true"))
    return "text-status-verified border-status-verified/20 bg-status-verified/10";
  if (v.includes("likely"))
    return "text-status-likely border-status-likely/20 bg-status-likely/10";
  if (v.includes("disputed"))
    return "text-status-disputed border-status-disputed/20 bg-status-disputed/10";
  if (v.includes("false"))
    return "text-status-false border-status-false/20 bg-status-false/10";
  return "text-status-uncertain border-status-uncertain/20 bg-status-uncertain/10";
};

const getVerdictIcon = (verdict: string) => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v.includes("true"))
    return <CheckCircle2 className="w-4 h-4 text-status-verified" />;
  if (v.includes("likely"))
    return <CheckCircle2 className="w-4 h-4 text-status-likely" />;
  if (v.includes("disputed"))
    return <AlertTriangle className="w-4 h-4 text-status-disputed" />;
  if (v.includes("false"))
    return <XCircle className="w-4 h-4 text-status-false" />;
  return <HelpCircle className="w-4 h-4 text-status-uncertain" />;
};

// --- Components ---
const ReportCardView = memo(
  ({ r, onSelect }: { r: Report; onSelect: (r: Report) => void }) => (
    <motion.article
      layout
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.2 }}
      className="group relative flex flex-col items-start justify-between bg-card border border-border hover:border-muted-foreground/30 p-6 sm:p-8 rounded-2xl transition-all hover:shadow-sm cursor-pointer"
      onClick={() => onSelect(r)}
    >
      <div className="flex items-center gap-x-4 text-xs mb-4">
        <time
          dateTime={r.published_at}
          className="text-muted-foreground font-mono"
        >
          {r.published_at ? new Date(r.published_at).toLocaleDateString("en-US", {
            year: "numeric",
            month: "long",
            day: "numeric",
          }) : "Pending"}
        </time>
        <div
          className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full font-medium border ${getVerdictColor(r.verdict)}`}
        >
          {getVerdictIcon(r.verdict)}
          {r.verdict}
        </div>
      </div>

      <div className="group relative">
        <h3 className="mt-3 text-2xl font-semibold leading-tight text-foreground group-hover:text-muted-foreground transition-colors">
          {r.title}
        </h3>
        <p className="mt-4 line-clamp-3 text-base leading-relaxed text-muted-foreground font-serif">
          {r.summary}
        </p>
      </div>

      <div className="relative mt-8 flex items-center gap-x-4">
        <div className="text-sm leading-6">
          <p className="font-semibold text-foreground flex items-center gap-1 group-hover:underline">
            Read Full Analysis <ArrowRight className="w-4 h-4" />
          </p>
        </div>
      </div>
    </motion.article>
  ),
);

export const App = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [activeNav, setActiveNav] = useState<
    "latest" | "methodology" | "transparency"
  >("latest");

  const { data: reportsData, isLoading: isDbLoading } = useQuery({
    queryKey: ["public-reports"],
    queryFn: async () => {
      const res = await fetch("/data/index.json");
      if (!res.ok) {
        return [];
      }
      
      const data: Report[] = await res.json();
      return data.sort((a, b) => new Date(b.published_at).getTime() - new Date(a.published_at).getTime());
    },
    refetchInterval: 5000, // Poll every 5s
  });

  const { data: detailedReport, isLoading: isDetailedLoading } = useQuery({
    queryKey: ["report-detail", selectedReport?.slug],
    queryFn: async () => {
      if (!selectedReport?.slug) return null;
      const res = await fetch(`/data/${selectedReport.slug}.json`);
      if (!res.ok) return null;
      return res.json() as Promise<DetailedReport>;
    },
    enabled: !!selectedReport?.slug,
  });

  const reports = reportsData || [];
  const isDbLoaded = !isDbLoading;

  const filteredReports = useMemo(() => {
    if (!searchQuery) return reports;
    const lowerQuery = searchQuery.toLowerCase();
    return reports.filter(
      (r) =>
        r.title.toLowerCase().includes(lowerQuery) ||
        r.summary.toLowerCase().includes(lowerQuery),
    );
  }, [reports, searchQuery]);

  return (
    <div className="min-h-screen bg-background font-sans">
      {/* Top Navigation */}
      <nav className="sticky top-0 z-50 w-full border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto max-w-7xl px-6 lg:px-8 h-16 flex items-center justify-between">
          <div
            className="flex items-center gap-2 cursor-pointer"
            onClick={() => {
              setSelectedReport(null);
              setActiveNav("latest");
            }}
          >
            <Compass className="w-6 h-6 text-primary" />
            <span className="font-bold text-xl tracking-tight">Factline</span>
          </div>
          <div className="hidden sm:flex space-x-8 text-sm font-medium text-muted-foreground">
            <button
              onClick={() => {
                setSelectedReport(null);
                setActiveNav("latest");
              }}
              className={`transition-colors ${activeNav === "latest" && !selectedReport ? "text-foreground font-semibold" : "hover:text-foreground"}`}
            >
              Latest Reports
            </button>
            <button
              onClick={() => {
                setSelectedReport(null);
                setActiveNav("methodology");
              }}
              className={`transition-colors ${activeNav === "methodology" && !selectedReport ? "text-foreground font-semibold" : "hover:text-foreground"}`}
            >
              Methodology
            </button>
            <button
              onClick={() => {
                setSelectedReport(null);
                setActiveNav("transparency");
              }}
              className={`transition-colors ${activeNav === "transparency" && !selectedReport ? "text-foreground font-semibold" : "hover:text-foreground"}`}
            >
              Transparency
            </button>
          </div>
        </div>
      </nav>

      {/* Selected Report Deep Dive View */}
      <AnimatePresence>
        {selectedReport && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            transition={{ duration: 0.4 }}
            className="mx-auto max-w-4xl px-6 lg:px-8 py-16"
          >
            <button
              onClick={() => setSelectedReport(null)}
              className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors mb-12"
            >
              ← Back to Intelligence Archive
            </button>

            <div className="flex flex-wrap items-center gap-4 text-sm mb-6">
              <time
                dateTime={selectedReport.published_at}
                className="text-muted-foreground font-mono"
              >
                {selectedReport.published_at ? new Date(selectedReport.published_at).toLocaleDateString(
                  "en-US",
                  {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                  },
                ) : "Pending"}
              </time>
              <div className="w-1 h-1 rounded-full bg-border" />
              <div className="font-mono text-muted-foreground">
                ID: {selectedReport.id.substring(0, 8)}
              </div>
            </div>

            <h1 className="text-4xl sm:text-5xl font-bold tracking-tight text-foreground font-serif leading-tight mb-8">
              {selectedReport.title}
            </h1>

            <div
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg font-bold border mb-12 text-lg ${getVerdictColor(selectedReport.verdict)}`}
            >
              {getVerdictIcon(selectedReport.verdict)}
              VERDICT: {selectedReport.verdict.toUpperCase()}
            </div>

            <div className="prose prose-invert prose-lg max-w-none font-serif text-muted-foreground leading-relaxed mb-12">
              <h3 className="text-xl font-sans font-semibold text-foreground mb-4">
                Executive Summary
              </h3>
              <p className="whitespace-pre-wrap">{selectedReport.summary}</p>
            </div>
            
            {isDetailedLoading ? (
              <div className="flex flex-col items-center justify-center py-24 opacity-50">
                <div className="w-8 h-8 border-4 border-muted-foreground border-t-primary rounded-full animate-spin mb-4"></div>
                <p className="font-medium">Loading detailed evidence graph...</p>
              </div>
            ) : detailedReport ? (
              <div className="space-y-16">
                {/* Original Source Context */}
                {detailedReport.candidate && (
                  <section className="bg-secondary/20 border border-border p-8 rounded-2xl">
                    <h3 className="text-xl font-semibold text-foreground mb-4 flex items-center gap-2">
                      <Compass className="w-5 h-5 text-muted-foreground" />
                      Original Candidate Source
                    </h3>
                    <p className="font-medium text-lg text-foreground mb-2">{detailedReport.candidate.title}</p>
                    {detailedReport.candidate.source_name && (
                      <p className="text-sm text-muted-foreground mb-4">Source: {detailedReport.candidate.source_name}</p>
                    )}
                    {detailedReport.candidate.url && (
                      <a href={detailedReport.candidate.url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-primary hover:underline text-sm mb-6">
                        <ExternalLink className="w-4 h-4" /> View Original Source
                      </a>
                    )}
                  </section>
                )}

                {/* Claims & Evidence */}
                {detailedReport.claims && detailedReport.claims.length > 0 && (
                  <section>
                    <h3 className="text-2xl font-semibold text-foreground mb-8 flex items-center gap-2">
                      <Database className="w-6 h-6 text-primary" />
                      Investigated Claims & Evidence
                    </h3>
                    <div className="space-y-12">
                      {detailedReport.claims.map((claim, idx) => (
                        <div key={idx} className="border-l-2 border-border pl-6">
                          <h4 className="text-lg font-medium text-foreground mb-6 leading-relaxed">
                            <span className="text-muted-foreground mr-2 font-mono">Claim {idx + 1}:</span>
                            {claim.claim_text}
                          </h4>
                          
                          {claim.evidence && claim.evidence.length > 0 ? (
                            <div className="grid grid-cols-1 gap-6">
                              {claim.evidence.map((ev, evIdx) => (
                                <div key={evIdx} className="bg-card border border-border rounded-xl p-5 hover:border-muted-foreground/30 transition-colors">
                                  <div className="flex justify-between items-start mb-3">
                                    <div className="flex items-center gap-2">
                                      <span className="px-2.5 py-0.5 rounded-full bg-secondary text-xs font-medium text-muted-foreground border border-border">
                                        Evidence #{evIdx + 1}
                                      </span>
                                      {ev.source_score > 0 && (
                                        <span className="text-xs text-muted-foreground font-mono">
                                          Authority Score: {ev.source_score}
                                        </span>
                                      )}
                                    </div>
                                    {ev.url && (
                                      <a href={ev.url} target="_blank" rel="noreferrer" className="text-muted-foreground hover:text-primary transition-colors">
                                        <ExternalLink className="w-4 h-4" />
                                      </a>
                                    )}
                                  </div>
                                  <p className="text-sm text-muted-foreground font-serif leading-relaxed line-clamp-4">
                                    {ev.extracted_text}
                                  </p>
                                </div>
                              ))}
                            </div>
                          ) : (
                            <p className="text-sm text-muted-foreground italic bg-secondary/30 p-4 rounded-lg">No direct evidence collected for this specific claim.</p>
                          )}
                        </div>
                      ))}
                    </div>
                  </section>
                )}
              </div>
            ) : (
              <p className="text-muted-foreground italic">Detailed evidence is not available for this report.</p>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Navigation Views (Only show if no report selected) */}
      {!selectedReport && activeNav === "methodology" && (
        <div className="mx-auto max-w-3xl px-6 lg:px-8 py-24">
          <h1 className="text-4xl font-bold tracking-tight text-foreground font-serif mb-8">
            Methodology
          </h1>
          <div className="prose prose-invert prose-lg text-muted-foreground">
            <p>
              Factline is dedicated to uncovering the truth behind emerging
              narratives by applying rigorous, evidence-based verification.
            </p>
            <h3 className="text-xl text-foreground font-semibold mt-8 mb-4">
              1. Discovering Claims
            </h3>
            <p>
              We continuously monitor global news, social media, and emerging
              narratives to identify claims that are gaining traction and
              require verification.
            </p>
            <h3 className="text-xl text-foreground font-semibold mt-8 mb-4">
              2. Isolating Facts
            </h3>
            <p>
              We separate objective, testable claims from opinions, rhetoric,
              and subjective commentary to ensure our investigations remain
              strictly factual.
            </p>
            <h3 className="text-xl text-foreground font-semibold mt-8 mb-4">
              3. Cross-Referencing Evidence
            </h3>
            <p>
              Our system cross-references each claim against primary sources,
              official records, and authoritative domains to gather
              corroborating or contradicting evidence.
            </p>
            <h3 className="text-xl text-foreground font-semibold mt-8 mb-4">
              4. Providing a Verdict
            </h3>
            <p>
              We synthesize the gathered evidence into a clear, accessible
              report with a definitive, evidence-backed verdict on the accuracy
              of the claim.
            </p>
          </div>
        </div>
      )}

      {!selectedReport && activeNav === "transparency" && (
        <div className="mx-auto max-w-3xl px-6 lg:px-8 py-24">
          <h1 className="text-4xl font-bold tracking-tight text-foreground font-serif mb-8">
            Our Commitment to Transparency
          </h1>
          <div className="prose prose-invert prose-lg text-muted-foreground">
            <p>
              We believe that trust is earned through complete transparency.
            </p>
            <div className="bg-secondary/30 border border-border rounded-xl p-6 my-8">
              <Database className="w-8 h-8 text-muted-foreground mb-4" />
              <h4 className="text-foreground font-semibold mb-2">
                Verifiable Evidence
              </h4>
              <p className="text-sm">
                Every report published on Factline includes a full breakdown of
                the primary sources and evidence used to reach a verdict. We do
                not rely on opaque editorial decisions; instead, we provide the
                raw data so you can verify the truth yourself.
              </p>
            </div>
            <p>
              Our process is open, objective, and dedicated to fighting
              misinformation by empowering readers with the facts.
            </p>
          </div>
        </div>
      )}

      {/* Hero Section & Grid (Only show if no report selected AND activeNav is latest) */}
      {!selectedReport && activeNav === "latest" && (
        <AnimatePresence>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="w-full"
          >
            <div className="relative isolate pt-24 pb-16 sm:pt-32 sm:pb-24">
              <div className="mx-auto max-w-7xl px-6 lg:px-8 text-center">
                <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-6xl font-serif">
                  Uncover the truth.
                </h1>
                <p className="mt-6 text-lg leading-8 text-muted-foreground max-w-2xl mx-auto font-sans">
                  Immutable, evidence-backed intelligence reports distributed
                  securely and transparently. Search our global archive of
                  verified investigations.
                </p>

                {/* Perplexity-style Search Bar */}
                <div className="mt-10 flex items-center justify-center">
                  <div className="relative w-full max-w-2xl group">
                    <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                      <Search className="w-5 h-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
                    </div>
                    <input
                      type="text"
                      placeholder="Ask a question or search for a report..."
                      className="w-full p-4 pl-12 text-lg bg-card border border-border rounded-full shadow-sm focus:ring-2 focus:ring-ring focus:border-transparent outline-none transition-all placeholder:text-muted-foreground"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      disabled={!isDbLoaded}
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Main Content Grid */}
            <div className="mx-auto max-w-7xl px-6 lg:px-8 pb-24">
              <div className="mx-auto max-w-2xl lg:max-w-none">
                <div className="flex items-center justify-between border-b border-border pb-4 mb-8">
                  <h2 className="text-2xl font-semibold tracking-tight">
                    {searchQuery
                      ? `Search Results (${filteredReports.length})`
                      : "Latest Intelligence"}
                  </h2>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground font-mono">
                    <Clock className="w-4 h-4" /> Updated live
                  </div>
                </div>

                {/* Empty States */}
                {!isDbLoaded && (
                  <div className="flex flex-col items-center justify-center py-24 opacity-50">
                    <div className="w-8 h-8 border-4 border-muted-foreground border-t-primary rounded-full animate-spin mb-4"></div>
                    <p className="font-medium">
                      Connecting to Intelligence Layer...
                    </p>
                  </div>
                )}

                {isDbLoaded && reports.length === 0 && (
                  <div className="flex flex-col items-center justify-center py-24 text-center">
                    <BookOpen className="w-12 h-12 text-muted-foreground mb-4 opacity-50" />
                    <h3 className="text-lg font-medium mb-1">
                      No investigations published.
                    </h3>
                    <p className="text-muted-foreground max-w-md">
                      Our analysts are currently working on active pipelines.
                      Reports will securely sync here upon completion.
                    </p>
                  </div>
                )}

                {isDbLoaded &&
                  reports.length > 0 &&
                  filteredReports.length === 0 && (
                    <div className="flex flex-col items-center justify-center py-24 text-center">
                      <Search className="w-12 h-12 text-muted-foreground mb-4 opacity-50" />
                      <h3 className="text-lg font-medium mb-1">
                        No results found
                      </h3>
                      <p className="text-muted-foreground">
                        Try adjusting your search criteria or browsing the
                        latest reports.
                      </p>
                    </div>
                  )}

                {/* Report Grid */}
                <div className="grid grid-cols-1 gap-x-8 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
                  <AnimatePresence>
                    {filteredReports.map((r) => (
                      <ReportCardView
                        key={r.id}
                        r={r}
                        onSelect={setSelectedReport}
                      />
                    ))}
                  </AnimatePresence>
                </div>
              </div>
            </div>
          </motion.div>
        </AnimatePresence>
      )}
    </div>
  );
};
