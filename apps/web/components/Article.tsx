import { MDXRemote } from 'next-mdx-remote/rsc';
import { ProcessedArticle } from '@/types/article';
import { mdxComponents } from './mdx/MDXComponents';
import EvidenceGallery from './EvidenceGallery';
import BackToTop from './BackToTop';
import SocialShare from './SocialShare';
import DiscourseEmbed from './DiscourseEmbed';
import { Badge, ThemeToggle } from './ui';

interface ArticleProps {
  article: ProcessedArticle;
}

// Extract headings from content for navigation
function extractHeadings(content: string) {
  const headingRegex = /^(#{1,6})\s+(.+)$/gm;
  const headings = [];
  let match;
  
  while ((match = headingRegex.exec(content)) !== null) {
    const level = match[1].length;
    const text = match[2].trim();
    const id = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    
    headings.push({ level, text, id });
  }
  
  return headings;
}

export default function Article({ article }: ArticleProps) {
  const { frontmatter, content, metadata } = article;
  const headings = extractHeadings(content);

  return (
    <div className="min-h-screen bg-white dark:bg-gray-900">
      {/* Navigation */}
      {headings.length > 0 && (
        <nav className="fixed top-0 left-0 right-0 z-50 bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm border-b border-gray-200 dark:border-gray-700">
          <div className="max-w-4xl mx-auto px-4 py-3">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                {frontmatter.title}
              </div>
              <div className="flex items-center space-x-4">
                <div className="hidden md:flex items-center space-x-4 text-sm">
                  {headings.slice(0, 3).map((heading) => (
                    <a
                      key={heading.id}
                      href={`#${heading.id}`}
                      className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
                    >
                      {heading.text}
                    </a>
                  ))}
                </div>
                <ThemeToggle />
              </div>
            </div>
          </div>
        </nav>
      )}

      <article className="max-w-4xl mx-auto px-4 py-8 pt-20">
        {/* Article Header */}
        <header className="mb-12 text-center">
          <h1 
            id="title"
            className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900 dark:text-gray-100 mb-4 leading-tight"
          >
            {frontmatter.title}
          </h1>
          <p className="text-lg sm:text-xl text-gray-600 dark:text-gray-400 mb-6 leading-relaxed max-w-3xl mx-auto">
            {frontmatter.subtitle}
          </p>
          
          {/* Article Meta */}
          <div className="flex flex-wrap justify-center items-center gap-2 sm:gap-4 text-sm text-gray-500 dark:text-gray-400 mb-8">
            <span>By {frontmatter.authorDisplay}</span>
            <span className="hidden sm:inline">•</span>
            <time dateTime={frontmatter.publishedAt}>
              {new Date(frontmatter.publishedAt).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </time>
            <span className="hidden sm:inline">•</span>
            <span>{metadata.readingTime} min read</span>
            <span className="hidden sm:inline">•</span>
            <span>{metadata.wordCount.toLocaleString()} words</span>
          </div>

          {/* Tags */}
          <div className="flex flex-wrap justify-center gap-2 mb-8">
            {frontmatter.tags.map((tag) => (
              <Badge key={tag} variant="primary">
                {tag}
              </Badge>
            ))}
          </div>

          {/* Hero Image */}
          {frontmatter.heroImage && (
            <div className="mb-8">
              <img
                src={frontmatter.heroImage}
                alt={frontmatter.title}
                className="w-full h-48 sm:h-64 md:h-96 object-cover rounded-lg shadow-lg"
              />
            </div>
          )}
        </header>

        {/* TL;DR Section */}
        <section id="tldr" className="mb-12">
          <div className="callout callout-warning">
            <h2 className="text-lg font-semibold text-yellow-800 dark:text-yellow-200 mb-2">
              <a href="#tldr" className="hover:underline">TL;DR</a>
            </h2>
            <p className="text-yellow-700 dark:text-yellow-300 leading-relaxed">{frontmatter.tldr}</p>
          </div>
        </section>

        {/* Article Content */}
        <section id="content" className="mb-12">
          <div className="prose prose-lg dark:prose-invert max-w-none prose-headings:scroll-mt-20">
            <MDXRemote 
              source={content} 
              components={{
                ...mdxComponents,
                h1: ({ children, ...props }) => (
                  <h1 
                    id={children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}
                    className="scroll-mt-20"
                    {...props}
                  >
                    <a 
                      href={`#${children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`}
                      className="hover:underline"
                    >
                      {children}
                    </a>
                  </h1>
                ),
                h2: ({ children, ...props }) => (
                  <h2 
                    id={children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}
                    className="scroll-mt-20"
                    {...props}
                  >
                    <a 
                      href={`#${children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`}
                      className="hover:underline"
                    >
                      {children}
                    </a>
                  </h2>
                ),
                h3: ({ children, ...props }) => (
                  <h3 
                    id={children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}
                    className="scroll-mt-20"
                    {...props}
                  >
                    <a 
                      href={`#${children?.toString().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`}
                      className="hover:underline"
                    >
                      {children}
                    </a>
                  </h3>
                ),
              }}
            />
          </div>
        </section>

        {/* Evidence Gallery */}
        {frontmatter.evidence && frontmatter.evidence.length > 0 && (
          <EvidenceGallery evidence={frontmatter.evidence} />
        )}



        {/* Discourse Comments */}
        <DiscourseEmbed 
          discourseUrl="https://forum.robbedbyapplecare.com"
          className="mt-12"
        />

        {/* Article Footer */}
        <footer className="mt-12 pt-8 border-t border-gray-200 dark:border-gray-700">
          <div className="text-center text-gray-500 dark:text-gray-400 text-sm">
            <p>Last updated: {new Date(metadata.lastModified).toLocaleDateString()}</p>
            <div className="mt-6">
              <SocialShare 
                url={frontmatter.canonicalUrl}
                title={frontmatter.title}
              />
            </div>
          </div>
        </footer>
      </article>

      {/* Back to top button */}
      <BackToTop />
    </div>
  );
}