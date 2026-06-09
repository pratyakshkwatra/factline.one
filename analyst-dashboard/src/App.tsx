import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { motion, AnimatePresence } from "framer-motion";
import { useWebSocket } from "./hooks/useWebSocket";
import {
  Activity,
  Search,
  Database,
  ShieldAlert,
  FileText,
  Network,
  Menu,
  ChevronRight,
  ExternalLink,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  HelpCircle,
  PlusCircle,
} from "lucide-react";
import "./index.css";

// --- Types ---
interface Candidate {
  id: string;
  url: string;
  source_name: string;
  title: string;
  opportunity_score: number;
}
interface Report {
  id: string;
  title: string;
  verdict: string;
  summary: string;
  public_url?: string;
}
interface Evidence {
  id: string;
  url: string;
  extracted_text: string;
  source_score: number;
  screenshot_path?: string;
}
interface Investigation {
  id: string;
  search_query: string;
  status: string;
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

export const App = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState("overview");

  // Connect to websocket to automatically trigger invalidations
  useWebSocket("ws://localhost:8000/api/v1/ws");

  const { data: candidatesData } = useQuery({
    queryKey: ['candidates'],
    queryFn: async () => {
      const res = await fetch("http://localhost:8000/api/v1/candidates");
      if (!res.ok) throw new Error("Failed to fetch");
      return res.json();
    }
  });

  const { data: reportsData, refetch: refetchReports } = useQuery({
    queryKey: ['reports'],
    queryFn: async () => {
      const res = await fetch("http://localhost:8000/api/v1/reports");
      if (!res.ok) throw new Error("Failed to fetch");
      return res.json();
    }
  });

  const { data: evidenceData } = useQuery({
    queryKey: ['evidence'],
    queryFn: async () => {
      const res = await fetch("http://localhost:8000/api/v1/evidence");
      if (!res.ok) throw new Error("Failed to fetch");
      return res.json();
    }
  });

  const { data: investigationsData } = useQuery({
    queryKey: ['investigations'],
    queryFn: async () => {
      const res = await fetch("http://localhost:8000/api/v1/investigations");
      if (!res.ok) throw new Error("Failed to fetch");
      return res.json();
    }
  });

  const candidates: Candidate[] = candidatesData?.candidates || [];
  const reports: Report[] = reportsData?.reports || [];
  const evidence: Evidence[] = evidenceData?.evidence || [];
  const investigations: Investigation[] = investigationsData?.investigations || [];

  const handlePublish = async (reportId: string) => {
    try {
      const res = await fetch(
        `http://localhost:8000/api/v1/publish/${reportId}`,
        { method: "POST" },
      );
      if (res.ok) refetchReports();
    } catch (e) {
      console.error("Publish error:", e);
    }
  };

  // --- Filtering ---
  const lowerQuery = searchQuery.toLowerCase();
  const filteredCandidates = useMemo(
    () =>
      candidates.filter(
        (c) =>
          c.title.toLowerCase().includes(lowerQuery) ||
          c.source_name.toLowerCase().includes(lowerQuery),
      ),
    [candidates, lowerQuery],
  );
  const filteredReports = useMemo(
    () =>
      reports.filter(
        (r) =>
          r.title.toLowerCase().includes(lowerQuery) ||
          r.summary.toLowerCase().includes(lowerQuery),
      ),
    [reports, lowerQuery],
  );
  const filteredInvestigations = useMemo(
    () =>
      investigations.filter((i) =>
        i.search_query.toLowerCase().includes(lowerQuery),
      ),
    [investigations, lowerQuery],
  );

  // --- UI Components ---
  const SidebarItem = ({ icon: Icon, label, id }: any) => (
    <button
      onClick={() => setActiveTab(id)}
      className={`w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === id ? "bg-secondary text-foreground" : "text-muted-foreground hover:bg-secondary/50 hover:text-foreground"}`}
    >
      <Icon className="w-4 h-4" />
      {label}
    </button>
  );

  return (
    <div className="flex h-screen bg-background text-foreground overflow-hidden font-sans">
      {/* LEFT SIDEBAR */}
      <aside className="w-64 border-r border-border bg-card flex flex-col">
        <div className="p-4 border-b border-border flex items-center gap-2">
          <Activity className="w-5 h-5 text-primary" />
          <h1 className="font-semibold tracking-tight text-lg">Factline OS</h1>
        </div>

        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2 px-3 mt-4">
            Workspace
          </div>
          <SidebarItem icon={PlusCircle} label="New Investigation" id="new_investigation" />
          <SidebarItem icon={Database} label="Overview" id="overview" />
          <SidebarItem icon={Search} label="Discovery Feed" id="discovery" />
          <SidebarItem
            icon={ShieldAlert}
            label="Investigations"
            id="investigations"
          />
          <SidebarItem icon={FileText} label="Report Review" id="reports" />
          <SidebarItem icon={Network} label="Source Explorer" id="memory" />
        </nav>

        <div className="p-4 border-t border-border">
          <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground">
            <div className="w-2 h-2 rounded-full bg-status-verified animate-pulse"></div>
            System Online
          </div>
        </div>
      </aside>

      {/* MAIN WORKSPACE */}
      <main className="flex-1 flex flex-col min-w-0 bg-background relative">
        {/* Topbar Search */}
        <header className="h-14 border-b border-border flex items-center px-4 bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-10">
          <Menu className="w-5 h-5 text-muted-foreground mr-4 lg:hidden" />
          <div className="flex-1 flex items-center relative">
            <Search className="w-4 h-4 text-muted-foreground absolute left-3" />
            <input
              type="text"
              placeholder="Search global workspace (Cmd+K)"
              className="w-full pl-9 pr-4 py-1.5 text-sm bg-secondary border-transparent rounded-md focus:border-ring focus:ring-1 focus:ring-ring outline-none transition-all placeholder:text-muted-foreground"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </header>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-6 md:p-8">
          {/* OVERVIEW TAB */}
          {activeTab === "overview" && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }} className="max-w-6xl mx-auto space-y-8">
              <div>
                <h2 className="text-2xl font-semibold tracking-tight">
                  Intelligence Overview
                </h2>
                <p className="text-muted-foreground text-sm mt-1">
                  High-level metrics for the current operational cycle.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="p-4 rounded-xl border border-border bg-card">
                  <div className="text-sm font-medium text-muted-foreground mb-1">
                    Discovery Candidates
                  </div>
                  <div className="text-3xl font-bold">{candidates.length}</div>
                </div>
                <div className="p-4 rounded-xl border border-border bg-card">
                  <div className="text-sm font-medium text-muted-foreground mb-1">
                    Active Queries
                  </div>
                  <div className="text-3xl font-bold">
                    {investigations.length}
                  </div>
                </div>
                <div className="p-4 rounded-xl border border-border bg-card">
                  <div className="text-sm font-medium text-muted-foreground mb-1">
                    Evidence Artifacts
                  </div>
                  <div className="text-3xl font-bold">{evidence.length}</div>
                </div>
                <div className="p-4 rounded-xl border border-border bg-card">
                  <div className="text-sm font-medium text-muted-foreground mb-1">
                    Generated Reports
                  </div>
                  <div className="text-3xl font-bold">{reports.length}</div>
                </div>
              </div>
            </motion.div>
          )}

          {/* NEW INVESTIGATION TAB */}
          {activeTab === "new_investigation" && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }} className="max-w-4xl mx-auto space-y-8">
              <div>
                <h2 className="text-2xl font-semibold tracking-tight">
                  New Investigation
                </h2>
                <p className="text-muted-foreground text-sm mt-1">
                  Submit a URL, text, or context to initiate a human-guided autonomous investigation.
                </p>
              </div>

              <form className="space-y-6 bg-card border border-border rounded-xl p-6 shadow-sm" onSubmit={(e) => { e.preventDefault(); setActiveTab('investigations'); }}>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">Primary URL (Optional)</label>
                    <input type="text" placeholder="https://..." className="w-full px-3 py-2 bg-secondary border border-border rounded-md text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Post Content or Claim</label>
                    <textarea rows={4} placeholder="Paste the claim or original post text here..." className="w-full px-3 py-2 bg-secondary border border-border rounded-md text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"></textarea>
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Original Comments or Discussion Context</label>
                    <textarea rows={3} placeholder="Paste relevant comments or context..." className="w-full px-3 py-2 bg-secondary border border-border rounded-md text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"></textarea>
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Investigation Notes</label>
                    <textarea rows={2} placeholder="What should the agents focus on?" className="w-full px-3 py-2 bg-secondary border border-border rounded-md text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"></textarea>
                  </div>
                </div>

                <div className="pt-4 flex justify-end">
                  <button type="submit" className="bg-primary text-primary-foreground hover:bg-primary/90 px-6 py-2 rounded-md font-medium transition-colors shadow-sm">
                    Begin Investigation
                  </button>
                </div>
              </form>
            </motion.div>
          )}

          {/* REPORTS TAB */}
          {activeTab === "reports" && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }} className="max-w-6xl mx-auto space-y-6">
              <div className="flex justify-between items-end">
                <div>
                  <h2 className="text-2xl font-semibold tracking-tight">
                    Report Review
                  </h2>
                  <p className="text-muted-foreground text-sm mt-1">
                    Approve or reject generated intelligence reports.
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  {filteredReports.length} pending
                </div>
              </div>

              <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                <AnimatePresence>
                  {filteredReports.map((r) => (
                    <motion.div
                      layout
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      transition={{ duration: 0.2 }}
                      key={r.id}
                      className="flex flex-col bg-card border border-border rounded-xl overflow-hidden hover:border-muted-foreground/30 transition-colors shadow-sm"
                    >
                      <div className="p-5 flex-1">
                        <div className="flex justify-between items-start mb-3 gap-4">
                          <h3 className="font-semibold text-lg leading-snug">
                            {r.title}
                          </h3>
                          <div
                            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border whitespace-nowrap ${getVerdictColor(r.verdict)}`}
                          >
                            {getVerdictIcon(r.verdict)}
                            {r.verdict}
                          </div>
                        </div>
                        <p className="text-sm text-muted-foreground leading-relaxed">
                          {r.summary}
                        </p>
                      </div>
                      <div className="px-5 py-3 border-t border-border bg-secondary/30 flex justify-end">
                        {r.public_url ? (
                          <div className="text-xs font-medium text-status-verified flex items-center gap-1">
                            Published:{" "}
                            <a href={r.public_url} className="hover:underline">
                              {r.public_url}
                            </a>
                          </div>
                        ) : (
                          <button
                            onClick={() => handlePublish(r.id)}
                            className="bg-primary text-primary-foreground hover:bg-primary/90 px-4 py-1.5 rounded-md text-sm font-medium transition-colors"
                          >
                            Approve & Publish
                          </button>
                        )}
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            </motion.div>
          )}

          {/* DISCOVERY TAB */}
          {activeTab === "discovery" && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }} className="max-w-6xl mx-auto space-y-6">
              <div className="flex justify-between items-end mb-6">
                <div>
                  <h2 className="text-2xl font-semibold tracking-tight">
                    Discovery Feed
                  </h2>
                  <p className="text-muted-foreground text-sm mt-1">
                    Autonomous candidate sourcing and ranking.
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  {filteredCandidates.length} items
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                <AnimatePresence>
                  {filteredCandidates.map((c) => (
                    <motion.div
                      layout
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      transition={{ duration: 0.2 }}
                      key={c.id}
                      className="p-5 rounded-xl border border-border bg-card flex flex-col justify-between hover:border-muted-foreground/50 hover:shadow-lg transition-all"
                    >
                      <div>
                        <div className="flex justify-between items-start mb-3">
                          <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground bg-secondary px-2 py-1 rounded">
                            {c.source_name}
                          </span>
                          <span className="text-sm font-bold text-primary">
                            Score: {c.opportunity_score}
                          </span>
                        </div>
                        <h3 className="font-medium text-lg leading-snug mb-4">
                          {c.title}
                        </h3>
                      </div>
                      <a
                        href={c.url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-sm font-medium text-status-verified hover:underline flex items-center gap-1 mt-auto pt-4 border-t border-border"
                      >
                        Verify Original Source{" "}
                        <ExternalLink className="w-3 h-3" />
                      </a>
                    </motion.div>
                  ))}
                </AnimatePresence>
                {filteredCandidates.length === 0 && (
                  <div className="col-span-full py-12 text-center text-muted-foreground border border-dashed border-border rounded-xl">
                    No candidates match your criteria.
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* INVESTIGATIONS TAB */}
          {activeTab === "investigations" && (
            <div className="max-w-6xl mx-auto space-y-8">
              <div>
                <h2 className="text-2xl font-semibold tracking-tight">
                  Active Investigations
                </h2>
                <p className="text-muted-foreground text-sm mt-1">
                  Live autonomous agent research queries.
                </p>
              </div>

              <div className="bg-card border border-border rounded-xl overflow-hidden">
                <table className="w-full text-sm text-left">
                  <thead className="bg-secondary/50 text-muted-foreground text-xs uppercase font-medium">
                    <tr>
                      <th className="px-6 py-3">Status</th>
                      <th className="px-6 py-3">Search Query</th>
                      <th className="px-6 py-3 text-right">Query ID</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {filteredInvestigations.map((inv) => (
                      <tr
                        key={inv.id}
                        className="hover:bg-secondary/20 transition-colors"
                      >
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium bg-secondary text-foreground border border-border">
                            {inv.status === "Running" ? (
                              <div className="w-1.5 h-1.5 rounded-full bg-status-verified animate-pulse" />
                            ) : (
                              <div className="w-1.5 h-1.5 rounded-full bg-muted-foreground" />
                            )}
                            {inv.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 font-mono text-xs">
                          {inv.search_query}
                        </td>
                        <td className="px-6 py-4 text-right text-muted-foreground font-mono text-xs">
                          {inv.id.substring(0, 8)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {filteredInvestigations.length === 0 && (
                  <div className="py-8 text-center text-muted-foreground">
                    No active investigations.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* SOURCE EXPLORER TAB */}
          {activeTab === "memory" && (
            <div className="max-w-6xl mx-auto space-y-6">
              <div className="flex justify-between items-end mb-6">
                <div>
                  <h2 className="text-2xl font-semibold tracking-tight">
                    Source Explorer
                  </h2>
                  <p className="text-muted-foreground text-sm mt-1">
                    Display every page visited, collected sources, raw content, and reasoning.
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  {evidence.length} sources
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {evidence.map((ev) => (
                  <div
                    key={ev.id}
                    className="p-5 rounded-xl border border-border bg-card hover:shadow-md transition-shadow"
                  >
                    <div className="flex justify-between items-start mb-4">
                      <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground bg-secondary px-2 py-1 rounded">
                        Score: {ev.source_score || "N/A"}
                      </span>
                      {ev.screenshot_path && (
                        <span className="text-xs font-medium text-primary flex items-center gap-1">
                          <ExternalLink className="w-3 h-3" /> Screenshot
                        </span>
                      )}
                    </div>
                    <a
                      href={ev.url}
                      target="_blank"
                      rel="noreferrer"
                      className="block text-sm font-medium text-foreground hover:text-status-verified truncate mb-3"
                    >
                      {ev.url}
                    </a>
                    <p className="text-sm text-muted-foreground bg-secondary/30 p-3 rounded-lg font-mono leading-relaxed h-32 overflow-y-auto whitespace-pre-wrap">
                      {ev.extracted_text}
                    </p>
                  </div>
                ))}
                {evidence.length === 0 && (
                  <div className="col-span-full py-12 text-center text-muted-foreground border border-dashed border-border rounded-xl">
                    No evidence sources collected yet.
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </main>

      {/* RIGHT CONTEXT PANEL */}
      <aside className="w-80 border-l border-border bg-card hidden lg:flex flex-col">
        <div className="h-14 border-b border-border flex items-center px-4">
          <span className="font-semibold text-sm">Context & Evidence</span>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-6">
          <div>
            <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              Live Feed
            </h4>
            <div className="space-y-3">
              {filteredCandidates.slice(0, 4).map((c) => (
                <div
                  key={c.id}
                  className="p-3 rounded-lg border border-border bg-background hover:border-muted-foreground/30 transition-colors cursor-pointer group"
                >
                  <div className="text-xs font-medium text-primary mb-1 flex items-center justify-between">
                    {c.source_name}
                    <ChevronRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />
                  </div>
                  <div className="text-sm text-foreground line-clamp-2">
                    {c.title}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div>
            <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              Recent Artifacts
            </h4>
            <div className="space-y-3">
              {evidence.slice(0, 3).map((ev) => (
                <div
                  key={ev.id}
                  className="p-3 rounded-lg border border-border bg-background"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] uppercase font-bold text-muted-foreground bg-secondary px-1.5 py-0.5 rounded">
                      Score: {ev.source_score || "N/A"}
                    </span>
                    <a
                      href={ev.url}
                      target="_blank"
                      rel="noreferrer"
                      className="text-muted-foreground hover:text-primary"
                    >
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  </div>
                  <p className="text-xs text-muted-foreground line-clamp-3">
                    {ev.extracted_text}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </aside>
    </div>
  );
};
