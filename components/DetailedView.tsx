"use client";

import React, { useState } from "react";
import Image from "next/image";
import {
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  HelpCircle,
  ExternalLink,
  Share2,
  Clock,
  BookOpen,
  FileText,
} from "lucide-react";

// ─────────────────────────────────────────────────────────────
// Verdict utilities
// ─────────────────────────────────────────────────────────────
const getVerdictConfig = (verdict: string) => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v === "true")
    return {
      color: "text-emerald-400",
      border: "border-emerald-900/50",
      bg: "bg-emerald-950/30",
      icon: <CheckCircle2 className="w-5 h-5 text-emerald-500" />,
    };
  if (v.includes("likely"))
    return {
      color: "text-blue-400",
      border: "border-blue-900/50",
      bg: "bg-blue-950/30",
      icon: <CheckCircle2 className="w-5 h-5 text-blue-500" />,
    };
  if (v.includes("mixed") || v.includes("disputed"))
    return {
      color: "text-amber-400",
      border: "border-amber-900/50",
      bg: "bg-amber-950/30",
      icon: <AlertTriangle className="w-5 h-5 text-amber-500" />,
    };
  if (v.includes("false"))
    return {
      color: "text-rose-400",
      border: "border-rose-900/50",
      bg: "bg-rose-950/30",
      icon: <XCircle className="w-5 h-5 text-rose-500" />,
    };
  return {
    color: "text-zinc-400",
    border: "border-zinc-800",
    bg: "bg-zinc-900",
    icon: <HelpCircle className="w-5 h-5 text-zinc-500" />,
  };
};

// ─────────────────────────────────────────────────────────────
// Share button
// ─────────────────────────────────────────────────────────────
const ShareButton = () => {
  const [copied, setCopied] = useState(false);
  const handleShare = () => {
    navigator.clipboard.writeText(window.location.href).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };
  return (
    <button
      onClick={handleShare}
      className="flex items-center gap-2 px-3 py-1.5 rounded-full border border-zinc-800 hover:bg-zinc-900 text-zinc-400 text-xs font-medium transition-colors"
    >
      {copied ? (
        <>
          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
          <span className="text-emerald-500">Copied</span>
        </>
      ) : (
        <>
          <Share2 className="w-3.5 h-3.5" />
          Share
        </>
      )}
    </button>
  );
};

// ─────────────────────────────────────────────────────────────
// Main component
// ─────────────────────────────────────────────────────────────
export function DetailedView({ report }: { report: any }) {
  const { dashboard, metadata, public: pub, claims, candidate } = report;
  const verdictCfg = getVerdictConfig(pub.verdict);

  const wordCount = JSON.stringify(report).split(/\s+/).length;
  const readTime = Math.max(3, Math.round(wordCount / 200));

  return (
    <article className="min-h-screen bg-zinc-950 pb-32">
      {/* ══════════════════════════════════════════════════════
          HERO HEADER
      ══════════════════════════════════════════════════════ */}
      <header className="relative w-full">
        {metadata?.cover_image && (
          <div className="w-full h-[50vh] sm:h-[60vh] relative">
            <Image
              src={metadata.cover_image}
              alt="Cover Image"
              fill
              priority
              className="object-cover grayscale-[20%] opacity-80"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/20 to-transparent pointer-events-none" />
          </div>
        )}

        <div className="max-w-4xl mx-auto px-6 -mt-32 relative z-10">
          <div className="bg-zinc-950 p-8 sm:p-12 border border-zinc-800 rounded-lg shadow-2xl">
            <div className="flex flex-wrap items-center gap-3 mb-6">
              <div
                className={`flex items-center gap-2 px-3 py-1 rounded-md text-xs font-bold uppercase tracking-widest ${verdictCfg.bg} ${verdictCfg.color} border ${verdictCfg.border}`}
              >
                {verdictCfg.icon}
                {pub.verdict}
              </div>
              {metadata?.tags?.map((t: string) => (
                <span
                  key={t}
                  className="px-3 py-1 rounded-full border border-zinc-800 text-zinc-400 text-[10px] uppercase tracking-widest font-semibold"
                >
                  {t}
                </span>
              ))}
            </div>

            <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl font-black text-zinc-100 leading-[1.1] mb-6">
              {dashboard?.hero_title || pub.title}
            </h1>

            <p className="text-xl sm:text-2xl text-zinc-400 font-serif leading-relaxed mb-8 italic">
              {dashboard?.hero_summary || pub.summary}
            </p>

            <div className="flex flex-wrap items-center gap-x-6 gap-y-3 text-sm text-zinc-500 border-t border-zinc-800/50 pt-6">
              {pub.published_at && (
                <span className="flex items-center gap-1.5 font-medium">
                  <Clock className="w-4 h-4" />
                  {new Date(pub.published_at).toLocaleDateString("en-US", {
                    month: "long",
                    day: "numeric",
                    year: "numeric",
                  })}
                </span>
              )}
              <span className="flex items-center gap-1.5 font-medium">
                <BookOpen className="w-4 h-4" />
                {readTime} min read
              </span>
              <div className="ml-auto">
                <ShareButton />
              </div>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-6 mt-16 space-y-20">
        {/* ══════════════════════════════════════════════════════
            ORIGIN & CANDIDATE
        ══════════════════════════════════════════════════════ */}
        {candidate && (
          <section className="bg-zinc-900/50 border-l-4 border-zinc-500 p-6 rounded-r-lg">
            <h3 className="text-sm font-bold text-zinc-500 uppercase tracking-widest mb-2">
              Origin of Investigation
            </h3>
            <p className="text-lg font-semibold text-zinc-100 mb-3">
              {candidate.title}
            </p>
            <div className="flex items-center gap-4">
              <span className="px-3 py-1 bg-zinc-800 rounded-md text-xs font-semibold text-zinc-300 uppercase tracking-widest">
                {candidate.source_name}
              </span>
              <a
                href={candidate.url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1.5 text-sm font-bold text-blue-400 hover:text-blue-300 transition-colors"
              >
                View Original Source <ExternalLink className="w-4 h-4" />
              </a>
            </div>
          </section>
        )}

        {/* ══════════════════════════════════════════════════════
            CLAIM VS REALITY (Context & What We Found)
        ══════════════════════════════════════════════════════ */}
        {dashboard &&
          (dashboard.why_people_care || dashboard.what_we_found) && (
            <section className="grid sm:grid-cols-2 gap-8">
              {dashboard.why_people_care && (
                <div>
                  <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-4 border-b border-zinc-800 pb-2">
                    The Context
                  </h2>
                  <p className="text-lg text-zinc-300 leading-relaxed font-serif">
                    {dashboard.why_people_care}
                  </p>
                </div>
              )}
              {dashboard.what_we_found && (
                <div className="bg-emerald-950/20 border border-emerald-900/50 p-8 rounded-lg relative overflow-hidden">
                  <div className="absolute top-0 right-0 opacity-5 p-4 pointer-events-none">
                    <ShieldCheck className="w-32 h-32 text-emerald-500" />
                  </div>
                  <h2 className="font-serif text-2xl font-bold text-emerald-400 mb-4 flex items-center gap-3 relative z-10">
                    <ShieldCheck className="w-6 h-6 text-emerald-500" />
                    What We Found
                  </h2>
                  <p className="text-lg text-emerald-100/90 leading-relaxed font-serif relative z-10">
                    {dashboard.what_we_found}
                  </p>
                </div>
              )}
            </section>
          )}

        {/* ══════════════════════════════════════════════════════
            KEY TAKEAWAYS
        ══════════════════════════════════════════════════════ */}
        {dashboard?.key_takeaways?.length > 0 && (
          <section>
            <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-6 border-b border-zinc-800 pb-2">
              Key Takeaways
            </h2>
            <div className="grid gap-4">
              {dashboard.key_takeaways.map((item: string, i: number) => (
                <div
                  key={i}
                  className="flex gap-4 p-4 bg-zinc-900/30 border border-zinc-800/50 rounded-lg"
                >
                  <span className="flex-shrink-0 w-8 h-8 rounded-full bg-zinc-800 text-zinc-300 flex items-center justify-center text-sm font-bold border border-zinc-700">
                    {i + 1}
                  </span>
                  <p className="text-lg text-zinc-300 leading-relaxed font-serif pt-0.5">
                    {item}
                  </p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ══════════════════════════════════════════════════════
            EVIDENCE DOSSIER
        ══════════════════════════════════════════════════════ */}
        {claims && claims.length > 0 && (
          <section>
            <div className="flex items-center gap-4 mb-8">
              <h2 className="font-serif text-3xl font-bold text-zinc-100">
                Evidence Dossier
              </h2>
              <div className="h-px bg-zinc-800 flex-grow" />
              <span className="text-zinc-500 font-mono text-sm uppercase tracking-widest">
                {claims.length} Claims Investigated
              </span>
            </div>

            <div className="space-y-8">
              {claims.map((claim: any, idx: number) => {
                const claimCfg = getVerdictConfig(claim.claim_status);
                return (
                  <div
                    key={idx}
                    className="border border-zinc-800 rounded-lg overflow-hidden bg-zinc-900/20 shadow-sm"
                  >
                    <div
                      className={`border-b ${claimCfg.border} ${claimCfg.bg} p-6 sm:p-8`}
                    >
                      <div className="flex flex-wrap items-center justify-between gap-4 mb-4">
                        <span
                          className={`text-xs font-bold uppercase tracking-widest ${claimCfg.color} flex items-center gap-1.5`}
                        >
                          {claimCfg.icon} {claim.claim_status}
                        </span>
                        <div className="flex items-center gap-2">
                          <span className="text-zinc-500 text-xs font-mono font-medium uppercase tracking-widest">
                            Confidence
                          </span>
                          <span className="text-zinc-300 font-mono font-bold">
                            {claim.confidence_score}%
                          </span>
                        </div>
                      </div>
                      <h3 className="font-serif text-2xl font-bold text-zinc-100 leading-snug">
                        {claim.claim_text}
                      </h3>
                    </div>

                    <div className="p-6 sm:p-8 grid md:grid-cols-2 gap-8">
                      {claim.evidence?.length > 0 && (
                        <div>
                          <h4 className="text-xs font-bold text-emerald-500 uppercase tracking-widest mb-4 flex items-center gap-2 border-b border-emerald-900/30 pb-2">
                            <CheckCircle2 className="w-4 h-4" /> Supporting
                            Evidence
                          </h4>
                          <div className="space-y-6">
                            {claim.evidence.map((ev: any, i: number) => (
                              <div
                                key={i}
                                className="pl-4 border-l-2 border-emerald-800/50"
                              >
                                <p className="text-zinc-300 font-serif italic mb-3 leading-relaxed">
                                  &quot;{ev.extracted_text}&quot;
                                </p>
                                <div className="flex items-center justify-between mb-4">
                                  <a
                                    href={ev.url}
                                    target="_blank"
                                    rel="noreferrer"
                                    className="text-xs font-bold text-zinc-500 hover:text-zinc-300 flex items-center gap-1 transition-colors"
                                  >
                                    <ExternalLink className="w-3 h-3" />{" "}
                                    {ev.source_type}
                                  </a>
                                  {ev.source_score && (
                                    <span className="text-[10px] text-emerald-600/70 font-mono">
                                      AUTH: {ev.source_score}/100
                                    </span>
                                  )}
                                </div>
                                {ev.screenshot_path && (
                                  <Image
                                    src={ev.screenshot_path}
                                    alt="Evidence Screenshot"
                                    width={800}
                                    height={450}
                                    className="w-full h-auto rounded-md border border-zinc-800 mb-4 opacity-80 grayscale-[30%] hover:grayscale-0 hover:opacity-100 transition-all"
                                  />
                                )}
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {claim.contradicting_evidence?.length > 0 && (
                        <div>
                          <h4 className="text-xs font-bold text-rose-500 uppercase tracking-widest mb-4 flex items-center gap-2 border-b border-rose-900/30 pb-2">
                            <XCircle className="w-4 h-4" /> Contradicting
                            Evidence
                          </h4>
                          <div className="space-y-6">
                            {claim.contradicting_evidence.map(
                              (ev: any, i: number) => (
                                <div
                                  key={i}
                                  className="pl-4 border-l-2 border-rose-800/50"
                                >
                                  <p className="text-zinc-300 font-serif italic mb-3 leading-relaxed">
                                    &quot;{ev.extracted_text}&quot;
                                  </p>
                                  <div className="flex items-center justify-between mb-4">
                                    {ev.url ? (
                                      <a
                                        href={ev.url}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="text-xs font-bold text-zinc-500 hover:text-zinc-300 flex items-center gap-1 transition-colors"
                                      >
                                        <ExternalLink className="w-3 h-3" />{" "}
                                        {ev.source_type}
                                      </a>
                                    ) : (
                                      <span className="text-xs font-bold text-zinc-600 flex items-center gap-1">
                                        <FileText className="w-3 h-3" />{" "}
                                        {ev.source_type}
                                      </span>
                                    )}
                                    {ev.source_score ? (
                                      <span className="text-[10px] text-rose-600/70 font-mono">
                                        AUTH: {ev.source_score}/100
                                      </span>
                                    ) : null}
                                  </div>
                                  {ev.screenshot_path && (
                                    <Image
                                      src={ev.screenshot_path}
                                      alt="Evidence Screenshot"
                                      width={800}
                                      height={450}
                                      className="w-full h-auto rounded-md border border-zinc-800 mb-4 opacity-80 grayscale-[30%] hover:grayscale-0 hover:opacity-100 transition-all"
                                    />
                                  )}
                                </div>
                              ),
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {/* ══════════════════════════════════════════════════════
            TIMELINE & CONTEXT
        ══════════════════════════════════════════════════════ */}
        {(dashboard?.timeline || dashboard?.context) && (
          <section className="grid md:grid-cols-5 gap-12 pt-10 border-t border-zinc-800">
            {/* Context */}
            {dashboard.context && (
              <div className="md:col-span-3">
                <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-8">
                  Investigation Context
                </h2>
                <div className="grid gap-6">
                  {Object.entries(dashboard.context).map(([key, val]) => (
                    <div
                      key={key}
                      className="bg-zinc-900/30 p-6 rounded-lg border border-zinc-800/50"
                    >
                      <h4 className="text-xs font-bold text-zinc-500 uppercase tracking-widest mb-3 flex items-center gap-2">
                        <FileText className="w-4 h-4 text-zinc-600" />
                        {key.replace(/_/g, " ")}
                      </h4>
                      <p className="text-zinc-300 font-serif leading-relaxed text-lg">
                        {val as string}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Timeline */}
            {dashboard.timeline && (
              <div className="md:col-span-2">
                <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-8">
                  Timeline
                </h2>
                <div className="relative border-l border-zinc-800 ml-3 space-y-8 pb-4">
                  {dashboard.timeline.map((item: any, idx: number) => (
                    <div key={idx} className="relative pl-6">
                      <div className="absolute -left-1.5 top-1.5 w-3 h-3 bg-blue-500 rounded-full ring-4 ring-zinc-950" />
                      <div className="text-xs font-bold font-mono text-blue-400 mb-1.5 tracking-widest uppercase">
                        {item.date}
                      </div>
                      <p className="text-zinc-300 font-serif leading-relaxed">
                        {item.event}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </section>
        )}

        {/* ══════════════════════════════════════════════════════
            OPEN QUESTIONS
        ══════════════════════════════════════════════════════ */}
        {dashboard?.open_questions?.length > 0 && (
          <section className="pt-10 border-t border-zinc-800">
            <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-6">
              Open Questions
            </h2>
            <div className="grid sm:grid-cols-2 gap-4">
              {dashboard.open_questions.map((q: string, i: number) => (
                <div
                  key={i}
                  className="flex items-start gap-3 p-6 bg-zinc-900/40 border border-zinc-800 rounded-lg"
                >
                  <HelpCircle className="w-5 h-5 text-zinc-500 flex-shrink-0 mt-0.5" />
                  <p className="text-zinc-300 font-serif text-lg leading-relaxed">
                    {q}
                  </p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ══════════════════════════════════════════════════════
            SOURCES
        ══════════════════════════════════════════════════════ */}
        {dashboard?.sources?.length > 0 && (
          <section className="pt-12 border-t border-zinc-800">
            <h2 className="font-serif text-3xl font-bold text-zinc-100 mb-8 flex items-center gap-3">
              <FileText className="w-6 h-6 text-zinc-600" />
              Sources & Citations
            </h2>
            <div className="space-y-4">
              {dashboard.sources.map((src: any, i: number) => {
                let domain = "";
                try {
                  domain = new URL(src.url).hostname.replace("www.", "");
                } catch (e) {}

                return (
                  <a
                    key={i}
                    href={src.url}
                    target="_blank"
                    rel="noreferrer"
                    className="group flex flex-col sm:flex-row sm:items-center justify-between gap-5 p-5 bg-zinc-900/20 border border-zinc-800/50 hover:bg-zinc-900/60 hover:border-zinc-700 transition-all rounded-lg"
                  >
                    <div className="flex items-start gap-5 flex-1">
                      <div className="flex-shrink-0 w-8 h-8 rounded bg-zinc-800 flex items-center justify-center font-mono text-xs font-bold text-zinc-400 group-hover:text-blue-400 group-hover:bg-blue-900/20 transition-colors mt-0.5">
                        {i + 1}
                      </div>
                      <div>
                        <h4 className="font-serif text-zinc-200 font-bold leading-snug group-hover:text-blue-400 transition-colors mb-2">
                          {src.title}
                        </h4>
                        <div className="flex items-center flex-wrap gap-3 text-xs font-mono text-zinc-500">
                          {domain && (
                            <span className="flex items-center gap-1.5 text-zinc-400">
                              <ExternalLink className="w-3 h-3" />
                              {domain}
                            </span>
                          )}
                          <span className="hidden sm:inline-block w-1 h-1 rounded-full bg-zinc-700" />
                          <span className="uppercase tracking-widest text-zinc-500 bg-zinc-800/50 px-2 py-0.5 rounded">
                            {src.source_type}
                          </span>
                        </div>
                      </div>
                    </div>
                    {src.authority_score && (
                      <div className="flex flex-col sm:items-end sm:pl-6 sm:border-l border-zinc-800/50 flex-shrink-0 mt-4 sm:mt-0">
                        <span className="text-[10px] uppercase tracking-widest text-zinc-600 font-bold mb-1">
                          Authority
                        </span>
                        <span className="text-2xl font-serif italic text-emerald-400/90 font-bold">
                          {src.authority_score}
                          <span className="text-sm text-zinc-600">/100</span>
                        </span>
                      </div>
                    )}
                  </a>
                );
              })}
            </div>
          </section>
        )}
      </main>
    </article>
  );
}
