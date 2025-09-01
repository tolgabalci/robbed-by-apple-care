export interface EvidenceItem {
  src: string;
  type: 'image' | 'pdf';
  caption: string;
  alt?: string;
}

export interface ArticleFrontmatter {
  title: string;
  subtitle: string;
  authorDisplay: string;
  publishedAt: string;
  tldr: string;
  tags: string[];
  heroImage: string;
  ogImage: string;
  canonicalUrl: string;
  evidence: EvidenceItem[];
}

export interface ProcessedArticle {
  frontmatter: ArticleFrontmatter;
  content: string;
  metadata: {
    wordCount: number;
    readingTime: number;
    lastModified: string;
  };
}

export interface ProcessedEvidence {
  original: string;
  webp: {
    '320': string;
    '640': string;
    '1280': string;
  };
  dimensions: {
    width: number;
    height: number;
  };
  fileSize: number;
  caption: string;
  type: 'image' | 'pdf';
  alt?: string;
}