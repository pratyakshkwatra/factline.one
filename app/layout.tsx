import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Factline | Intelligence Archive',
  description: "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
  metadataBase: new URL('https://factline.one'),
  openGraph: {
    type: 'website',
    url: 'https://factline.one',
    title: 'Factline | Intelligence Archive',
    description: "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
    images: [{ url: '/default-og.jpg' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Factline | Intelligence Archive',
    description: "Immutable, evidence-backed intelligence reports. We go down the rabbit hole so you don't have to.",
    images: ['/default-og.jpg'],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen overflow-x-hidden antialiased grain-overlay">
        {children}
      </body>
    </html>
  );
}
