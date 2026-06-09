"use client";

import { useState, useRef } from "react";
import {
  motion,
  useScroll,
  useTransform,
  AnimatePresence,
  useInView,
} from "framer-motion";
import {
  ShieldCheck,
  Zap,
  ChevronLeft,
  ChevronDown,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  HelpCircle,
  ExternalLink,
  Share2,
  Clock,
  BookOpen,
  HelpCircle as QuestionIcon,
  Link2,
} from "lucide-react";
import Link from "next/link";

// ─────────────────────────────────────────────────────────────
// Verdict utilities
// ─────────────────────────────────────────────────────────────
const getVerdictConfig = (verdict: string) => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v === "true")
    return { color: "text-emerald-400", border: "border-emerald-500/30", bg: "bg-emerald-500/10", accent: "#10b981", label: verdict };
  if (v.includes("likely"))
    return { color: "text-blue-400",   border: "border-blue-500/30",   bg: "bg-blue-500/10",   accent: "#3b82f6", label: verdict };
  if (v.includes("mixed") || v.includes("disputed"))
    return { color: "text-amber-400",  border: "border-amber-500/30",  bg: "bg-amber-500/10",  accent: "#f59e0b", label: verdict };
  if (v.includes("false"))
    return { color: "text-rose-400",   border: "border-rose-500/30",   bg: "bg-rose-500/10",   accent: "#ef4444", label: verdict };
  return   { color: "text-slate-400",  border: "border-slate-500/30",  bg: "bg-slate-500/10",  accent: "#64748b", label: verdict || "Under Review" };
};

const getVerdictIcon = (verdict: string, size = "w-5 h-5") => {
  const v = (verdict || "").toLowerCase();
  if (v.includes("verifi") || v === "true") return <CheckCircle2 className={`${size} text-emerald-400`} />;
  if (v.includes("likely"))                 return <CheckCircle2 className={`${size} text-blue-400`} />;
  if (v.includes("mixed"))                  return <AlertTriangle className={`${size} text-amber-400`} />;
  if (v.includes("false"))                  return <XCircle       className={`${size} text-rose-400`} />;
  return                                           <HelpCircle     className={`${size} text-slate-400`} />;
};

// ─────────────────────────────────────────────────────────────
// Animated confidence bar
// ─────────────────────────────────────────────────────────────
const ConfidenceBar = ({ score, label }: { score: number; label: string }) => {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-50px" });
  const barColor = score >= 90 ? "bg-emerald-500" : score >= 70 ? "bg-amber-500" : "bg-rose-500";
  const glow     = score >= 90
    ? "shadow-[0_0_8px_rgba(16,185,129,0.6)]"
    : score >= 70
      ? "shadow-[0_0_8px_rgba(245,158,11,0.6)]"
      : "shadow-[0_0_8px_rgba(239,68,68,0.6)]";

  return (
    <div ref={ref} className="w-full max-w-[130px]">
      <div className="flex justify-between items-center mb-1.5 text-[10px] font-bold tracking-widest uppercase text-white/40">
        <span>{label}</span>
        <span className="text-white/80">{score}%</span>
      </div>
      <div className="w-full h-1 bg-white/8 rounded-full overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: inView ? `${score}%` : 0 }}
          transition={{ duration: 1.2, ease: [0.16, 1, 0.3, 1] }}
          className={`h-full rounded-full ${barColor} ${glow}`}
        />
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// Animated confidence ring (SVG arc)
// ─────────────────────────────────────────────────────────────
const ConfidenceRing = ({ score, color }: { score: number; color: string }) => {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });
  const r = 36;
  const circ = 2 * Math.PI * r;
  const offset = circ - (score / 100) * circ;

  return (
    <div ref={ref} className="relative w-24 h-24 flex-shrink-0">
      <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
        <circle cx="50" cy="50" r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="8" />
        <motion.circle
          cx="50" cy="50" r={r}
          fill="none"
          stroke={color}
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={circ}
          initial={{ strokeDashoffset: circ }}
          animate={{ strokeDashoffset: inView ? offset : circ }}
          transition={{ duration: 1.4, ease: [0.16, 1, 0.3, 1], delay: 0.2 }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-xl font-black text-white font-geist">{score}</span>
        <span className="text-[9px] text-white/40 font-mono tracking-wider uppercase">conf.</span>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
const SectionHeader = ({ label, count }: { label: string; count?: number }) => (
  <div className="flex items-center gap-5 mb-10">
    <h3 className="text-3xl sm:text-4xl font-black text-white tracking-tighter font-geist">
      {label}
    </h3>
    {count !== undefined && (
      <span className="text-white/25 font-mono text-sm">({count})</span>
    )}
    <div className="h-px bg-gradient-to-r from-white/10 to-transparent flex-grow" />
  </div>
);

// ─────────────────────────────────────────────────────────────
// Evidence card
// ─────────────────────────────────────────────────────────────
const EvidenceCard = ({
  ev,
  variant,
}: {
  ev: any;
  variant: "supporting" | "contradicting";
}) => {
  const isSupport = variant === "supporting";
  const accentColor = isSupport ? "#10b981" : "#ef4444";
  const borderColor = isSupport ? "border-emerald-500/20" : "border-rose-500/20";
  const bgColor     = isSupport ? "bg-emerald-500/5"      : "bg-rose-500/5";
  const textColor   = isSupport ? "text-emerald-400"      : "text-rose-400";

  return (
    <motion.div
      initial={{ opacity: 0, x: isSupport ? -12 : 12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
      className={`relative rounded-xl border ${borderColor} ${bgColor} p-5 overflow-hidden`}
    >
      {/* Left accent line */}
      <div
        className="absolute left-0 top-0 bottom-0 w-[3px] rounded-l-xl"
        style={{ backgroundColor: accentColor }}
      />

      {/* Source type badge */}
      <div className="flex items-center justify-between mb-3">
        <span className={`text-[10px] font-bold tracking-widest uppercase ${textColor} opacity-80`}>
          {ev.source_type || "Source"}
        </span>
        {ev.source_score != null && (
          <span className="text-[10px] font-mono text-white/30">
            AUTH {ev.source_score}/100
          </span>
        )}
      </div>

      {/* Quote */}
      <p className="text-white/75 text-sm leading-relaxed mb-4 pl-1 border-l-2 border-white/10 italic">
        &ldquo;{ev.extracted_text}&rdquo;
      </p>

      {/* Screenshot */}
      {ev.screenshot_path && (
        <div className="mb-4 rounded-lg overflow-hidden border border-white/10 relative group/img">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={ev.screenshot_path}
            alt="Evidence screenshot"
            className="w-full object-cover grayscale-[20%] group-hover/img:grayscale-0 transition-all duration-500 opacity-85 group-hover/img:opacity-100"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent pointer-events-none" />
        </div>
      )}

      {/* Source link */}
      {ev.url && (
        <a
          href={ev.url}
          target="_blank"
          rel="noreferrer"
          className={`inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wide ${textColor} opacity-70 hover:opacity-100 transition-opacity`}
        >
          <ExternalLink className="w-3 h-3" />
          {(() => {
            try { return new URL(ev.url).hostname.replace("www.", ""); } catch { return "Source"; }
          })()}
        </a>
      )}
    </motion.div>
  );
};

// ─────────────────────────────────────────────────────────────
// Context icons map
// ─────────────────────────────────────────────────────────────
const CONTEXT_ICONS: Record<string, string> = {
  historical: "🏛️",
  industry:   "🏭",
  geopolit:   "🌍",
  technolog:  "💡",
  social:     "👥",
  economic:   "📈",
  legal:      "⚖️",
};
const getContextIcon = (key: string) => {
  const lower = key.toLowerCase();
  for (const [k, icon] of Object.entries(CONTEXT_ICONS)) {
    if (lower.includes(k)) return icon;
  }
  return "🔍";
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
      className="flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 hover:border-white/25 hover:bg-white/10 text-white/60 hover:text-white text-sm font-semibold transition-all duration-200"
    >
      {copied ? (
        <>
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          <span className="text-emerald-400">Copied!</span>
        </>
      ) : (
        <>
          <Share2 className="w-4 h-4" />
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
  const { scrollYProgress } = useScroll();
  const yParallax      = useTransform(scrollYProgress, [0, 0.5], [0, 120]);
  const opacityParallax = useTransform(scrollYProgress, [0, 0.3], [1, 0]);

  const [expandedClaim, setExpandedClaim] = useState<number | null>(0);

  const verdictCfg = getVerdictConfig(pub.verdict);

  // Estimated read time
  const wordCount = JSON.stringify(report).split(/\s+/).length;
  const readTime  = Math.max(3, Math.round(wordCount / 200));

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4 }}
      className="relative w-full pb-40 bg-[#020202]"
    >
      {/* ── Ambient glows ── */}
      <div className="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        <div className="absolute top-0 left-[-10%] w-[60%] h-[50%] bg-[#A259FF]/6 rounded-full blur-[200px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-blue-500/4 rounded-full blur-[200px]" />
      </div>

      {/* ── Back button ── */}
      <Link href="/">
        <motion.button
          initial={{ opacity: 0, x: -16 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
          className="fixed top-[86px] left-4 lg:left-8 z-40 flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-[#0a0a0a]/90 hover:bg-[#111]/90 border border-white/10 hover:border-white/20 text-sm font-semibold text-white/60 hover:text-white backdrop-blur-xl transition-all duration-200 group shadow-[0_4px_24px_rgba(0,0,0,0.5)]"
        >
          <ChevronLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
          <span className="hidden sm:inline">Archive</span>
        </motion.button>
      </Link>

      {/* ══════════════════════════════════════════════════════
          HERO
      ══════════════════════════════════════════════════════ */}
      <div className="relative w-full h-[80vh] min-h-[620px] flex flex-col justify-end pb-16 overflow-hidden">

        {/* Cover image with parallax */}
        <motion.div
          style={{ y: yParallax, opacity: opacityParallax }}
          className="absolute inset-0 z-0"
        >
          {metadata?.cover_image && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={metadata.cover_image}
              className="w-full h-full object-cover opacity-35 grayscale-[40%] scale-110"
              alt="Investigation cover"
            />
          )}
          {/* Multi-layer gradient */}
          <div className="absolute inset-0 bg-gradient-to-t from-[#020202] via-[#020202]/85 to-[#020202]/20" />
          <div className="absolute inset-0 bg-gradient-to-r from-[#020202]/60 to-transparent" />

          {/* Subtle scan line */}
          <div className="absolute inset-0 scan-line pointer-events-none opacity-30" />
        </motion.div>

        {/* Hero content */}
        <div className="relative z-10 max-w-5xl w-full px-6 lg:px-12 mx-auto">
          <motion.div
            initial={{ y: 24, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.25, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="flex flex-wrap items-center gap-3 mb-7"
          >
            {/* Verdict badge */}
            <div className={`flex items-center gap-2 px-4 py-2 rounded-lg font-bold text-sm border backdrop-blur-xl tracking-widest uppercase ${verdictCfg.color} ${verdictCfg.border} ${verdictCfg.bg}`}>
              {getVerdictIcon(pub.verdict)}
              <span>Verdict: {pub.verdict}</span>
            </div>

            {/* Tags */}
            {metadata?.tags?.map((t: string) => (
              <span
                key={t}
                className="px-3 py-1.5 rounded-full bg-white/5 border border-white/10 text-white/50 font-medium tracking-widest text-xs uppercase hover:bg-white/8 hover:text-white/70 transition-colors cursor-pointer"
              >
                {t}
              </span>
            ))}
          </motion.div>

          {/* Title */}
          <motion.h1
            initial={{ y: 24, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.35, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tighter text-white leading-[1.02] mb-7 font-geist"
          >
            {dashboard?.hero_title || pub.title}
          </motion.h1>

          {/* Summary */}
          <motion.p
            initial={{ y: 24, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.45, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="text-lg sm:text-xl text-white/60 max-w-3xl leading-relaxed font-medium mb-8"
          >
            {dashboard?.hero_summary || pub.summary}
          </motion.p>

          {/* Meta strip */}
          <motion.div
            initial={{ y: 16, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.55, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="flex flex-wrap items-center gap-x-6 gap-y-2 text-xs font-mono text-white/35 tracking-wider uppercase"
          >
            {metadata?.author && (
              <span className="flex items-center gap-1.5">
                <BookOpen className="w-3.5 h-3.5" />
                {metadata.author}
              </span>
            )}
            {pub.published_at && (
              <span className="flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5" />
                {new Date(pub.published_at).toLocaleDateString("en-US", {
                  month: "long", day: "numeric", year: "numeric",
                })}
              </span>
            )}
            <span className="flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5" />
              ~{readTime} min read
            </span>
            <ShareButton />
          </motion.div>
        </div>
      </div>

      {/* ══════════════════════════════════════════════════════
          BODY
      ══════════════════════════════════════════════════════ */}
      <div className="relative z-10 max-w-5xl mx-auto px-6 lg:px-12 mt-16 space-y-28">

        {/* ── QUICK VERDICT ── */}
        <motion.section
          initial={{ opacity: 0, y: 32 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
        >
          <div
            className="rounded-2xl overflow-hidden border"
            style={{
              borderColor: `${verdictCfg.accent}30`,
              background: `linear-gradient(135deg, ${verdictCfg.accent}08 0%, rgba(0,0,0,0.4) 100%)`,
            }}
          >
            <div className="p-8 md:p-10 flex flex-col md:flex-row items-center gap-8 md:gap-12">
              {/* Ring */}
              <ConfidenceRing
                score={
                  claims?.[0]?.confidence_score ??
                  (pub.verdict?.toLowerCase().includes("verifi") ? 95 : 75)
                }
                color={verdictCfg.accent}
              />

              <div className="flex-1 space-y-4">
                <div className="flex items-center gap-3">
                  <span className="text-[11px] font-bold tracking-widest uppercase text-white/35 font-mono">
                    Quick Verdict
                  </span>
                  <div className="h-px bg-white/10 flex-grow" />
                </div>

                <div className={`text-3xl sm:text-4xl font-black tracking-tight font-geist ${verdictCfg.color}`}>
                  {getVerdictIcon(pub.verdict, "w-8 h-8")}
                </div>

                <h2 className={`text-2xl sm:text-3xl font-black tracking-tight font-geist ${verdictCfg.color}`}>
                  {pub.verdict}
                </h2>

                <p className="text-white/65 text-base leading-relaxed max-w-2xl">
                  {dashboard?.hero_summary?.split(".")[0] + "." || pub.summary}
                </p>
              </div>
            </div>

            {/* Key takeaways */}
            {dashboard?.key_takeaways?.length > 0 && (
              <div className="border-t border-white/[0.06] px-8 md:px-10 py-6 space-y-3">
                <p className="text-[10px] font-bold tracking-widest uppercase text-white/30 font-mono mb-4">Key Takeaways</p>
                {dashboard.key_takeaways.map((item: string, i: number) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -12 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.08, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                    className="flex items-start gap-3"
                  >
                    <span
                      className="flex-shrink-0 mt-0.5 w-5 h-5 rounded-full flex items-center justify-center text-[11px] font-black font-geist"
                      style={{ backgroundColor: `${verdictCfg.accent}20`, color: verdictCfg.accent }}
                    >
                      {i + 1}
                    </span>
                    <p className="text-white/70 text-sm leading-relaxed">{item}</p>
                  </motion.div>
                ))}
              </div>
            )}
          </div>
        </motion.section>

        {/* ── ORIGIN OF INVESTIGATION ── */}
        {candidate && (
          <motion.section
            initial={{ opacity: 0, y: 32 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          >
            <div className="p-[1px] rounded-2xl" style={{ background: `linear-gradient(135deg, ${verdictCfg.accent}40, rgba(255,255,255,0.06))` }}>
              <div className="bg-[#080808] rounded-[calc(1rem-1px)] p-8 md:p-10 relative overflow-hidden">
                <div className="absolute top-0 right-0 p-8 opacity-[0.04] select-none pointer-events-none">
                  <Link2 className="w-32 h-32" style={{ color: verdictCfg.accent }} />
                </div>

                <p className="text-[10px] font-bold tracking-widest uppercase font-mono mb-5 flex items-center gap-2" style={{ color: verdictCfg.accent }}>
                  <span className="w-1.5 h-1.5 rounded-full animate-live-pulse" style={{ backgroundColor: verdictCfg.accent }} />
                  Origin of Investigation
                </p>

                <div className="flex flex-col md:flex-row gap-8 items-start">
                  <div className="flex-1 space-y-4">
                    <h3 className="text-2xl sm:text-3xl font-bold text-white tracking-tight font-geist">
                      {candidate.title}
                    </h3>
                    <div className="flex items-center gap-4 flex-wrap">
                      <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-lg text-white/55 text-sm font-medium">
                        {candidate.source_name}
                      </span>
                      <a
                        href={candidate.url}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center gap-1.5 text-sm font-bold transition-colors hover:text-white"
                        style={{ color: verdictCfg.accent }}
                      >
                        View Source <ExternalLink className="w-3.5 h-3.5" />
                      </a>
                    </div>
                  </div>

                  {candidate.screenshot_path && (
                    <div className="w-full md:w-2/5 shrink-0 rounded-xl overflow-hidden border border-white/10 shadow-2xl relative group/ss">
                      <div className="absolute inset-0 z-10 mix-blend-overlay opacity-0 group-hover/ss:opacity-100 transition-opacity duration-500 pointer-events-none" style={{ backgroundColor: `${verdictCfg.accent}25` }} />
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={candidate.screenshot_path}
                        alt="Origin source"
                        className="w-full object-cover grayscale-[20%] group-hover/ss:grayscale-0 transition-all duration-500"
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
          </motion.section>
        )}

        {/* ── THE CLAIM vs THE REALITY ── */}
        {dashboard && (dashboard.why_people_care || dashboard.what_we_found) && (
          <motion.section
            initial={{ opacity: 0, y: 32 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          >
            <SectionHeader label="Claim vs Reality" />
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">

              {/* The Claim */}
              <div className="group relative bg-[#0d0808] border border-rose-500/15 hover:border-rose-500/30 p-8 rounded-2xl transition-all duration-300 overflow-hidden">
                <div className="absolute top-0 left-0 w-[3px] h-full bg-rose-500/60 group-hover:bg-rose-500 transition-colors duration-300" />
                <div className="absolute top-4 right-6 text-[80px] leading-none text-rose-500/5 font-black select-none font-geist pointer-events-none">&ldquo;</div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2.5 bg-rose-500/10 text-rose-400 rounded-xl">
                    <Zap className="w-5 h-5" />
                  </div>
                  <h3 className="text-lg font-black text-white tracking-tight uppercase font-geist">The Claim</h3>
                </div>
                <p className="text-white/65 text-base leading-relaxed">
                  {dashboard.why_people_care}
                </p>
              </div>

              {/* The Reality */}
              <div className="group relative bg-[#080d08] border border-emerald-500/15 hover:border-emerald-500/30 p-8 rounded-2xl transition-all duration-300 overflow-hidden">
                <div className="absolute top-0 left-0 w-[3px] h-full bg-emerald-500/60 group-hover:bg-emerald-500 transition-colors duration-300" />
                <div className="absolute top-4 right-6 text-[80px] leading-none text-emerald-500/5 font-black select-none font-geist pointer-events-none">✓</div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2.5 bg-emerald-500/10 text-emerald-400 rounded-xl">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <h3 className="text-lg font-black text-white tracking-tight uppercase font-geist">The Reality</h3>
                </div>
                <p className="text-white/70 text-base leading-relaxed">
                  {dashboard.what_we_found}
                </p>
              </div>
            </div>
          </motion.section>
        )}

        {/* ══════════════════════════════════════════════════════
            EVIDENCE DOSSIER
        ══════════════════════════════════════════════════════ */}
        {claims && claims.length > 0 && (
          <motion.section
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6 }}
          >
            <SectionHeader label="Evidence Dossier" count={claims.length} />

            <div className="space-y-4">
              {claims.map((claim: any, idx: number) => {
                const isExpanded  = expandedClaim === idx;
                const claimCfg    = getVerdictConfig(claim.claim_status);

                return (
                  <div
                    key={idx}
                    className="rounded-2xl overflow-hidden transition-all duration-400"
                    style={{
                      border: `1px solid ${isExpanded ? claimCfg.accent + '35' : 'rgba(255,255,255,0.07)'}`,
                      background: isExpanded ? `linear-gradient(135deg, ${claimCfg.accent}06, #080808)` : '#0a0a0a',
                    }}
                  >
                    {/* Claim header */}
                    <button
                      id={`claim-${idx}`}
                      onClick={() => setExpandedClaim(isExpanded ? null : idx)}
                      className="w-full text-left p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center justify-between gap-5 relative"
                    >
                      {/* Big claim number — decorative */}
                      <span
                        className="absolute right-24 top-1/2 -translate-y-1/2 text-[80px] font-black font-geist leading-none opacity-[0.04] pointer-events-none select-none hidden sm:block"
                      >
                        {String(idx + 1).padStart(2, "0")}
                      </span>

                      <div className="flex-1 space-y-3">
                        <div className="flex flex-wrap items-center gap-2.5">
                          <span
                            className={`flex items-center gap-1 px-2.5 py-1 rounded text-[10px] font-black uppercase tracking-widest border ${claimCfg.color} ${claimCfg.border} ${claimCfg.bg}`}
                          >
                            {getVerdictIcon(claim.claim_status, "w-3 h-3")}
                            {claim.claim_status}
                          </span>
                          <span className="text-white/25 text-[10px] font-mono font-bold tracking-widest">
                            CLAIM {String(idx + 1).padStart(2, "0")}
                          </span>
                        </div>
                        <h4 className="text-lg sm:text-xl font-bold text-white leading-snug font-geist">
                          {claim.claim_text}
                        </h4>
                      </div>

                      <div className="flex items-center gap-5 shrink-0">
                        <ConfidenceBar score={claim.confidence_score} label="Confidence" />
                        <motion.div
                          animate={{ rotate: isExpanded ? 180 : 0 }}
                          transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
                          className="p-2 rounded-full bg-white/5 text-white/40 flex-shrink-0"
                        >
                          <ChevronDown className="w-4 h-4" />
                        </motion.div>
                      </div>
                    </button>

                    {/* Expandable evidence */}
                    <AnimatePresence>
                      {isExpanded && (
                        <motion.div
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: "auto", opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                          className="overflow-hidden"
                        >
                          <div className="p-6 sm:p-8 pt-0 border-t border-white/[0.06]">
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 pt-7">

                              {/* Supporting */}
                              <div className="space-y-4">
                                <h5 className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-widest mb-5">
                                  <CheckCircle2 className="w-3.5 h-3.5" />
                                  Supporting ({claim.evidence?.length || 0})
                                </h5>
                                {claim.evidence?.length === 0 && (
                                  <p className="text-white/25 text-sm italic">No supporting evidence found.</p>
                                )}
                                {claim.evidence?.map((ev: any, i: number) => (
                                  <EvidenceCard key={i} ev={ev} variant="supporting" />
                                ))}
                              </div>

                              {/* Contradicting */}
                              <div className="space-y-4">
                                <h5 className="flex items-center gap-2 text-rose-400 text-xs font-bold uppercase tracking-widest mb-5">
                                  <XCircle className="w-3.5 h-3.5" />
                                  Contradicting ({claim.contradicting_evidence?.length || 0})
                                </h5>
                                {claim.contradicting_evidence?.length === 0 && (
                                  <p className="text-white/25 text-sm italic">No contradicting evidence found.</p>
                                )}
                                {claim.contradicting_evidence?.map((ev: any, i: number) => (
                                  <EvidenceCard key={i} ev={ev} variant="contradicting" />
                                ))}
                              </div>
                            </div>
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                );
              })}
            </div>
          </motion.section>
        )}

        {/* ══════════════════════════════════════════════════════
            TIMELINE + CONTEXT
        ══════════════════════════════════════════════════════ */}
        {(dashboard?.timeline || dashboard?.context) && (
          <section className="grid grid-cols-1 lg:grid-cols-5 gap-12 lg:gap-16 pt-12 border-t border-white/[0.06]">

            {/* Context */}
            {dashboard?.context && (
              <div className="lg:col-span-3 space-y-10">
                <h3 className="text-3xl font-black text-white tracking-tighter font-geist">
                  Investigation Context
                </h3>
                <div className="space-y-4">
                  {Object.entries(dashboard.context).map(([key, val], i) => (
                    <motion.div
                      key={key}
                      initial={{ opacity: 0, x: -16 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: i * 0.08, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                      className="bg-[#0a0a0a] border border-white/[0.06] hover:border-white/[0.12] p-6 rounded-2xl transition-all duration-300 group"
                    >
                      <h4 className="text-[11px] font-bold mb-3 uppercase tracking-widest flex items-center gap-2 text-white/40 group-hover:text-white/60 transition-colors">
                        <span className="text-base">{getContextIcon(key)}</span>
                        {key.replace(/_/g, " ")}
                      </h4>
                      <p className="text-white/65 leading-relaxed text-sm">
                        {val as string}
                      </p>
                    </motion.div>
                  ))}
                </div>
              </div>
            )}

            {/* Timeline */}
            {dashboard?.timeline && (
              <div className="lg:col-span-2">
                <h3 className="text-3xl font-black text-white tracking-tighter font-geist mb-10">
                  Timeline
                </h3>
                <div className="relative">
                  {/* Animated vertical line */}
                  <motion.div
                    className="absolute left-[7px] top-2 bottom-0 w-[1px]"
                    style={{
                      background: `linear-gradient(to bottom, ${verdictCfg.accent}, rgba(162,89,255,0.1))`,
                    }}
                    initial={{ scaleY: 0, originY: 0 }}
                    whileInView={{ scaleY: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 1.4, ease: [0.16, 1, 0.3, 1] }}
                  />

                  <div className="space-y-8 pl-8">
                    {dashboard.timeline.map((item: any, idx: number) => (
                      <motion.div
                        key={idx}
                        initial={{ opacity: 0, x: 16 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ delay: idx * 0.12, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                        className="relative group"
                      >
                        {/* Node */}
                        <div
                          className="absolute -left-[25px] top-1.5 w-3.5 h-3.5 rounded-full border-2 border-[#020202] flex-shrink-0 transition-transform duration-200 group-hover:scale-125"
                          style={{ backgroundColor: verdictCfg.accent, boxShadow: `0 0 10px ${verdictCfg.accent}60` }}
                        />

                        <div className="space-y-1.5">
                          <span className="text-[10px] font-bold font-mono tracking-widest uppercase" style={{ color: verdictCfg.accent }}>
                            {item.date}
                          </span>
                          <p className="text-white/80 text-sm leading-relaxed font-medium">
                            {item.event}
                          </p>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </section>
        )}

        {/* ── OPEN QUESTIONS ── */}
        {dashboard?.open_questions?.length > 0 && (
          <motion.section
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6 }}
            className="pt-12 border-t border-white/[0.06]"
          >
            <SectionHeader label="Open Questions" count={dashboard.open_questions.length} />
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {dashboard.open_questions.map((q: string, i: number) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                  className="flex items-start gap-4 p-6 rounded-2xl bg-[#0a0a0a] border border-white/[0.06] hover:border-[#A259FF]/20 hover:bg-[#0d0a14] transition-all duration-300 group"
                >
                  <div className="w-8 h-8 rounded-full bg-[#A259FF]/10 border border-[#A259FF]/20 flex items-center justify-center flex-shrink-0 group-hover:bg-[#A259FF]/15 transition-colors">
                    <QuestionIcon className="w-4 h-4 text-[#A259FF]" />
                  </div>
                  <p className="text-white/65 text-sm leading-relaxed">{q}</p>
                </motion.div>
              ))}
            </div>
          </motion.section>
        )}

        {/* ── SOURCES & TRANSPARENCY ── */}
        {dashboard?.sources?.length > 0 && (
          <motion.section
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6 }}
            className="pt-12 border-t border-white/[0.06]"
          >
            <div className="text-center mb-12">
              <h3 className="text-3xl font-black text-white tracking-tighter font-geist mb-3">
                Sources & Transparency
              </h3>
              <p className="text-white/35 text-sm max-w-xl mx-auto leading-relaxed">
                Every investigation relies on transparent, verifiable sources. Authority scores reflect historical accuracy and editorial credibility.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {dashboard.sources.map((src: any, idx: number) => (
                <motion.a
                  key={idx}
                  href={src.url}
                  target="_blank"
                  rel="noreferrer"
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: idx * 0.07, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                  whileHover={{ y: -3, transition: { duration: 0.2 } }}
                  className="block group"
                >
                  <div className="h-full p-5 bg-[#0a0a0a] border border-white/[0.06] group-hover:border-white/[0.15] rounded-2xl transition-all duration-200 relative overflow-hidden">
                    {/* Authority bar at top */}
                    <div
                      className="absolute top-0 left-0 h-[2px] transition-all duration-500 group-hover:opacity-100 opacity-60"
                      style={{
                        width: `${src.authority_score}%`,
                        backgroundColor: src.authority_score >= 90 ? '#10b981' : src.authority_score >= 75 ? '#3b82f6' : '#f59e0b',
                      }}
                    />

                    <div className="flex justify-between items-start mb-3 mt-1">
                      <span className="px-2 py-0.5 bg-white/5 border border-white/10 rounded text-[9px] font-mono text-white/40 uppercase tracking-wider">
                        {src.source_type}
                      </span>
                      <div className="text-right">
                        <span className="text-[11px] font-black font-mono" style={{
                          color: src.authority_score >= 90 ? '#10b981' : src.authority_score >= 75 ? '#3b82f6' : '#f59e0b'
                        }}>
                          {src.authority_score}
                        </span>
                        <span className="text-white/25 text-[9px] font-mono">/100</span>
                      </div>
                    </div>

                    <h4 className="text-white/75 group-hover:text-white font-semibold text-sm leading-snug mb-4 transition-colors">
                      {src.title}
                    </h4>

                    <span className="text-white/25 group-hover:text-white/50 text-[11px] font-bold uppercase flex items-center gap-1.5 transition-colors">
                      <ExternalLink className="w-3 h-3" />
                      {(() => { try { return new URL(src.url).hostname.replace("www.", ""); } catch { return "Verify"; } })()}
                    </span>
                  </div>
                </motion.a>
              ))}
            </div>

            {/* Transparency note */}
            <motion.div
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.3 }}
              className="mt-8 p-5 rounded-2xl bg-emerald-500/5 border border-emerald-500/15 flex items-center gap-4"
            >
              <ShieldCheck className="w-5 h-5 text-emerald-400 flex-shrink-0" />
              <p className="text-white/55 text-sm">
                <strong className="text-white/80">100% Human Verified.</strong>{" "}
                Every investigation, timeline, and verdict is audited and approved by a human investigator before publication.
              </p>
            </motion.div>
          </motion.section>
        )}
      </div>
    </motion.div>
  );
}
