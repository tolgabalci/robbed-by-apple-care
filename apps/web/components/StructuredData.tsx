import { ProcessedArticle } from '@/types/article';

interface StructuredDataProps {
  article: ProcessedArticle;
}

export default function StructuredData({ article }: StructuredDataProps) {
  const { frontmatter, metadata } = article;
  
  const structuredData = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: frontmatter.title,
    description: frontmatter.tldr,
    author: {
      '@type': 'Person',
      name: frontmatter.authorDisplay,
    },
    publisher: {
      '@type': 'Organization',
      name: 'Robbed by AppleCare',
      url: 'https://www.robbedbyapplecare.com',
      logo: {
        '@type': 'ImageObject',
        url: 'https://www.robbedbyapplecare.com/logo.png',
      },
    },
    datePublished: frontmatter.publishedAt,
    dateModified: metadata.lastModified,
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': frontmatter.canonicalUrl,
    },
    image: {
      '@type': 'ImageObject',
      url: frontmatter.ogImage,
      width: 1200,
      height: 630,
    },
    url: frontmatter.canonicalUrl,
    wordCount: metadata.wordCount,
    keywords: frontmatter.tags.join(', '),
    articleSection: 'Customer Service',
    about: {
      '@type': 'Thing',
      name: 'AppleCare Customer Service',
    },
    mentions: [
      {
        '@type': 'Organization',
        name: 'Apple Inc.',
      },
      {
        '@type': 'Product',
        name: 'AppleCare+',
      },
    ],
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(structuredData),
      }}
    />
  );
}