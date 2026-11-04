import type { Metadata } from "next";
import { Inter, Playfair_Display } from "next/font/google";
import Script from "next/script";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-inter",
});

const playfair = Playfair_Display({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-playfair",
});

export const metadata: Metadata = {
  title: "Factline | Intelligence Archive",
  description:
    "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
  metadataBase: new URL("https://factline.one"),
  openGraph: {
    type: "website",
    url: "https://factline.one",
    title: "Factline | Intelligence Archive",
    description:
      "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
    images: [{ url: "/default-og.jpg" }],
  },
  alternates: {
    canonical: "https://factline.one",
  },
  twitter: {
    card: "summary_large_image",
    title: "Factline | Intelligence Archive",
    description:
      "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
    images: ["/default-og.jpg"],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`dark ${inter.variable} ${playfair.variable}`}>
      <body className="min-h-screen overflow-x-hidden antialiased">
        {children}
        <Script
          src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"
          strategy="afterInteractive"
        />
        <Script id="google-translate-init" strategy="afterInteractive">
          {`
            function googleTranslateElementInit() {
              if (window.google && window.google.translate) {
                new window.google.translate.TranslateElement({
                  pageLanguage: 'en',
                  layout: window.google.translate.TranslateElement.InlineLayout.SIMPLE,
                  autoDisplay: false
                }, 'google_translate_element');
              }
            }
          `}
        </Script>
      </body>
    </html>
  );
}
