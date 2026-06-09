'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, X } from 'lucide-react';
import { ReportCardView, Report } from './ReportCardView';

// ── Animation variants ─────────────────────────────────────────
const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.07, delayChildren: 0.1 },
  },
};

// ── Verdict filter tabs ─────────────────────────────────────────
const FILTERS = [
  { label: 'All',       value: 'all',      color: 'rgba(255,255,255,0.8)' },
  { label: 'Verified',  value: 'verifi',   color: '#10b981' },
  { label: 'Likely',    value: 'likely',   color: '#3b82f6' },
  { label: 'Mixed',     value: 'mixed',    color: '#f59e0b' },
  { label: 'False',     value: 'false',    color: '#ef4444' },
];

// ── Tagline lines ───────────────────────────────────────────────
const TAGLINES = [
  { emoji: '🌐', text: ' internet says one thing',   delay: 0.2,  opacity: 0.38 },
  { emoji: '📚', text: ' sources say another',       delay: 0.9,  opacity: 0.55 },
  { emoji: '🕳️', text: ' we go down the rabbit hole', delay: 1.7, opacity: 1.0, hero: true },
];

export function ReportList({ initialReports }: { initialReports: Report[] }) {
  const [searchQuery,    setSearchQuery]    = useState('');
  const [activeFilter,   setActiveFilter]   = useState('all');

  const filteredReports = useMemo(() => {
    let reports = initialReports;

    // Filter by verdict
    if (activeFilter !== 'all') {
      reports = reports.filter(r =>
        (r.verdict || '').toLowerCase().includes(activeFilter)
      );
    }

    // Filter by search
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      reports = reports.filter(
        r =>
          r.title.toLowerCase().includes(q) ||
          r.summary.toLowerCase().includes(q),
      );
    }

    return reports;
  }, [initialReports, searchQuery, activeFilter]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="relative w-full grain-overlay"
    >
      {/* ── Ambient background glows ── */}
      <div className="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        <div className="absolute top-[-15%] left-[-5%] w-[55%] h-[55%] bg-[#A259FF]/8 rounded-full blur-[180px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-blue-500/5 rounded-full blur-[200px]" />
        <div className="absolute top-[40%] left-[60%] w-[30%] h-[30%] bg-emerald-500/3 rounded-full blur-[150px]" />
      </div>

      {/* ───────────── HERO ───────────── */}
      <div className="relative z-10 pt-36 pb-24 sm:pt-44 sm:pb-32">
        <div className="mx-auto max-w-5xl px-6 lg:px-8 text-center flex flex-col items-center">

          {/* Tagline stagger */}
          <div className="space-y-3 mb-14 flex flex-col items-center">
            {TAGLINES.map((line, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 18 }}
                animate={{ opacity: line.opacity, y: 0 }}
                transition={{
                  delay: line.delay,
                  duration: 0.9,
                  ease: [0.16, 1, 0.3, 1],
                }}
                className={
                  line.hero
                    ? 'text-3xl sm:text-5xl lg:text-6xl font-black tracking-tighter text-white mt-3 font-geist'
                    : 'text-xl sm:text-3xl font-semibold tracking-tight text-white font-geist'
                }
              >
                <span
                  className={line.hero ? 'inline-block animate-float mr-3' : 'mr-2'}
                  style={line.hero ? { filter: 'drop-shadow(0 0 16px rgba(162,89,255,0.7))' } : {}}
                >
                  {line.emoji}
                </span>
                {line.text}
              </motion.div>
            ))}
          </div>

          {/* Stats strip */}
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 2.5, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="flex items-center gap-6 sm:gap-10 text-white/30 text-xs font-mono tracking-widest uppercase mb-14"
          >
            <span className="flex items-center gap-2">
              <span className="text-[#A259FF] font-black text-lg">{initialReports.length}</span>
              Investigations
            </span>
            <span className="w-px h-5 bg-white/10" />
            <span className="flex items-center gap-2">
              <span className="text-white/60 font-black text-lg">{initialReports.length}</span>
              Published
            </span>
            <span className="w-px h-5 bg-white/10" />
            <span className="flex items-center gap-2">
              <span className="text-emerald-400 font-black text-lg">100%</span>
              Human Verified
            </span>
          </motion.div>

          {/* Search bar */}
          <motion.div
            initial={{ y: 16, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 2.7, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="w-full max-w-2xl"
          >
            <div className="relative group">
              {/* Search icon */}
              <div className="absolute inset-y-0 left-0 flex items-center pl-5 pointer-events-none z-10">
                <Search className="w-5 h-5 text-white/30 group-focus-within:text-[#A259FF] transition-colors duration-200" />
              </div>

              <input
                id="search-archive"
                type="text"
                placeholder={`Search ${initialReports.length} investigations...`}
                className="w-full py-4 pl-14 pr-16 bg-white/[0.04] border border-white/[0.09] rounded-2xl focus:border-[#A259FF]/50 focus:bg-white/[0.06] outline-none transition-all duration-300 placeholder:text-white/25 text-white text-base backdrop-blur-xl"
                style={{
                  boxShadow: 'none',
                }}
                onFocus={e => {
                  (e.currentTarget.parentElement as HTMLElement).style.boxShadow = '0 0 0 1px rgba(162,89,255,0.4), 0 0 30px rgba(162,89,255,0.12)';
                }}
                onBlur={e => {
                  (e.currentTarget.parentElement as HTMLElement).style.boxShadow = 'none';
                }}
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />

              {/* Clear button */}
              <AnimatePresence>
                {searchQuery && (
                  <motion.button
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    onClick={() => setSearchQuery('')}
                    className="absolute inset-y-0 right-0 flex items-center pr-5 text-white/30 hover:text-white/70 transition-colors"
                    aria-label="Clear search"
                  >
                    <X className="w-4 h-4" />
                  </motion.button>
                )}
              </AnimatePresence>

              {/* Keyboard hint */}
              {!searchQuery && (
                <div className="absolute inset-y-0 right-0 hidden sm:flex items-center pr-5 pointer-events-none">
                  <span className="text-white/15 text-xs font-mono bg-white/5 border border-white/10 px-2 py-0.5 rounded">
                    ⌘K
                  </span>
                </div>
              )}
            </div>
          </motion.div>
        </div>
      </div>

      {/* ───────────── ARCHIVE ───────────── */}
      <div className="relative z-10 mx-auto max-w-7xl px-6 lg:px-8 pb-40">

        {/* Archive header + filter tabs */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2.9, duration: 0.6 }}
          className="flex flex-col sm:flex-row sm:items-center justify-between gap-5 mb-10 pb-6 border-b border-white/[0.06]"
        >
          <div className="flex items-baseline gap-3">
            <h2 className="text-xl font-black tracking-tight text-white font-geist">
              {searchQuery
                ? `Results`
                : activeFilter !== 'all'
                  ? FILTERS.find(f => f.value === activeFilter)?.label + ' Reports'
                  : 'Intelligence Archive'}
            </h2>
            <span className="text-white/30 text-sm font-mono">
              ({filteredReports.length})
            </span>
          </div>

          {/* Filter pills */}
          <div className="flex items-center gap-2 flex-wrap">
            {FILTERS.map(f => (
              <button
                key={f.value}
                onClick={() => setActiveFilter(f.value)}
                className={`relative px-3 py-1 rounded-full text-xs font-bold tracking-widest uppercase transition-all duration-200 ${
                  activeFilter === f.value
                    ? 'text-white'
                    : 'text-white/35 hover:text-white/65 bg-white/[0.03] hover:bg-white/[0.06]'
                }`}
                style={{
                  border: activeFilter === f.value ? `1px solid ${f.color}50` : '1px solid rgba(255,255,255,0.07)',
                  backgroundColor: activeFilter === f.value ? `${f.color}14` : undefined,
                  color: activeFilter === f.value ? f.color : undefined,
                }}
              >
                {f.label}
              </button>
            ))}
          </div>
        </motion.div>

        {/* Grid */}
        <AnimatePresence mode="wait">
          {filteredReports.length > 0 ? (
            <motion.div
              key={`${activeFilter}-${searchQuery}`}
              variants={containerVariants}
              initial="hidden"
              animate="show"
              exit={{ opacity: 0, transition: { duration: 0.2 } }}
              className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3"
            >
              {filteredReports.map(r => (
                <ReportCardView key={r.id} r={r} />
              ))}
            </motion.div>
          ) : (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="text-center py-32"
            >
              <div className="text-5xl mb-5">🕳️</div>
              <p className="text-white/40 font-semibold text-lg">No investigations found</p>
              <p className="text-white/25 text-sm mt-2">Try a different search or filter</p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}
