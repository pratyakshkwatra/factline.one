'use client';

import { memo } from 'react';
import { motion } from 'framer-motion';
import { CheckCircle2, AlertTriangle, XCircle, HelpCircle, MoveRight } from 'lucide-react';
import Link from 'next/link';

export interface Report {
  id: string;
  slug: string;
  title: string;
  summary: string;
  verdict: string;
  published_at: string;
  public_url: string;
}

// ── Verdict config ────────────────────────────────────────────
const getVerdictConfig = (verdict: string) => {
  const v = (verdict || '').toLowerCase();

  if (v.includes('verifi') || v === 'true')
    return {
      color:  'text-emerald-400',
      border: 'border-emerald-500/20',
      bg:     'bg-emerald-500/8',
      accent: '#10b981',
      pillBg: 'bg-emerald-500/10 border-emerald-500/25 text-emerald-400',
      barColor:'bg-emerald-500',
      icon:   <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
      label:  verdict,
    };

  if (v.includes('likely'))
    return {
      color:  'text-blue-400',
      border: 'border-blue-500/20',
      bg:     'bg-blue-500/8',
      accent: '#3b82f6',
      pillBg: 'bg-blue-500/10 border-blue-500/25 text-blue-400',
      barColor:'bg-blue-500',
      icon:   <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />,
      label:  verdict,
    };

  if (v.includes('mixed') || v.includes('disputed'))
    return {
      color:  'text-amber-400',
      border: 'border-amber-500/20',
      bg:     'bg-amber-500/8',
      accent: '#f59e0b',
      pillBg: 'bg-amber-500/10 border-amber-500/25 text-amber-400',
      barColor:'bg-amber-500',
      icon:   <AlertTriangle className="w-3.5 h-3.5 shrink-0" />,
      label:  verdict,
    };

  if (v.includes('false'))
    return {
      color:  'text-rose-400',
      border: 'border-rose-500/20',
      bg:     'bg-rose-500/8',
      accent: '#ef4444',
      pillBg: 'bg-rose-500/10 border-rose-500/25 text-rose-400',
      barColor:'bg-rose-500',
      icon:   <XCircle className="w-3.5 h-3.5 shrink-0" />,
      label:  verdict,
    };

  return {
    color:  'text-slate-400',
    border: 'border-slate-500/20',
    bg:     'bg-slate-500/8',
    accent: '#64748b',
    pillBg: 'bg-slate-500/10 border-slate-500/25 text-slate-400',
    barColor:'bg-slate-500',
    icon:   <HelpCircle className="w-3.5 h-3.5 shrink-0" />,
    label:  verdict || 'Under Review',
  };
};

// ── Item animation variant ────────────────────────────────────
const itemVariants = {
  hidden: { opacity: 0, y: 24 },
  show: {
    opacity: 1,
    y: 0,
    transition: { type: 'spring' as const, stiffness: 90, damping: 18 },
  },
};

export const ReportCardView = memo(({ r }: { r: Report }) => {
  const cfg = getVerdictConfig(r.verdict);

  const formattedDate = r.published_at
    ? new Date(r.published_at).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    : 'PENDING';

  return (
    <Link href={`/report/${r.slug}`} className="block h-full focus:outline-none" tabIndex={0}>
      <motion.article
        variants={itemVariants}
        whileHover={{ y: -5, transition: { type: 'spring', stiffness: 300, damping: 25 } }}
        whileTap={{ scale: 0.985 }}
        className="group relative flex flex-col h-full rounded-2xl overflow-hidden cursor-pointer"
        style={{
          background: 'linear-gradient(135deg, #0d0d0d 0%, #080808 100%)',
          border: `1px solid rgba(255,255,255,0.07)`,
        }}
      >
        {/* Verdict accent bar — top */}
        <div
          className="absolute top-0 left-0 right-0 h-[2px] opacity-80 group-hover:opacity-100 transition-opacity duration-300"
          style={{ background: cfg.accent }}
        />

        {/* Hover glow overlay */}
        <div
          className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
          style={{
            background: `radial-gradient(circle at 50% 0%, ${cfg.accent}08 0%, transparent 70%)`,
          }}
        />

        {/* Border highlight on hover */}
        <div
          className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"
          style={{ boxShadow: `inset 0 0 0 1px ${cfg.accent}25` }}
        />

        <div className="relative z-10 flex flex-col h-full p-7">

          {/* Header row: verdict + date */}
          <div className="flex items-center justify-between gap-3 mb-6">
            <div className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-bold tracking-widest uppercase border ${cfg.pillBg}`}>
              {cfg.icon}
              {cfg.label}
            </div>
            <time
              dateTime={r.published_at}
              className="text-white/30 text-[11px] font-mono tracking-wider uppercase whitespace-nowrap"
            >
              {formattedDate}
            </time>
          </div>

          {/* Content */}
          <div className="flex-grow space-y-3">
            <h3 className="text-[1.15rem] font-bold tracking-tight leading-snug text-white/90 group-hover:text-white transition-colors duration-300 font-geist">
              {r.title}
            </h3>
            <p className="text-[0.875rem] leading-relaxed text-white/45 group-hover:text-white/60 transition-colors duration-300 line-clamp-3">
              {r.summary}
            </p>
          </div>

          {/* Footer CTA */}
          <div className="mt-7 pt-5 border-t border-white/[0.06] flex items-center justify-between">
            <span className={`text-xs font-bold uppercase tracking-widest flex items-center gap-2 transition-all duration-200 ${cfg.color}`}>
              Go down the rabbit hole
              <motion.span
                initial={{ x: 0 }}
                whileHover={{ x: 3 }}
                className="inline-flex"
              >
                <MoveRight className="w-3.5 h-3.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
              </motion.span>
            </span>

            {/* Investigation ID hint */}
            <span className="text-white/15 text-[10px] font-mono tracking-wider hidden sm:block">
              {r.id?.slice(0, 8).toUpperCase() || 'FL-XXXX'}
            </span>
          </div>
        </div>
      </motion.article>
    </Link>
  );
});

ReportCardView.displayName = 'ReportCardView';
