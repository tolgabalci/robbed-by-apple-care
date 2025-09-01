import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import PerformanceMonitor from '@/components/PerformanceMonitor';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Robbed by AppleCare - A Customer Service Nightmare',
  description: 'A detailed account of AppleCare\'s failure to provide adequate customer service and support.',
  keywords: ['AppleCare', 'Apple', 'customer service', 'complaint', 'support'],
  authors: [{ name: 'Anonymous Customer' }],
  openGraph: {
    title: 'Robbed by AppleCare - A Customer Service Nightmare',
    description: 'A detailed account of AppleCare\'s failure to provide adequate customer service and support.',
    url: 'https://www.robbedbyapplecare.com',
    siteName: 'Robbed by AppleCare',
    type: 'article',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'Robbed by AppleCare',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Robbed by AppleCare - A Customer Service Nightmare',
    description: 'A detailed account of AppleCare\'s failure to provide adequate customer service and support.',
    images: ['/og-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: {
    canonical: 'https://www.robbedbyapplecare.com',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="canonical" href="https://www.robbedbyapplecare.com" />
        {/* Discourse prefetch for better performance */}
        <link rel="dns-prefetch" href="//forum.robbedbyapplecare.com" />
        <link rel="preconnect" href="https://forum.robbedbyapplecare.com" crossOrigin="anonymous" />
      </head>
      <body className={inter.className}>
        <PerformanceMonitor />
        <div className="min-h-screen bg-white dark:bg-gray-900">
          {children}
        </div>
      </body>
    </html>
  );
}