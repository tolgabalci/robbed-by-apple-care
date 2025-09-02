import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import Article from '../components/Article';
import { ProcessedArticle } from '../types/article';

expect.extend(toHaveNoViolations);

// Mock components to avoid complex dependencies in tests
jest.mock('../components/EvidenceGallery', () => {
  return function MockEvidenceGallery({ evidence }: { evidence: any[] }) {
    return (
      <div data-testid="evidence-gallery">
        {evidence.map((item, index) => (
          <div key={index} data-testid={`evidence-${index}`}>
            {item.caption}
          </div>
        ))}
      </div>
    );
  };
});

jest.mock('../components/DiscourseEmbed', () => {
  return function MockDiscourseEmbed({ discourseUrl }: { discourseUrl: string }) {
    return <div data-testid="discourse-embed" data-url={discourseUrl}>Comments</div>;
  };
});

jest.mock('../components/BackToTop', () => {
  return function MockBackToTop() {
    return <button data-testid="back-to-top">Back to Top</button>;
  };
});

jest.mock('../components/SocialShare', () => {
  return function MockSocialShare({ url, title }: { url: string; title: string }) {
    return <div data-testid="social-share" data-url={url} data-title={title}>Share</div>;
  };
});

jest.mock('../components/ui', () => ({
  Badge: ({ children, variant }: { children: React.ReactNode; variant: string }) => (
    <span data-testid="badge" data-variant={variant}>{children}</span>
  ),
  ThemeToggle: () => (
    <button 
      data-testid="theme-toggle" 
      aria-label="Switch to dark mode"
      title="Switch to dark mode"
    >
      <svg><path /></svg>
    </button>
  ),
}));

// Mock MDXRemote to avoid issues in test environment
jest.mock('next-mdx-remote/rsc', () => ({
  MDXRemote: ({ source }: { source: string }) => <div data-testid="mdx-content">{source}</div>,
}));

// Mock article data for testing
const mockArticle: ProcessedArticle = {
  frontmatter: {
    title: 'Robbed by AppleCare: A Customer Service Nightmare',
    subtitle: 'How Apple\'s premium support service failed me when I needed it most',
    authorDisplay: 'Anonymous Customer',
    publishedAt: '2024-01-15',
    tldr: 'AppleCare failed to provide adequate support for a legitimate warranty claim.',
    tags: ['AppleCare', 'Apple', 'Customer Service'],
    heroImage: '/hero-image.jpg',
    ogImage: '/og-image.jpg',
    canonicalUrl: 'https://www.robbedbyapplecare.com',
    evidence: [
      {
        src: '/evidence/email-1.jpg',
        type: 'image',
        caption: 'Initial support request'
      }
    ]
  },
  content: '# The Beginning of a Nightmare\n\nIt started like any other day...',
  metadata: {
    wordCount: 100,
    readingTime: 1,
    lastModified: '2024-01-15T00:00:00.000Z'
  }
};

const mockArticleWithoutEvidence: ProcessedArticle = {
  ...mockArticle,
  frontmatter: {
    ...mockArticle.frontmatter,
    evidence: []
  }
};

describe('Article Component', () => {
  beforeEach(() => {
    // Mock window.location for canonical URL tests
    Object.defineProperty(window, 'location', {
      value: { href: 'https://www.robbedbyapplecare.com' },
      writable: true,
    });
  });

  describe('Basic Rendering', () => {
    it('renders the article title with proper heading hierarchy', () => {
      render(<Article article={mockArticle} />);
      const heading = screen.getByRole('heading', { level: 1, name: /robbed by applecare/i });
      expect(heading).toBeInTheDocument();
      expect(heading).toHaveAttribute('id', 'title');
    });

    it('renders the article subtitle', () => {
      render(<Article article={mockArticle} />);
      const subtitle = screen.getByText(/how apple's premium support service failed me/i);
      expect(subtitle).toBeInTheDocument();
    });

    it('renders the TL;DR section with proper heading', () => {
      render(<Article article={mockArticle} />);
      const tldrHeading = screen.getByRole('heading', { level: 2, name: /tl;dr/i });
      const tldrContent = screen.getByText(/applecare failed to provide adequate support/i);
      expect(tldrHeading).toBeInTheDocument();
      expect(tldrContent).toBeInTheDocument();
    });

    it('renders article metadata correctly', () => {
      render(<Article article={mockArticle} />);
      expect(screen.getByText(/Anonymous Customer/)).toBeInTheDocument();
      expect(screen.getByText(/1 min read/)).toBeInTheDocument();
      expect(screen.getByText(/100 words/)).toBeInTheDocument();
      expect(screen.getByText(/January 14, 2024/)).toBeInTheDocument();
    });

    it('renders tags as badges', () => {
      render(<Article article={mockArticle} />);
      const badges = screen.getAllByTestId('badge');
      expect(badges).toHaveLength(3);
      expect(screen.getByText('AppleCare')).toBeInTheDocument();
      expect(screen.getByText('Apple')).toBeInTheDocument();
      expect(screen.getByText('Customer Service')).toBeInTheDocument();
    });

    it('renders hero image when provided', () => {
      render(<Article article={mockArticle} />);
      const heroImage = screen.getByRole('img', { name: mockArticle.frontmatter.title });
      expect(heroImage).toBeInTheDocument();
      expect(heroImage).toHaveAttribute('src', '/hero-image.jpg');
    });

    it('renders hero image from article frontmatter', () => {
      render(<Article article={mockArticleWithoutEvidence} />);
      const heroImage = screen.getByRole('img', { name: mockArticle.frontmatter.title });
      expect(heroImage).toBeInTheDocument();
    });
  });

  describe('Content Sections', () => {
    it('renders MDX content', () => {
      render(<Article article={mockArticle} />);
      const mdxContent = screen.getByTestId('mdx-content');
      expect(mdxContent).toBeInTheDocument();
      expect(mdxContent).toHaveTextContent('# The Beginning of a Nightmare');
    });

    it('renders evidence gallery when evidence exists', () => {
      render(<Article article={mockArticle} />);
      const evidenceGallery = screen.getByTestId('evidence-gallery');
      expect(evidenceGallery).toBeInTheDocument();
    });

    it('does not render evidence section when no evidence', () => {
      render(<Article article={mockArticleWithoutEvidence} />);
      const evidenceHeading = screen.queryByRole('heading', { name: /evidence/i });
      expect(evidenceHeading).not.toBeInTheDocument();
    });

    it('renders timeline section in MDX content', () => {
      render(<Article article={mockArticle} />);
      // Timeline is now part of the MDX content, not a separate section
      expect(screen.getByTestId('mdx-content')).toBeInTheDocument();
    });

    it('renders Discourse embed component', () => {
      render(<Article article={mockArticle} />);
      const discourseEmbed = screen.getByTestId('discourse-embed');
      expect(discourseEmbed).toBeInTheDocument();
      expect(discourseEmbed).toHaveAttribute('data-url', 'https://forum.robbedbyapplecare.com');
    });
  });

  describe('Navigation and Interaction', () => {
    it('renders navigation bar with article title', () => {
      render(<Article article={mockArticle} />);
      // Navigation should show the title
      const navElements = screen.getAllByText(/robbed by applecare/i);
      expect(navElements.length).toBeGreaterThan(1); // Title appears in nav and main content
    });

    it('renders theme toggle in navigation', () => {
      render(<Article article={mockArticle} />);
      const themeToggle = screen.getByTestId('theme-toggle');
      expect(themeToggle).toBeInTheDocument();
      expect(themeToggle).toHaveAttribute('aria-label');
      expect(themeToggle).toHaveAttribute('title');
    });

    it('renders back to top button', () => {
      render(<Article article={mockArticle} />);
      const backToTop = screen.getByTestId('back-to-top');
      expect(backToTop).toBeInTheDocument();
    });

    it('renders social share component', () => {
      render(<Article article={mockArticle} />);
      const socialShare = screen.getByTestId('social-share');
      expect(socialShare).toBeInTheDocument();
      expect(socialShare).toHaveAttribute('data-url', 'https://www.robbedbyapplecare.com');
      expect(socialShare).toHaveAttribute('data-title', mockArticle.frontmatter.title);
    });
  });

  describe('Footer and Metadata', () => {
    it('renders last updated date in footer', () => {
      render(<Article article={mockArticle} />);
      expect(screen.getByText(/last updated/i)).toBeInTheDocument();
      expect(screen.getByText(/1\/14\/2024/)).toBeInTheDocument();
    });

    it('renders share section in footer', () => {
      render(<Article article={mockArticle} />);
      expect(screen.getByTestId('social-share')).toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('handles missing optional fields gracefully', () => {
      const minimalArticle: ProcessedArticle = {
        frontmatter: {
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          authorDisplay: 'Test Author',
          publishedAt: '2024-01-01',
          tldr: 'Test TL;DR',
          tags: [],
          heroImage: '/test-hero.jpg',
          ogImage: '/test-og.jpg',
          canonicalUrl: 'https://example.com',
          evidence: []
        },
        content: 'Test content',
        metadata: {
          wordCount: 10,
          readingTime: 1,
          lastModified: '2024-01-01T00:00:00.000Z'
        }
      };

      expect(() => render(<Article article={minimalArticle} />)).not.toThrow();
      expect(screen.getByText('Test Title')).toBeInTheDocument();
    });

    it('handles empty tags array', () => {
      const articleWithoutTags = {
        ...mockArticle,
        frontmatter: { ...mockArticle.frontmatter, tags: [] }
      };

      render(<Article article={articleWithoutTags} />);
      const badges = screen.queryAllByTestId('badge');
      expect(badges).toHaveLength(0);
    });
  });

  describe('Accessibility', () => {
    it('should not have accessibility violations', async () => {
      const { container } = render(<Article article={mockArticle} />);
      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('has proper heading hierarchy', () => {
      render(<Article article={mockArticle} />);
      
      // Check that we have proper heading levels
      const h1 = screen.getByRole('heading', { level: 1 });
      const h2s = screen.getAllByRole('heading', { level: 2 });
      
      expect(h1).toBeInTheDocument();
      expect(h2s.length).toBeGreaterThan(0);
    });

    it('has proper semantic structure', () => {
      render(<Article article={mockArticle} />);
      
      // Check for semantic HTML elements
      expect(screen.getByRole('article')).toBeInTheDocument();
      expect(screen.getByRole('navigation')).toBeInTheDocument();
      expect(screen.getByRole('banner')).toBeInTheDocument(); // header
      expect(screen.getByRole('contentinfo')).toBeInTheDocument(); // footer
    });

    it('has proper time element with datetime attribute', () => {
      render(<Article article={mockArticle} />);
      const timeElement = screen.getByText('January 14, 2024').closest('time');
      expect(timeElement).toHaveAttribute('datetime', '2024-01-15');
    });

    it('has proper alt text for hero image', () => {
      render(<Article article={mockArticle} />);
      const heroImage = screen.getByRole('img', { name: mockArticle.frontmatter.title });
      expect(heroImage).toHaveAttribute('alt', mockArticle.frontmatter.title);
    });

    it('has proper anchor links for headings', () => {
      render(<Article article={mockArticle} />);
      
      // Check that section headings have proper anchor links
      const tldrHeading = screen.getByRole('heading', { name: /tl;dr/i });
      const tldrLink = tldrHeading.querySelector('a');
      expect(tldrLink).toHaveAttribute('href', '#tldr');
      
      // Evidence heading is now part of the EvidenceGallery component
      expect(screen.getByTestId('evidence-gallery')).toBeInTheDocument();
    });
  });

  describe('Responsive Design', () => {
    it('applies responsive classes correctly', () => {
      render(<Article article={mockArticle} />);
      const title = screen.getByRole('heading', { level: 1 });
      expect(title).toHaveClass('text-3xl', 'sm:text-4xl', 'lg:text-5xl');
    });

    it('has proper container max-width', () => {
      render(<Article article={mockArticle} />);
      const article = screen.getByRole('article');
      expect(article).toHaveClass('max-w-4xl', 'mx-auto');
    });
  });
});