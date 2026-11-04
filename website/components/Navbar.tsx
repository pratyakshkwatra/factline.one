"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { LanguageSelector } from "./LanguageSelector";

export function Navbar() {
  const pathname = usePathname();

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-zinc-950/90 backdrop-blur-md border-b border-zinc-800 flex items-center px-6 sm:px-8 h-16 sm:h-20">
      <Link href="/" className="flex items-center gap-3 group">
        <Image
          src="/assets/logo.png"
          alt="Factline Logo"
          width={150}
          height={32}
          priority
          className="h-6 sm:h-8 w-auto group-hover:opacity-80 transition-opacity"
          style={{ width: 'auto' }}
        />
      </Link>
      <div className="ml-auto flex items-center gap-6">
        <Link
          href="/archive"
          className={`text-sm font-bold uppercase tracking-widest transition-colors ${
            pathname === "/archive"
              ? "text-zinc-100"
              : "text-zinc-400 hover:text-zinc-100"
          }`}
        >
          Archive
        </Link>
        <Link
          href="/ai-process"
          className={`text-sm font-bold uppercase tracking-widest hidden sm:block transition-colors ${
            pathname === "/ai-process"
              ? "text-zinc-100"
              : "text-zinc-400 hover:text-zinc-100"
          }`}
        >
          About
        </Link>
        
        {/* Custom Language Selector */}
        <LanguageSelector />

        {/* Hidden Google Translate Element */}
        <div id="google_translate_element" className="hidden-translate hidden" />
      </div>
    </nav>
  );
}
