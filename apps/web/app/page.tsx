import { Metadata } from 'next';
import { getArticle, getArticleMetadata } from '@/lib/mdx';
import Article from '@/components/Article';
import StructuredData from '@/components/StructuredData';
import PerformanceOptimizer from '@/components/PerformanceOptimizer';

export async function generateMetadata(): Promise<Metadata> {
  const { frontmatter, metadata } = await getArticleMetadata();
  
  return {
    title: {
      default: frontmatter.title,
      template: '%s | Robbed by AppleCare',
    },
    description: frontmatter.tldr,
    keywords: frontmatter.tags.join(', '),
    authors: [{ name: frontmatter.authorDisplay }],
    creator: frontmatter.authorDisplay,
    publisher: 'Robbed by AppleCare',
    category: 'Customer Service',
    classification: 'Article',
    openGraph: {
      title: frontmatter.title,
      description: frontmatter.tldr,
      url: frontmatter.canonicalUrl,
      siteName: 'Robbed by AppleCare',
      images: [
        {
          url: '/opengraph-image',
          width: 1200,
          height: 630,
          alt: frontmatter.title,
          type: 'image/png',
        },
      ],
      locale: 'en_US',
      type: 'article',
      publishedTime: frontmatter.publishedAt,
      modifiedTime: metadata.lastModified,
      authors: [frontmatter.authorDisplay],
      tags: frontmatter.tags,
      section: 'Customer Service',
    },
    twitter: {
      card: 'summary_large_image',
      title: frontmatter.title,
      description: frontmatter.tldr,
      images: ['/opengraph-image'],
      creator: '@robbedbyapplecare',
      site: '@robbedbyapplecare',
    },
    alternates: {
      canonical: frontmatter.canonicalUrl,
    },
    robots: {
      index: true,
      follow: true,
      googleBot: {
        index: true,
        follow: true,
        'max-video-preview': -1,
        'max-image-preview': 'large',
        'max-snippet': -1,
      },
    },
    verification: {
      google: 'your-google-verification-code',
      yandex: 'your-yandex-verification-code',
      yahoo: 'your-yahoo-verification-code',
    },
    other: {
      'article:author': frontmatter.authorDisplay,
      'article:published_time': frontmatter.publishedAt,
      'article:modified_time': metadata.lastModified,
      'article:section': 'Customer Service',
      'article:tag': frontmatter.tags.join(','),
    },
  };
}

export default async function HomePage() {
  const article = await getArticle();

  return (
    <>
      <StructuredData article={article} />
      <PerformanceOptimizer />
      <main>
        <Article article={article} />
      </main>
    </>
  );
}