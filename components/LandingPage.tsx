"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform, useInView } from "framer-motion";
import Link from "next/link";
import {
  ArrowRight,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  HelpCircle,
  ChevronDown,
  MoveRight,
} from "lucide-react";
import { Report } from "./ReportCardView";

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

interface Claim {
  claim_text: string;
  claim_status: string;
  confidence_score: number;
}

interface FeaturedReport {
  slug: string;
  public: {
    title: string;
    summary: string;
    verdict: string;
    published_at: string;
  };
  metadata?: {
    tags?: string[];
    cover_image?: string;
    theme_color?: string;
  };
  claims?: Claim[];
  dashboard?: {
    hero_title?: string;
    hero_summary?: string;
    what_we_found?: string;
    key_takeaways?: string[];
  };
  candidate?: {
    title?: string;
    source_name?: string;
  };
}

interface LandingPageProps {
  reports: Report[];
  featuredReport: FeaturedReport | null;
}

// ─────────────────────────────────────────────────────────────
// Verdict utilities
// ─────────────────────────────────────────────────────────────

const getVerdictCfg = (verdict: string) => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v === "true")
    return {
      color: "text-emerald-400",
      bg: "bg-emerald-500/10",
      border: "border-emerald-500/25",
      accent: "#10b981",
      icon: <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("likely"))
    return {
      color: "text-blue-400",
      bg: "bg-blue-500/10",
      border: "border-blue-500/25",
      accent: "#3b82f6",
      icon: <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("mixed") || v.includes("disputed"))
    return {
      color: "text-amber-400",
      bg: "bg-amber-500/10",
      border: "border-amber-500/25",
      accent: "#f59e0b",
      icon: <AlertTriangle className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("false"))
    return {
      color: "text-rose-400",
      bg: "bg-rose-500/10",
      border: "border-rose-500/25",
      accent: "#ef4444",
      icon: <XCircle className="w-3.5 h-3.5 shrink-0" />,
    };
  return {
    color: "text-slate-400",
    bg: "bg-slate-500/10",
    border: "border-slate-500/25",
    accent: "#64748b",
    icon: <HelpCircle className="w-3.5 h-3.5 shrink-0" />,
  };
};

// ─────────────────────────────────────────────────────────────
// Node Network — animated SVG investigation background
// ─────────────────────────────────────────────────────────────

const NODES = [
  { cx: 8, cy: 20 },
  { cx: 22, cy: 7 },
  { cx: 42, cy: 13 },
  { cx: 60, cy: 5 },
  { cx: 78, cy: 16 },
  { cx: 92, cy: 36 },
  { cx: 90, cy: 58 },
  { cx: 80, cy: 76 },
  { cx: 60, cy: 88 },
  { cx: 38, cy: 93 },
  { cx: 18, cy: 84 },
  { cx: 5, cy: 64 },
  { cx: 10, cy: 44 },
  { cx: 28, cy: 37 },
  { cx: 50, cy: 43 },
  { cx: 70, cy: 52 },
  { cx: 44, cy: 65 },
  { cx: 25, cy: 58 },
  { cx: 55, cy: 25 },
  { cx: 35, cy: 75 },
];

const CONNECTIONS: [number, number][] = [
  [0, 1],
  [1, 2],
  [2, 3],
  [3, 4],
  [4, 5],
  [5, 6],
  [6, 7],
  [7, 8],
  [8, 9],
  [9, 10],
  [10, 11],
  [11, 12],
  [12, 13],
  [13, 14],
  [14, 15],
  [15, 6],
  [13, 17],
  [17, 16],
  [16, 14],
  [16, 8],
  [12, 0],
  [1, 13],
  [2, 14],
  [14, 7],
  [3, 15],
  [18, 2],
  [18, 14],
  [19, 16],
  [19, 9],
  [17, 11],
  [5, 15],
];

function NodeNetwork() {
  return (
    <svg
      viewBox="0 0 100 100"
      preserveAspectRatio="xMidYMid slice"
      className="absolute inset-0 w-full h-full pointer-events-none select-none"
      aria-hidden="true"
    >
      {/* Lines */}
      {CONNECTIONS.map(([a, b], i) => {
        const na = NODES[a],
          nb = NODES[b];
        const delay = (i * 0.12) % 3;
        const dur = 3 + (i % 5) * 0.6;
        return (
          <line
            key={i}
            x1={na.cx}
            y1={na.cy}
            x2={nb.cx}
            y2={nb.cy}
            stroke="#A259FF"
            strokeWidth="0.13"
            opacity="0"
            style={{
              animation: `lineFlicker ${dur}s ease-in-out ${delay}s infinite alternate`,
            }}
          />
        );
      })}
      {/* Nodes */}
      {NODES.map((node, i) => (
        <circle
          key={i}
          cx={node.cx}
          cy={node.cy}
          r={i % 5 === 0 ? 0.55 : 0.3}
          fill="#A259FF"
          opacity="0"
          style={{
            animation: `nodePulse ${2.5 + (i % 4) * 0.4}s ease-in-out ${(i * 0.18) % 2}s infinite alternate`,
          }}
        />
      ))}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Process steps — driven by JSON shape, not hardcoded content
// ─────────────────────────────────────────────────────────────

const STEPS = [
  {
    num: "01",
    title: "A claim surfaces.",
    body: 'Something spreads online. A headline. A screenshot. A hot take. Before most people check, it becomes "fact".',
    color: "#A259FF",
  },
  {
    num: "02",
    title: "We gather every source.",
    body: "Official statements. Academic papers. Primary reporting. Social data. We collect it all — not just the top search result.",
    color: "#3b82f6",
  },
  {
    num: "03",
    title: "We connect the evidence.",
    body: "Every source is scored. Every claim is tested against the evidence. Contradictions are surfaced, not buried.",
    color: "#8b5cf6",
  },
  {
    num: "04",
    title: "We publish the truth.",
    body: "An immutable, evidence-backed investigation. Every verdict. Every source. Transparent and permanently archived.",
    color: "#10b981",
  },
];

// ─────────────────────────────────────────────────────────────
// Manifesto items
// ─────────────────────────────────────────────────────────────

const MANIFESTO = [
  {
    headline: "Sources,\nnot summaries.",
    body: "Every conclusion is backed by verifiable, cited sources — not AI hallucination.",
  },
  {
    headline: "Evidence,\nnot opinions.",
    body: "We test claims against primary sources, not vibes or editorial bias.",
  },
  {
    headline: "Transparent,\nalways.",
    body: "Every evidence trail is public. You can verify every step of every investigation.",
  },
  {
    headline: "Deep,\nnot viral.",
    body: "We prioritize accuracy over speed. Investigations take time. Truth is worth it.",
  },
];

// ─────────────────────────────────────────────────────────────
// Section reveal wrapper
// ─────────────────────────────────────────────────────────────

function Reveal({
  children,
  delay = 0,
  className = "",
}: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 28 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ delay, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

// ─────────────────────────────────────────────────────────────
// Featured Investigation Showcase (dynamic, from props)
// ─────────────────────────────────────────────────────────────

function InvestigationShowcase({ report }: { report: FeaturedReport }) {
  const cfg = getVerdictCfg(report.public.verdict);
  const claims = (report.claims || []).slice(0, 3);
  const tags = report.metadata?.tags?.slice(0, 4) || [];
  const title = report.dashboard?.hero_title || report.public.title;

  return (
    <div className="relative">
      {/* Glow underneath the card */}
      <div
        className="absolute -inset-4 rounded-[2.5rem] blur-[60px] opacity-20 pointer-events-none"
        style={{
          background: `radial-gradient(ellipse, ${cfg.accent}, transparent 70%)`,
        }}
      />

      <Link
        href={`/report/${report.slug}`}
        className="block focus:outline-none group"
      >
        <motion.div
          whileHover={{
            y: -4,
            transition: { type: "spring", stiffness: 300, damping: 24 },
          }}
          className="relative rounded-[1.5rem] overflow-hidden border border-white/[0.08] group-hover:border-white/[0.16] transition-all duration-500"
          style={{
            background: "linear-gradient(145deg, #0d0d0d 0%, #080808 100%)",
          }}
        >
          {/* Verdict accent bar */}
          <div
            className="absolute top-0 left-0 right-0 h-[2px]"
            style={{ background: cfg.accent }}
          />

          {/* Hover glow */}
          <div
            className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
            style={{
              background: `radial-gradient(ellipse at 50% 0%, ${cfg.accent}0a, transparent 60%)`,
            }}
          />

          <div className="p-8 sm:p-10">
            {/* Header */}
            <div className="flex flex-wrap items-center gap-3 mb-6">
              <div
                className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-bold tracking-widest uppercase border ${cfg.color} ${cfg.border} ${cfg.bg}`}
              >
                {cfg.icon}
                {report.public.verdict}
              </div>
              {tags.map((t) => (
                <span
                  key={t}
                  className="px-2.5 py-1 rounded-md bg-white/[0.04] border border-white/[0.07] text-white/40 text-[10px] font-mono tracking-wider uppercase"
                >
                  {t}
                </span>
              ))}
              <span className="ml-auto text-white/25 text-[10px] font-mono tracking-wider hidden sm:block">
                {new Date(report.public.published_at).toLocaleDateString(
                  "en-US",
                  { month: "short", day: "numeric", year: "numeric" },
                )}
              </span>
            </div>

            {/* Title */}
            <h3 className="text-2xl sm:text-3xl font-black tracking-tight text-white leading-snug mb-4 font-geist group-hover:text-white transition-colors max-w-3xl">
              {title}
            </h3>

            {/* Summary */}
            <p className="text-white/50 text-sm leading-relaxed mb-8 max-w-2xl line-clamp-2">
              {report.dashboard?.hero_summary || report.public.summary}
            </p>

            {/* Claims preview */}
            {claims.length > 0 && (
              <div className="space-y-3 mb-8">
                <p className="text-[10px] font-mono font-bold tracking-widest uppercase text-white/25 mb-4">
                  {claims.length} Claims Investigated
                </p>
                {claims.map((claim, i) => {
                  const claimCfg = getVerdictCfg(claim.claim_status);
                  return (
                    <div
                      key={i}
                      className="flex items-center gap-4 p-4 rounded-xl bg-white/[0.03] border border-white/[0.05] hover:border-white/[0.10] transition-colors"
                    >
                      <div
                        className={`flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest shrink-0 ${claimCfg.color}`}
                      >
                        {claimCfg.icon}
                        {claim.claim_status}
                      </div>
                      <p className="text-white/55 text-sm leading-snug flex-1 line-clamp-1">
                        {claim.claim_text}
                      </p>
                      {/* Confidence bar */}
                      <div className="shrink-0 flex items-center gap-2 hidden sm:flex">
                        <div className="w-16 h-1 bg-white/8 rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all"
                            style={{
                              width: `${claim.confidence_score}%`,
                              backgroundColor: claimCfg.accent,
                            }}
                          />
                        </div>
                        <span className="text-[10px] font-mono text-white/30">
                          {claim.confidence_score}%
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {/* Footer CTA */}
            <div className="flex items-center justify-between pt-6 border-t border-white/[0.06]">
              <span
                className="text-sm font-bold flex items-center gap-2 transition-colors"
                style={{ color: cfg.accent }}
              >
                Read full investigation
                <MoveRight className="w-4 h-4 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all duration-200" />
              </span>
              <span className="text-white/20 text-[10px] font-mono tracking-widest uppercase hidden sm:block">
                {report.slug.toUpperCase()}
              </span>
            </div>
          </div>
        </motion.div>
      </Link>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Recent Reports mini-grid (dynamic from props)
// ─────────────────────────────────────────────────────────────

function ReportMiniCard({ report, index }: { report: Report; index: number }) {
  const cfg = getVerdictCfg(report.verdict);
  return (
    <Reveal delay={index * 0.07}>
      <Link
        href={`/report/${report.slug}`}
        className="block group focus:outline-none"
      >
        <div
          className="h-full p-5 rounded-2xl border border-white/[0.06] group-hover:border-white/[0.14] transition-all duration-300 relative overflow-hidden"
          style={{ background: "#0a0a0a" }}
        >
          <div
            className="absolute top-0 left-0 right-0 h-[2px] opacity-70 group-hover:opacity-100 transition-opacity"
            style={{ background: cfg.accent }}
          />
          <div className="flex items-center justify-between mb-3">
            <span
              className={`flex items-center gap-1 text-[10px] font-black uppercase tracking-widest ${cfg.color}`}
            >
              {cfg.icon}
              {report.verdict}
            </span>
            <time className="text-white/25 text-[10px] font-mono">
              {report.published_at
                ? new Date(report.published_at).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                  })
                : "—"}
            </time>
          </div>
          <h4 className="text-white/85 group-hover:text-white text-sm font-bold leading-snug line-clamp-2 transition-colors font-geist">
            {report.title}
          </h4>
        </div>
      </Link>
    </Reveal>
  );
}

// ─────────────────────────────────────────────────────────────
// MAIN LANDING PAGE
// ─────────────────────────────────────────────────────────────

export function LandingPage({ reports, featuredReport }: LandingPageProps) {
  const heroRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: heroRef,
    offset: ["start start", "end start"],
  });
  const heroY = useTransform(scrollYProgress, [0, 1], [0, 80]);
  const heroOpacity = useTransform(scrollYProgress, [0, 0.6], [1, 0]);

  // Show up to 6 reports in the mini grid (excluding the featured one)
  const recentReports = reports
    .filter((r) => r.slug !== featuredReport?.slug)
    .slice(0, 6);

  return (
    <div className="relative w-full">
      {/* ══════════════════════════════════════════════════════
          HERO
      ══════════════════════════════════════════════════════ */}
      <section
        ref={heroRef}
        className="relative w-full min-h-screen flex flex-col justify-center overflow-hidden"
      >
        {/* Ambient glows */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-[-10%] left-[-8%] w-[60%] h-[70%] bg-[#A259FF]/8 rounded-full blur-[200px]" />
          <div className="absolute bottom-[-20%] right-[-10%] w-[55%] h-[60%] bg-blue-600/5 rounded-full blur-[220px]" />
          <div className="absolute top-[40%] right-[20%] w-[30%] h-[40%] bg-violet-500/5 rounded-full blur-[150px]" />
        </div>

        {/* Node network background */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.22 }}
          transition={{ duration: 2.5, ease: "easeOut" }}
          className="absolute inset-0 pointer-events-none"
        >
          <NodeNetwork />
        </motion.div>

        {/* Hero content */}
        <motion.div
          style={{ y: heroY, opacity: heroOpacity }}
          className="relative z-10 mx-auto w-full max-w-6xl px-6 lg:px-8 pt-32 pb-24 sm:pt-40 sm:pb-32"
        >
          {/* Label */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="flex items-center gap-3 mb-10"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-[#A259FF] animate-live-pulse shadow-[0_0_8px_rgba(162,89,255,0.8)]" />
            <span className="text-[11px] font-mono font-bold tracking-[0.2em] uppercase text-white/40">
              Investigation Platform
            </span>
          </motion.div>

          {/* Headline */}
          <div className="overflow-hidden mb-3">
            <motion.h1
              initial={{ y: 80, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{
                delay: 0.3,
                duration: 0.9,
                ease: [0.16, 1, 0.3, 1],
              }}
              className="text-[clamp(3.2rem,8vw,7rem)] font-black tracking-[-0.03em] text-white leading-[1.0] font-geist"
            >
              Everyone saw
              <br />
              the headline.
            </motion.h1>
          </div>

          <div className="overflow-hidden mb-12">
            <motion.p
              initial={{ y: 60, opacity: 0 }}
              animate={{ y: 0, opacity: 0.45 }}
              transition={{
                delay: 0.5,
                duration: 0.9,
                ease: [0.16, 1, 0.3, 1],
              }}
              className="text-[clamp(1.8rem,4.5vw,3.5rem)] font-black tracking-tight text-white font-geist leading-tight"
            >
              We read the sources.
            </motion.p>
          </div>

          {/* Sub-text */}
          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.75, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="text-white/45 text-base sm:text-lg leading-relaxed max-w-xl mb-12"
          >
            Factline investigates the claims circulating online — gathering
            every source, connecting every piece of evidence, and publishing
            transparent reports.
          </motion.p>

          {/* CTAs */}
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.9, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="flex flex-wrap items-center gap-4"
          >
            <Link href="/archive">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="flex items-center gap-2 px-6 py-3.5 rounded-full bg-white text-black text-sm font-bold tracking-wide hover:bg-white/90 transition-colors"
              >
                Explore investigations
                <ArrowRight className="w-4 h-4" />
              </motion.button>
            </Link>
            <Link href="/ai-process">
              <button className="flex items-center gap-2 px-6 py-3.5 rounded-full border border-white/12 text-white/60 hover:text-white hover:border-white/25 text-sm font-semibold transition-all duration-200">
                How it works
              </button>
            </Link>
          </motion.div>

          {/* Trust strip */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.3, duration: 0.7 }}
            className="flex items-center gap-6 mt-16 text-white/20 text-[11px] font-mono tracking-wider"
          >
            <span>
              {reports.length} investigation{reports.length !== 1 ? "s" : ""}{" "}
              published
            </span>
            <span className="w-px h-3 bg-white/10" />
            <span>100% human verified</span>
            <span className="w-px h-3 bg-white/10" />
            <span>every source cited</span>
          </motion.div>
        </motion.div>

        {/* Scroll cue */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2, duration: 1 }}
          className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-white/25"
        >
          <span className="text-[10px] font-mono tracking-widest uppercase">
            Scroll
          </span>
          <motion.div
            animate={{ y: [0, 5, 0] }}
            transition={{ duration: 1.8, repeat: Infinity, ease: "easeInOut" }}
          >
            <ChevronDown className="w-4 h-4" />
          </motion.div>
        </motion.div>
      </section>

      {/* ══════════════════════════════════════════════════════
          BRAND STATEMENT
      ══════════════════════════════════════════════════════ */}
      <section className="relative py-28 sm:py-40 border-t border-white/[0.05]">
        <div className="absolute inset-0 bg-gradient-to-b from-[#020202] via-[#050504] to-[#020202] pointer-events-none" />
        <div className="relative mx-auto max-w-5xl px-6 lg:px-8 text-center">
          <Reveal>
            <p className="text-[11px] font-mono font-bold tracking-[0.2em] uppercase text-white/30 mb-10">
              The Factline Principle
            </p>
          </Reveal>

          <div className="space-y-6 sm:space-y-8">
            {[
              {
                emoji: "🌐",
                text: "internet says one thing",
                opacity: "text-white/35",
                delay: 0,
              },
              {
                emoji: "📚",
                text: "sources say another",
                opacity: "text-white/55",
                delay: 0.15,
              },
              {
                emoji: "🕳️",
                text: "we go down the rabbit hole",
                opacity: "text-white",
                delay: 0.3,
                hero: true,
              },
            ].map((line, i) => (
              <Reveal key={i} delay={line.delay}>
                <div
                  className={`flex items-center justify-center gap-4 font-geist font-black tracking-tight ${line.hero ? "text-3xl sm:text-5xl" : "text-xl sm:text-3xl"} ${line.opacity}`}
                >
                  <span
                    className={line.hero ? "animate-float" : ""}
                    style={
                      line.hero
                        ? {
                            filter:
                              "drop-shadow(0 0 20px rgba(162,89,255,0.6))",
                          }
                        : {}
                    }
                  >
                    {line.emoji}
                  </span>
                  {line.text}
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════
          HOW IT WORKS
      ══════════════════════════════════════════════════════ */}
      <section className="relative py-28 sm:py-40 border-t border-white/[0.05]">
        <div className="mx-auto max-w-6xl px-6 lg:px-8">
          <Reveal className="mb-20">
            <div className="flex items-center gap-4 mb-4">
              <span className="text-[11px] font-mono font-bold tracking-[0.2em] uppercase text-white/30">
                The Process
              </span>
              <div className="h-px bg-gradient-to-r from-white/10 to-transparent flex-grow" />
            </div>
            <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-white font-geist">
              How an investigation
              <br />
              actually works.
            </h2>
          </Reveal>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 lg:gap-8">
            {STEPS.map((step, i) => (
              <Reveal key={i} delay={i * 0.1}>
                <div className="group relative p-7 rounded-2xl border border-white/[0.06] hover:border-white/[0.14] bg-[#080808] hover:bg-[#0a0a0a] transition-all duration-300 h-full overflow-hidden">
                  {/* Background step number */}
                  <span
                    className="absolute bottom-4 right-5 text-[5rem] font-black font-geist leading-none opacity-[0.04] pointer-events-none select-none"
                    style={{ color: step.color }}
                  >
                    {step.num}
                  </span>
                  {/* Accent dot */}
                  <div
                    className="w-2.5 h-2.5 rounded-full mb-6 shadow-[0_0_10px_currentColor]"
                    style={{ backgroundColor: step.color }}
                  />
                  <h3 className="text-xl font-black text-white tracking-tight mb-3 font-geist">
                    {step.title}
                  </h3>
                  <p className="text-white/50 text-sm leading-relaxed">
                    {step.body}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════
          INVESTIGATION SHOWCASE (fully dynamic)
      ══════════════════════════════════════════════════════ */}
      {featuredReport && (
        <section className="relative py-28 sm:py-40 border-t border-white/[0.05]">
          {/* Section ambient glow */}
          <div
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[80%] h-[60%] rounded-full blur-[200px] opacity-10 pointer-events-none"
            style={{
              background: `radial-gradient(ellipse, ${getVerdictCfg(featuredReport.public.verdict).accent}, transparent)`,
            }}
          />
          <div className="relative mx-auto max-w-4xl px-6 lg:px-8">
            <Reveal className="mb-12">
              <div className="flex items-center gap-4 mb-4">
                <span className="text-[11px] font-mono font-bold tracking-[0.2em] uppercase text-white/30">
                  Latest Investigation
                </span>
                <div className="h-px bg-gradient-to-r from-white/10 to-transparent flex-grow" />
              </div>
              <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-white font-geist">
                See what an investigation
                <br />
                actually looks like.
              </h2>
            </Reveal>
            <Reveal delay={0.15}>
              <InvestigationShowcase report={featuredReport} />
            </Reveal>
          </div>
        </section>
      )}

      {/* ══════════════════════════════════════════════════════
          MANIFESTO
      ══════════════════════════════════════════════════════ */}
      <section className="relative py-28 sm:py-40 border-t border-white/[0.05]">
        <div className="mx-auto max-w-6xl px-6 lg:px-8">
          <Reveal className="mb-20 text-center">
            <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-white font-geist">
              What we believe.
            </h2>
          </Reveal>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {MANIFESTO.map((item, i) => (
              <Reveal key={i} delay={i * 0.08}>
                <div className="group h-full p-6 rounded-2xl border border-white/[0.06] hover:border-[#A259FF]/25 bg-[#080808] hover:bg-[#0a0814] transition-all duration-300">
                  <h3 className="text-lg font-black text-white font-geist whitespace-pre-line leading-snug mb-4 tracking-tight">
                    {item.headline}
                  </h3>
                  <p className="text-white/40 text-sm leading-relaxed group-hover:text-white/55 transition-colors">
                    {item.body}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════
          RECENT INVESTIGATIONS (dynamic, excludes featured)
      ══════════════════════════════════════════════════════ */}
      {recentReports.length > 0 && (
        <section className="relative py-28 sm:py-40 border-t border-white/[0.05]">
          <div className="mx-auto max-w-6xl px-6 lg:px-8">
            <Reveal className="mb-12 flex items-end justify-between gap-6">
              <div>
                <p className="text-[11px] font-mono font-bold tracking-[0.2em] uppercase text-white/30 mb-3">
                  More Investigations
                </p>
                <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-white font-geist">
                  Every investigation
                  <br />
                  goes deeper.
                </h2>
              </div>
              <Link href="/archive" className="shrink-0">
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className="flex items-center gap-2 px-5 py-2.5 rounded-full border border-white/12 text-white/55 hover:text-white hover:border-white/25 text-sm font-semibold transition-all duration-200 whitespace-nowrap"
                >
                  View all
                  <ArrowRight className="w-3.5 h-3.5" />
                </motion.button>
              </Link>
            </Reveal>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {recentReports.map((r, i) => (
                <ReportMiniCard key={r.slug} report={r} index={i} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ══════════════════════════════════════════════════════
          ARCHIVE CTA
      ══════════════════════════════════════════════════════ */}
      <section className="relative py-32 sm:py-48 border-t border-white/[0.05] overflow-hidden">
        {/* Background orb */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="w-[600px] h-[400px] bg-[#A259FF]/6 rounded-full blur-[150px]" />
        </div>

        <div className="relative mx-auto max-w-3xl px-6 lg:px-8 text-center">
          <Reveal>
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/[0.04] border border-white/[0.08] text-white/40 text-[11px] font-mono tracking-widest uppercase mb-10">
              <span className="w-1.5 h-1.5 rounded-full bg-[#A259FF] animate-live-pulse" />
              {reports.length} investigation{reports.length !== 1 ? "s" : ""} in
              the archive
            </div>
          </Reveal>

          <Reveal delay={0.1}>
            <h2 className="text-5xl sm:text-7xl font-black tracking-[-0.03em] text-white font-geist leading-[1.0] mb-8">
              Go down
              <br />
              <span className="text-white/35">the rabbit hole.</span>
            </h2>
          </Reveal>

          <Reveal delay={0.2}>
            <p className="text-white/40 text-lg leading-relaxed mb-12 max-w-xl mx-auto">
              Every report. Every claim. Every source. Permanently archived and
              transparently published.
            </p>
          </Reveal>

          <Reveal delay={0.3}>
            <Link href="/archive">
              <motion.button
                whileHover={{
                  scale: 1.03,
                  boxShadow: "0 0 40px rgba(162,89,255,0.25)",
                }}
                whileTap={{ scale: 0.97 }}
                className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-[#A259FF] hover:bg-[#b36fff] text-white font-bold text-base tracking-wide transition-colors duration-200"
              >
                🕳️ Explore the archive
                <ArrowRight className="w-4 h-4" />
              </motion.button>
            </Link>
          </Reveal>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/[0.05] py-10">
        <div className="mx-auto max-w-6xl px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-white/25 text-xs font-mono tracking-wider">
          <span>
            © 2026 Factline. All investigations are evidence-backed and human
            verified.
          </span>
          <div className="flex items-center gap-6">
            <Link
              href="/archive"
              className="hover:text-white/50 transition-colors"
            >
              Archive
            </Link>
            <Link
              href="/ai-process"
              className="hover:text-white/50 transition-colors"
            >
              Methodology
            </Link>
            <a
              href="https://www.instagram.com/factline.one/"
              target="_blank"
              rel="noreferrer"
              className="hover:text-white/50 transition-colors"
            >
              Instagram
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
