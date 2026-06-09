'use client';

import { motion, useScroll, useTransform, useSpring } from 'framer-motion';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

// ── Factline geometric brand sigil ──────────────────────────
function FactlineSigil({ className = '' }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      {/* Outer ring */}
      <circle cx="16" cy="16" r="14" stroke="currentColor" strokeWidth="1.5" strokeOpacity="0.6" />
      {/* Middle ring */}
      <circle cx="16" cy="16" r="9"  stroke="currentColor" strokeWidth="1.5" strokeOpacity="0.85" />
      {/* Inner dot */}
      <circle cx="16" cy="16" r="3.5" fill="currentColor" />
      {/* Cross-hair lines */}
      <line x1="16" y1="2"  x2="16" y2="7"  stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
      <line x1="16" y1="25" x2="16" y2="30" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
      <line x1="2"  y1="16" x2="7"  y2="16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
      <line x1="25" y1="16" x2="30" y2="16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.5" />
    </svg>
  );
}

// ── Instagram icon ───────────────────────────────────────────
function InstagramIcon({ className = '' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
      <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
    </svg>
  );
}

// ── Nav link with animated underline ────────────────────────
function NavLink({ href, children, active }: { href: string; children: React.ReactNode; active: boolean }) {
  return (
    <Link href={href} className="relative group py-1 text-sm font-semibold tracking-wide transition-colors duration-200">
      <span className={active ? 'text-white' : 'text-white/40 group-hover:text-white/80'}>
        {children}
      </span>
      <span
        className={`absolute -bottom-0.5 left-0 h-px bg-[#A259FF] transition-all duration-300 ease-out ${active ? 'w-full' : 'w-0 group-hover:w-full'}`}
      />
    </Link>
  );
}

export function Navbar() {
  const pathname = usePathname();
  const { scrollYProgress } = useScroll();

  // Smooth spring for scroll progress bar
  const scaleX = useSpring(scrollYProgress, { stiffness: 200, damping: 30, restDelta: 0.001 });

  // Navbar opacity on scroll (subtle)
  const navBg = useTransform(scrollYProgress, [0, 0.05], ['rgba(2,2,2,0)', 'rgba(2,2,2,0.85)']);

  return (
    <>
      {/* Scroll progress bar — absolute top */}
      <motion.div
        className="fixed top-0 left-0 right-0 z-[60] h-[2px] origin-left bg-gradient-to-r from-[#A259FF] via-[#c084fc] to-[#A259FF]"
        style={{ scaleX }}
      />

      <motion.nav
        style={{ backgroundColor: navBg }}
        className="fixed top-0 z-50 w-full border-b border-white/[0.05] backdrop-blur-2xl backdrop-saturate-150"
      >
        <div className="mx-auto max-w-7xl px-5 lg:px-8 h-[68px] flex items-center justify-between gap-6">

          {/* Brand */}
          <Link href="/" aria-label="Factline home">
            <motion.div
              initial={{ opacity: 0, x: -16 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              className="flex items-center gap-3 cursor-pointer group"
            >
              <div className="relative flex-shrink-0 text-[#A259FF] group-hover:text-white transition-colors duration-300">
                <FactlineSigil className="w-7 h-7" />
                {/* Glow on hover */}
                <div className="absolute inset-0 rounded-full bg-[#A259FF]/20 blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none" />
              </div>

              <span className="font-geist font-black text-[1.35rem] tracking-[-0.04em] text-white leading-none">
                FACTLINE
              </span>
            </motion.div>
          </Link>

          {/* Center nav links — desktop */}
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
            className="hidden sm:flex items-center gap-8"
          >
          <NavLink href="/archive"    active={pathname === '/archive'}>Archive</NavLink>
            <NavLink href="/ai-process" active={pathname === '/ai-process'}>Methodology</NavLink>
          </motion.div>

          {/* Right controls */}
          <motion.div
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
            className="flex items-center gap-3"
          >
            {/* Live indicator */}
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/[0.04] border border-white/[0.07] text-white/50 text-[11px] font-mono font-semibold uppercase tracking-widest">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-live-pulse shadow-[0_0_6px_rgba(52,211,153,0.8)]" />
              Live
            </div>

            {/* AI Enhanced badge */}
            <Link href="/ai-process" aria-label="AI Enhanced methodology">
              <button className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#A259FF]/10 border border-[#A259FF]/25 hover:bg-[#A259FF]/20 hover:border-[#A259FF]/60 text-[#A259FF] transition-all duration-200 text-[11px] font-bold uppercase tracking-widest group">
                <svg className="w-3 h-3 group-hover:animate-spin" style={{ animationDuration: '2s' }} viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2L9.19 8.63L2 9.24L7 13.47L5.29 21L12 17.27L18.71 21L17 13.47L22 9.24L14.81 8.63L12 2Z"/>
                </svg>
                AI Enhanced
              </button>
            </Link>

            {/* Instagram */}
            <a
              href="https://www.instagram.com/factline.one/"
              target="_blank"
              rel="noreferrer"
              aria-label="Factline on Instagram"
              className="p-2 rounded-full text-white/40 hover:text-white border border-transparent hover:border-white/10 hover:bg-white/[0.05] transition-all duration-200"
            >
              <InstagramIcon className="w-[18px] h-[18px]" />
            </a>
          </motion.div>
        </div>
      </motion.nav>
    </>
  );
}
