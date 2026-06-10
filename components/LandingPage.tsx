"use client";

/* eslint-disable @next/next/no-img-element */
import { useRef } from "react";
import { motion, useScroll, useTransform, useInView } from "framer-motion";
import Link from "next/link";
import Image from "next/image";
import {
  ArrowRight,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  HelpCircle,
  ChevronDown,
  MoveRight,
  Newspaper,
  BookOpen,
  Search,
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
      bg: "bg-emerald-950/30",
      border: "border-emerald-900/50",
      accent: "#10b981",
      icon: <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("likely"))
    return {
      color: "text-blue-400",
      bg: "bg-blue-950/30",
      border: "border-blue-900/50",
      accent: "#3b82f6",
      icon: <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("mixed") || v.includes("disputed"))
    return {
      color: "text-amber-400",
      bg: "bg-amber-950/30",
      border: "border-amber-900/50",
      accent: "#f59e0b",
      icon: <AlertTriangle className="w-3.5 h-3.5 shrink-0" />,
    };
  if (v.includes("false"))
    return {
      color: "text-rose-400",
      bg: "bg-rose-950/30",
      border: "border-rose-900/50",
      accent: "#ef4444",
      icon: <XCircle className="w-3.5 h-3.5 shrink-0" />,
    };
  return {
    color: "text-zinc-400",
    bg: "bg-zinc-900/50",
    border: "border-zinc-800",
    accent: "#a1a1aa",
    icon: <HelpCircle className="w-3.5 h-3.5 shrink-0" />,
  };
};

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
  const tags = report.metadata?.tags?.slice(0, 4) || [];
  const title = report.dashboard?.hero_title || report.public.title;

  return (
    <div className="relative group w-full">
      <Link
        href={`/report/${report.slug}`}
        className="block focus:outline-none"
      >
        <div className="flex flex-col md:flex-row bg-zinc-900/30 border border-zinc-800 rounded-lg overflow-hidden transition-colors hover:border-zinc-600">
          {/* Featured Image Side */}
          {report.metadata?.cover_image && (
            <div className="md:w-5/12 relative overflow-hidden">
              <div className="absolute inset-0 bg-zinc-950/20 group-hover:bg-transparent transition-colors z-10" />
              <Image
                src={report.metadata.cover_image}
                alt={title}
                fill
                priority
                className="object-cover grayscale-[20%] group-hover:scale-105 transition-transform duration-700"
              />
            </div>
          )}

          {/* Content Side */}
          <div className="flex-1 p-8 sm:p-12">
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
                  className="px-2.5 py-1 rounded-md border border-zinc-800 text-zinc-500 text-[10px] font-mono tracking-wider uppercase"
                >
                  {t}
                </span>
              ))}
              <span className="ml-auto text-zinc-500 text-xs font-mono tracking-wider">
                {new Date(report.public.published_at).toLocaleDateString(
                  "en-US",
                  { month: "short", day: "numeric", year: "numeric" },
                )}
              </span>
            </div>

            <h3 className="text-3xl sm:text-4xl font-black font-serif tracking-tight text-zinc-100 leading-snug mb-4 group-hover:text-blue-400 transition-colors">
              {title}
            </h3>

            <p className="text-zinc-400 text-lg font-serif leading-relaxed mb-8 italic">
              {report.dashboard?.hero_summary || report.public.summary}
            </p>

            <div className="flex items-center justify-between pt-6 border-t border-zinc-800/50">
              <span className="text-sm font-bold flex items-center gap-2 text-zinc-300 group-hover:text-zinc-100 transition-colors">
                Read full investigation
                <MoveRight className="w-4 h-4 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all duration-200" />
              </span>
            </div>
          </div>
        </div>
      </Link>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Recent Reports mini-grid
// ─────────────────────────────────────────────────────────────

function ReportMiniCard({ report, index }: { report: Report; index: number }) {
  const cfg = getVerdictCfg(report.verdict);
  return (
    <Reveal delay={index * 0.07}>
      <Link
        href={`/report/${report.slug}`}
        className="block group focus:outline-none h-full"
      >
        <div className="h-full p-6 rounded-lg border border-zinc-800 bg-zinc-900/30 hover:bg-zinc-900/50 hover:border-zinc-600 transition-all duration-300 relative">
          <div className="flex items-center justify-between mb-4">
            <span
              className={`flex items-center gap-1.5 text-xs font-bold uppercase tracking-widest ${cfg.color}`}
            >
              {cfg.icon}
              {report.verdict}
            </span>
            <time className="text-zinc-500 text-[11px] font-mono">
              {report.published_at
                ? new Date(report.published_at).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                  })
                : "—"}
            </time>
          </div>
          <h4 className="text-zinc-200 group-hover:text-blue-400 text-xl font-bold font-serif leading-snug line-clamp-3 transition-colors">
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
    <div className="relative w-full bg-zinc-950 text-zinc-100 min-h-screen">
      {/* ══════════════════════════════════════════════════════
          HERO
      ══════════════════════════════════════════════════════ */}
      <section
        ref={heroRef}
        className="relative w-full min-h-[90vh] flex flex-col justify-center overflow-hidden pt-20"
      >
        <motion.div
          style={{ y: heroY, opacity: heroOpacity }}
          className="relative z-10 mx-auto w-full max-w-6xl px-6 lg:px-8 pt-20 pb-16"
        >
          <div className="flex items-center gap-3 mb-10">
            <span className="w-1.5 h-1.5 rounded-full bg-zinc-400 animate-pulse" />
            <span className="text-xs font-mono font-bold tracking-widest uppercase text-zinc-500">
              The Front Page of Truth
            </span>
          </div>

          <div className="max-w-4xl">
            <motion.h1
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.8, ease: "easeOut" }}
              className="text-5xl sm:text-7xl lg:text-[8rem] font-black font-serif tracking-tight text-zinc-100 leading-[1.05] mb-8"
            >
              Everyone saw the headline.
            </motion.h1>

            <motion.p
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2, duration: 0.8, ease: "easeOut" }}
              className="text-2xl sm:text-4xl font-serif text-zinc-400 leading-tight italic"
            >
              We read the sources. Factline investigates the claims circulating
              online, gathering evidence, and publishing transparent reports.
            </motion.p>
          </div>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.7 }}
            className="flex flex-wrap items-center gap-6 mt-16"
          >
            <Link href="/archive">
              <button className="flex items-center gap-2 px-8 py-4 rounded-md bg-zinc-100 text-zinc-950 font-bold tracking-wide hover:bg-zinc-300 transition-colors">
                Explore Investigations
                <ArrowRight className="w-4 h-4" />
              </button>
            </Link>
          </motion.div>
        </motion.div>

        {/* Scroll cue */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1, duration: 1 }}
          className="absolute bottom-8 left-6 flex items-center gap-3 text-zinc-500"
        >
          <span className="text-xs font-mono tracking-widest uppercase">
            Scroll down
          </span>
          <motion.div
            animate={{ y: [0, 5, 0] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          >
            <ChevronDown className="w-4 h-4" />
          </motion.div>
        </motion.div>
      </section>

      {/* ══════════════════════════════════════════════════════
          FEATURED INVESTIGATION
      ══════════════════════════════════════════════════════ */}
      {featuredReport && (
        <section className="relative py-24 sm:py-32 border-t border-zinc-800 bg-zinc-950/50">
          <div className="mx-auto max-w-6xl px-6 lg:px-8">
            <Reveal className="mb-12">
              <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-zinc-100 font-serif mb-4">
                Latest Investigation
              </h2>
              <div className="w-24 h-1 bg-zinc-800" />
            </Reveal>
            <Reveal delay={0.1}>
              <InvestigationShowcase report={featuredReport} />
            </Reveal>
          </div>
        </section>
      )}

      {/* ══════════════════════════════════════════════════════
          HOW WE WORK (Editorial Layout)
      ══════════════════════════════════════════════════════ */}
      <section className="relative py-24 sm:py-32 border-t border-zinc-800">
        <div className="mx-auto max-w-6xl px-6 lg:px-8">
          <Reveal className="mb-16">
            <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-zinc-100 font-serif mb-4">
              The Factline Standard
            </h2>
            <div className="w-24 h-1 bg-zinc-800" />
          </Reveal>

          <div className="grid md:grid-cols-3 gap-12">
            {[
              {
                title: "Sources, not summaries.",
                desc: "Every conclusion is backed by verifiable, cited sources. We test claims against primary data, not vibes.",
                icon: <BookOpen className="w-8 h-8 text-zinc-500 mb-6" />,
              },
              {
                title: "Deep, not viral.",
                desc: "We prioritize accuracy over speed. Investigations take time. Truth is worth the wait.",
                icon: <Search className="w-8 h-8 text-zinc-500 mb-6" />,
              },
              {
                title: "Transparent, always.",
                desc: "Every evidence trail is public. You can verify every step of every investigation.",
                icon: <Newspaper className="w-8 h-8 text-zinc-500 mb-6" />,
              },
            ].map((item, i) => (
              <Reveal key={i} delay={i * 0.1}>
                <div>
                  {item.icon}
                  <h3 className="text-2xl font-bold font-serif text-zinc-100 mb-4">
                    {item.title}
                  </h3>
                  <p className="text-zinc-400 leading-relaxed text-lg">
                    {item.desc}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════
          RECENT INVESTIGATIONS
      ══════════════════════════════════════════════════════ */}
      {recentReports.length > 0 && (
        <section className="relative py-24 sm:py-32 border-t border-zinc-800 bg-zinc-950/50">
          <div className="mx-auto max-w-6xl px-6 lg:px-8">
            <Reveal className="mb-12 flex flex-col sm:flex-row sm:items-end justify-between gap-6">
              <div>
                <h2 className="text-4xl sm:text-5xl font-black tracking-tight text-zinc-100 font-serif mb-4">
                  The Archive
                </h2>
                <div className="w-24 h-1 bg-zinc-800" />
              </div>
              <Link href="/archive">
                <button className="flex items-center gap-2 px-5 py-2 rounded-md border border-zinc-700 text-zinc-300 hover:text-zinc-100 hover:border-zinc-500 text-sm font-bold transition-all whitespace-nowrap">
                  View all investigations
                  <ArrowRight className="w-4 h-4" />
                </button>
              </Link>
            </Reveal>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {recentReports.map((r, i) => (
                <ReportMiniCard key={r.slug} report={r} index={i} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ══════════════════════════════════════════════════════
          FOOTER
      ══════════════════════════════════════════════════════ */}
      <footer className="border-t border-zinc-800 py-12 bg-zinc-950">
        <div className="mx-auto max-w-6xl px-6 lg:px-8 flex flex-col md:flex-row items-center justify-between gap-6">
          <Image
            src="/assets/logo.png"
            alt="Factline Logo"
            width={120}
            height={24}
            className="h-5 w-auto opacity-50 grayscale"
          />
          <span className="text-zinc-500 text-xs font-mono tracking-wider text-center md:text-left">
            © 2026 Factline. All investigations are evidence-backed.
          </span>
          <div className="flex items-center gap-6 text-zinc-500 text-xs font-mono tracking-wider">
            <Link
              href="/archive"
              className="hover:text-zinc-300 transition-colors uppercase"
            >
              Archive
            </Link>
            <a
              href="#"
              className="hover:text-zinc-300 transition-colors uppercase"
            >
              About
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
