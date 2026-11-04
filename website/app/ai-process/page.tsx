'use client';

import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import {
  ChevronLeft,
  Radar,
  Network,
  Brain,
  ShieldCheck,
  Globe,
} from 'lucide-react';
import Link from 'next/link';
import { Navbar } from '../../components/Navbar';

// ── Pipeline steps ─────────────────────────────────────────────
const STEPS = [
  {
    icon:  <Globe className="w-6 h-6" />,
    label: '01',
    title: 'Signal Detection',
    description:
      'Our system continuously monitors social media, news outlets, and online communities for emerging claims, viral misinformation, and breaking narratives that need investigation.',
    color: '#A259FF',
  },
  {
    icon:  <Radar className="w-6 h-6" />,
    label: '02',
    title: 'Source Aggregation',
    description:
      'Thousands of primary and secondary sources are identified, crawled, and indexed in real time — from official statements and scientific papers to forum posts and video transcripts.',
    color: '#3b82f6',
  },
  {
    icon:  <Network className="w-6 h-6" />,
    label: '03',
    title: 'AI Analysis',
    description:
      'Advanced LLMs parse the aggregated sources, identify claim patterns, extract evidence, assign authority scores, and generate a structured investigation draft — at a scale no human team could achieve alone.',
    color: '#8b5cf6',
  },
  {
    icon:  <Brain className="w-6 h-6" />,
    label: '04',
    title: 'Human Review',
    description:
      'A human investigator audits every AI-generated finding. They verify sources, challenge conclusions, add nuanced context, and make the final verdict call. AI does the heavy lifting; humans hold the accountability.',
    color: '#f59e0b',
  },
  {
    icon:  <ShieldCheck className="w-6 h-6" />,
    label: '05',
    title: 'Published',
    description:
      'The investigation is published as an immutable, evidence-backed report. Every claim, source, and conclusion is permanently archived and publicly accessible.',
    color: '#10b981',
  },
];

// ── Step card ──────────────────────────────────────────────────
function StepCard({ step, index }: { step: typeof STEPS[0]; index: number }) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: '-80px' });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, x: index % 2 === 0 ? -24 : 24, y: 12 }}
      animate={inView ? { opacity: 1, x: 0, y: 0 } : {}}
      transition={{ delay: index * 0.1, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
      className="group flex gap-6 items-start relative"
    >
      {/* Icon */}
      <div
        className="flex-shrink-0 w-14 h-14 rounded-2xl flex items-center justify-center transition-all duration-300 group-hover:scale-110"
        style={{
          backgroundColor: `${step.color}15`,
          border: `1px solid ${step.color}30`,
          color: step.color,
          boxShadow: inView ? `0 0 20px ${step.color}15` : 'none',
        }}
      >
        {step.icon}
      </div>

      <div className="flex-1 pb-10 relative">
        {/* Connector line */}
        {index < STEPS.length - 1 && (
          <motion.div
            className="absolute left-[-32px] top-14 w-px"
            style={{ backgroundColor: `${step.color}20` }}
            initial={{ height: 0 }}
            animate={inView ? { height: 'calc(100% - 16px)' } : {}}
            transition={{ delay: index * 0.1 + 0.3, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          />
        )}

        <div className="mb-1">
          <span className="text-[10px] font-mono font-bold tracking-widest uppercase" style={{ color: step.color }}>
            {step.label}
          </span>
        </div>
        <h3 className="text-xl font-black text-white tracking-tight mb-3 font-geist">
          {step.title}
        </h3>
        <p className="text-white/55 text-sm leading-relaxed">
          {step.description}
        </p>
      </div>
    </motion.div>
  );
}

export default function AiProcessView() {
  return (
    <>
      {/* Ambient */}
      <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-15%] left-[-5%] w-[55%] h-[55%] bg-[#A259FF]/8 rounded-full blur-[180px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-blue-500/5 rounded-full blur-[200px]" />
      </div>

      <Navbar />

      <main className="relative z-10 pt-20">
        <div className="max-w-3xl mx-auto px-6 lg:px-8 py-28">

          {/* Back link */}
          <Link href="/" className="inline-block mb-14">
            <motion.div
              initial={{ opacity: 0, x: -12 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              className="flex items-center gap-2 text-sm font-semibold text-white/40 hover:text-white/80 transition-colors group"
            >
              <ChevronLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
              Back to Archive
            </motion.div>
          </Link>

          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="mb-16"
          >
            <div className="flex items-center gap-3 mb-6">
              <span className="text-[11px] font-bold tracking-widest uppercase text-[#A259FF] font-mono">
                Our Process
              </span>
              <div className="h-px bg-gradient-to-r from-[#A259FF]/40 to-transparent flex-grow" />
            </div>

            <h1 className="text-5xl sm:text-6xl font-black tracking-tighter text-white mb-6 font-geist leading-[1.02]">
              AI Augmented,<br />
              <span className="text-white/50">Human Verified.</span>
            </h1>

            <p className="text-white/55 text-lg leading-relaxed max-w-2xl">
              Factline uses advanced AI to investigate at scale — but every investigation is reviewed, challenged, and published by a human. Here&apos;s exactly how that works.
            </p>
          </motion.div>

          {/* Pipeline */}
          <div className="space-y-0 relative mb-20">
            {STEPS.map((step, i) => (
              <StepCard key={i} step={step} index={i} />
            ))}
          </div>

          {/* Human verification callout */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="relative rounded-2xl overflow-hidden border border-emerald-500/20 bg-emerald-500/5 p-8"
          >
            <div className="absolute top-0 right-0 p-8 opacity-[0.04] pointer-events-none">
              <ShieldCheck className="w-32 h-32 text-emerald-400" />
            </div>

            <div className="relative z-10 flex items-start gap-5">
              <div className="p-3 bg-emerald-500/15 rounded-xl flex-shrink-0">
                <ShieldCheck className="w-6 h-6 text-emerald-400" />
              </div>
              <div>
                <h3 className="text-2xl font-black text-white mb-3 font-geist tracking-tight">
                  100% Human Verified
                </h3>
                <p className="text-white/60 leading-relaxed">
                  AI is only a tool — it is prone to hallucination and lacks nuanced human context.
                  That is why <strong className="text-white/85">every single investigation, timeline, and verdict</strong> is
                  thoroughly audited, fact-checked, and approved by a human investigator before it is
                  published on our platform. The AI does the heavy lifting of gathering evidence,
                  but final judgment and accountability rest entirely with our team.
                </p>
              </div>
            </div>
          </motion.div>

          {/* Why it matters */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.7, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
            className="mt-6 rounded-2xl border border-white/[0.06] bg-[#0a0a0a] p-8"
          >
            <h3 className="text-xl font-black text-white mb-4 font-geist tracking-tight">
              Why this matters
            </h3>
            <div className="space-y-3">
              {[
                'Every claim has verifiable sources — we don\'t just summarize.',
                'Authority scores help you evaluate source credibility instantly.',
                'The full evidence chain is publicly visible, not just the conclusion.',
                'Investigations are immutable — we don\'t quietly edit verdicts.',
              ].map((item, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.08, duration: 0.4 }}
                  className="flex items-start gap-3"
                >
                  <span className="w-4 h-4 rounded-full bg-[#A259FF]/20 border border-[#A259FF]/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#A259FF]" />
                  </span>
                  <p className="text-white/60 text-sm leading-relaxed">{item}</p>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* CTA back */}
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-16 text-center"
          >
            <Link href="/">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="px-8 py-4 rounded-2xl bg-[#A259FF]/15 border border-[#A259FF]/30 hover:bg-[#A259FF]/25 hover:border-[#A259FF]/60 text-[#A259FF] hover:text-white font-bold text-sm tracking-wide transition-all duration-200"
              >
                🕳️ View the Investigation Archive
              </motion.button>
            </Link>
          </motion.div>

        </div>
      </main>
    </>
  );
}
