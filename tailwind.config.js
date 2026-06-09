/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans:  ['Inter', 'system-ui', 'sans-serif'],
        mono:  ['Geist', 'ui-monospace', 'monospace'],
        serif: ['Playfair Display', 'Merriweather', 'serif'],
        geist: ['Geist', 'Inter', 'sans-serif'],
      },
      colors: {
        border:      "hsl(var(--border-tw))",
        background:  "hsl(var(--background))",
        foreground:  "hsl(var(--foreground))",
        primary: {
          DEFAULT:    "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        muted: {
          DEFAULT:    "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent:   '#2563EB',
        verified: '#10b981',
        likely:   '#3b82f6',
        mixed:    '#f59e0b',
        false:    '#ef4444',
        uncertain:'#64748b',
      },
      borderRadius: {
        sm:  '6px',
        md:  '12px',
        lg:  '20px',
        xl:  '28px',
        '2xl': '40px',
      },
      keyframes: {
        shimmer: {
          '0%':   { backgroundPosition: '-200% center' },
          '100%': { backgroundPosition: '200% center' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%':      { transform: 'translateY(-8px)' },
        },
        'glow-pulse': {
          '0%, 100%': { boxShadow: '0 0 20px rgba(162,89,255,0.15)' },
          '50%':      { boxShadow: '0 0 40px rgba(162,89,255,0.35)' },
        },
        'live-pulse': {
          '0%, 100%': { opacity: '1',   transform: 'scale(1)' },
          '50%':      { opacity: '0.3', transform: 'scale(0.75)' },
        },
        'scan-line': {
          '0%':   { transform: 'translateY(-100%)', opacity: '0' },
          '10%':  { opacity: '0.5' },
          '90%':  { opacity: '0.5' },
          '100%': { transform: 'translateY(100vh)', opacity: '0' },
        },
        grain: {
          '0%, 100%': { transform: 'translate(0,0)' },
          '25%':      { transform: 'translate(-2%,3%)' },
          '50%':      { transform: 'translate(3%,-2%)' },
          '75%':      { transform: 'translate(-1%,1%)' },
        },
        'fade-up': {
          from: { opacity: '0', transform: 'translateY(16px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        shimmer:     'shimmer 2s ease-in-out infinite',
        float:       'float 6s ease-in-out infinite',
        'glow-pulse':'glow-pulse 3s ease-in-out infinite',
        'live-pulse':'live-pulse 1.8s ease-in-out infinite',
        'scan-line': 'scan-line 7s ease-in-out infinite',
        grain:       'grain 8s steps(10) infinite',
        'fade-up':   'fade-up 0.5s var(--ease-out-expo) forwards',
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
      },
      typography: () => ({
        invert: {
          css: {
            '--tw-prose-body':       'rgba(255,255,255,0.70)',
            '--tw-prose-headings':   'rgba(255,255,255,0.95)',
            '--tw-prose-lead':       'rgba(255,255,255,0.70)',
            '--tw-prose-links':      '#A259FF',
            '--tw-prose-bold':       'rgba(255,255,255,0.95)',
            '--tw-prose-counters':   'rgba(255,255,255,0.40)',
            '--tw-prose-bullets':    'rgba(255,255,255,0.20)',
            '--tw-prose-hr':         'rgba(255,255,255,0.08)',
            '--tw-prose-quotes':     'rgba(255,255,255,0.90)',
            '--tw-prose-quote-borders': '#A259FF',
            '--tw-prose-captions':   'rgba(255,255,255,0.40)',
            '--tw-prose-code':       '#A259FF',
            '--tw-prose-pre-code':   'rgba(255,255,255,0.80)',
            '--tw-prose-pre-bg':     '#0d0d0d',
            '--tw-prose-th-borders': 'rgba(255,255,255,0.10)',
            '--tw-prose-td-borders': 'rgba(255,255,255,0.06)',
          },
        },
      }),
    },
  },
  plugins: [],
};
