"use client";

import { Globe } from "lucide-react";
import { GOOGLE_LANGUAGES } from "../lib/languages";

export function LanguageSelector() {
  const handleLanguageChange = (langValue: string) => {
    // 1. Force the cookie approach for maximum reliability
    document.cookie = `googtrans=/en/${langValue}; path=/;`;
    document.cookie = `googtrans=/en/${langValue}; domain=${window.location.hostname}; path=/;`;

    // 2. Try the DOM dispatch approach just in case it's loaded without reload
    const select = document.querySelector(
      ".goog-te-combo",
    ) as HTMLSelectElement;
    if (select) {
      if (!Array.from(select.options).some((opt) => opt.value === langValue)) {
        const newOption = document.createElement("option");
        newOption.value = langValue;
        select.appendChild(newOption);
      }
      select.value = langValue;
      select.dispatchEvent(new Event("change", { bubbles: true }));
    } else {
      // If the DOM element isn't there, reload to force cookie usage
      window.location.reload();
    }
  };

  return (
    <div className="relative flex items-center group cursor-pointer w-8 h-8 justify-center rounded-full hover:bg-zinc-800 transition-colors">
      <Globe className="w-4 h-4 text-zinc-400 group-hover:text-zinc-100 transition-colors pointer-events-none" />
      <select
        onChange={(e) => handleLanguageChange(e.target.value)}
        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
        defaultValue="en"
        title="Select Language"
      >
        {GOOGLE_LANGUAGES.map((lang) => (
          <option key={lang.value} value={lang.value}>
            {lang.label}
          </option>
        ))}
      </select>
    </div>
  );
}
