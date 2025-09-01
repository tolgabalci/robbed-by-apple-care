import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import { ArticleFrontmatter, ProcessedArticle } from '@/types/article';

const contentDirectory = path.join(process.cwd(), 'content');

/**
 * Calculate reading time based on average reading speed of 200 words per minute
 */
function calculateReadingTime(content: string): number {
  const wordsPerMinute = 200;
  const wordCount = content.trim().split(/\s+/).length;
  const readingTime = Math.ceil(wordCount / wordsPerMinute);
  return readingTime;
}

/**
 * Count words in content (excluding frontmatter)
 */
function countWords(content: string): number {
  return content.trim().split(/\s+/).length;
}

/**
 * Get file modification time
 */
function getLastModified(filePath: string): string {
  try {
    const stats = fs.statSync(filePath);
    return stats.mtime.toISOString();
  } catch (error) {
    return new Date().toISOString();
  }
}

/**
 * Load and process the main article
 */
export async function getArticle(): Promise<ProcessedArticle> {
  const articlePath = path.join(contentDirectory, 'article.mdx');
  
  if (!fs.existsSync(articlePath)) {
    throw new Error('Article file not found at content/article.mdx');
  }

  const fileContents = fs.readFileSync(articlePath, 'utf8');
  const { data, content } = matter(fileContents);

  // Validate frontmatter structure
  const frontmatter = validateFrontmatter(data);

  // Calculate metadata
  const wordCount = countWords(content);
  const readingTime = calculateReadingTime(content);
  const lastModified = getLastModified(articlePath);

  return {
    frontmatter,
    content,
    metadata: {
      wordCount,
      readingTime,
      lastModified,
    },
  };
}

/**
 * Validate and type-check frontmatter data
 */
function validateFrontmatter(data: any): ArticleFrontmatter {
  const required = [
    'title',
    'subtitle', 
    'authorDisplay',
    'publishedAt',
    'tldr',
    'tags',
    'heroImage',
    'ogImage',
    'canonicalUrl',
    'evidence'
  ];

  for (const field of required) {
    if (!(field in data)) {
      throw new Error(`Missing required frontmatter field: ${field}`);
    }
  }

  // Validate evidence array structure
  if (!Array.isArray(data.evidence)) {
    throw new Error('Evidence must be an array');
  }

  for (const [index, item] of data.evidence.entries()) {
    if (!item.src || !item.type || !item.caption) {
      throw new Error(`Evidence item ${index} missing required fields (src, type, caption)`);
    }
    if (!['image', 'pdf'].includes(item.type)) {
      throw new Error(`Evidence item ${index} has invalid type: ${item.type}`);
    }
  }

  // Validate tags array
  if (!Array.isArray(data.tags)) {
    throw new Error('Tags must be an array');
  }

  return data as ArticleFrontmatter;
}

/**
 * Get article metadata only (useful for SEO and previews)
 */
export async function getArticleMetadata(): Promise<{
  frontmatter: ArticleFrontmatter;
  metadata: ProcessedArticle['metadata'];
}> {
  const article = await getArticle();
  return {
    frontmatter: article.frontmatter,
    metadata: article.metadata,
  };
}