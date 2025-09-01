/**
 * Critical CSS utilities for performance optimization
 * Extracts and inlines critical CSS for above-the-fold content
 */

/**
 * Critical CSS for above-the-fold content
 * This should include only the styles needed for the initial viewport
 */
export const CRITICAL_CSS = `
/* Critical Base Styles */
html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.6;
  color: #111827;
  background-color: #ffffff;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  body {
    color: #f9fafb;
    background-color: #111827;
  }
}

/* Critical Layout */
.min-h-screen {
  min-height: 100vh;
}

.container-prose {
  max-width: 56rem;
  margin-left: auto;
  margin-right: auto;
  padding-left: 1rem;
  padding-right: 1rem;
}

/* Critical Typography */
h1 {
  font-size: 2.25rem;
  font-weight: 800;
  line-height: 1.2;
  margin-bottom: 1rem;
}

h2 {
  font-size: 1.875rem;
  font-weight: 700;
  line-height: 1.3;
  margin-top: 2rem;
  margin-bottom: 1rem;
}

p {
  margin-bottom: 1rem;
}

/* Critical Button Styles */
.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1rem;
  background-color: #2563eb;
  color: white;
  border-radius: 0.375rem;
  font-weight: 500;
  text-decoration: none;
  transition: background-color 0.2s;
}

.btn-primary:hover {
  background-color: #1d4ed8;
}

/* Critical Loading States */
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: .5;
  }
}

/* Critical Responsive */
@media (max-width: 640px) {
  .container-prose {
    padding-left: 0.75rem;
    padding-right: 0.75rem;
  }
  
  h1 {
    font-size: 1.875rem;
  }
  
  h2 {
    font-size: 1.5rem;
  }
}
`;

/**
 * Generates critical CSS based on the current page content
 * In a real implementation, this would analyze the DOM and extract only used styles
 */
export function generateCriticalCSS(content?: string): string {
  // For now, return the static critical CSS
  // In production, you might use tools like:
  // - critical (npm package)
  // - puppeteer to analyze rendered page
  // - postcss plugins
  
  return CRITICAL_CSS;
}

/**
 * Inlines critical CSS in the document head
 * Should be called during SSR or build time
 */
export function inlineCriticalCSS(): string {
  return `<style id="critical-css">${CRITICAL_CSS}</style>`;
}

/**
 * Loads non-critical CSS asynchronously
 */
export function loadNonCriticalCSS(href: string): void {
  if (typeof window === 'undefined') return;
  
  const link = document.createElement('link');
  link.rel = 'preload';
  link.as = 'style';
  link.href = href;
  link.onload = () => {
    link.onload = null;
    link.rel = 'stylesheet';
  };
  
  document.head.appendChild(link);
  
  // Fallback for browsers that don't support preload
  const noscript = document.createElement('noscript');
  const fallbackLink = document.createElement('link');
  fallbackLink.rel = 'stylesheet';
  fallbackLink.href = href;
  noscript.appendChild(fallbackLink);
  document.head.appendChild(noscript);
}

/**
 * Preloads important resources
 */
export function preloadResources(): void {
  if (typeof window === 'undefined') return;
  
  // Preload fonts
  const fontPreload = document.createElement('link');
  fontPreload.rel = 'preload';
  fontPreload.as = 'font';
  fontPreload.type = 'font/woff2';
  fontPreload.href = 'https://fonts.gstatic.com/s/inter/v12/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiA.woff2';
  fontPreload.crossOrigin = 'anonymous';
  document.head.appendChild(fontPreload);
  
  // Preload critical images (hero image, first evidence items)
  const heroImagePreload = document.createElement('link');
  heroImagePreload.rel = 'preload';
  heroImagePreload.as = 'image';
  heroImagePreload.href = '/evidence/email-1.svg'; // Replace with actual hero image
  document.head.appendChild(heroImagePreload);
}

/**
 * Performance optimization utilities
 */
export const PerformanceUtils = {
  /**
   * Defer non-critical JavaScript
   */
  deferScript(src: string, callback?: () => void): void {
    if (typeof window === 'undefined') return;
    
    const script = document.createElement('script');
    script.src = src;
    script.defer = true;
    if (callback) {
      script.onload = callback;
    }
    document.head.appendChild(script);
  },

  /**
   * Lazy load images with Intersection Observer
   */
  lazyLoadImages(selector: string = 'img[data-src]'): void {
    if (typeof window === 'undefined' || !('IntersectionObserver' in window)) return;
    
    const images = document.querySelectorAll(selector);
    const imageObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const img = entry.target as HTMLImageElement;
          const src = img.dataset.src;
          if (src) {
            img.src = src;
            img.removeAttribute('data-src');
            imageObserver.unobserve(img);
          }
        }
      });
    });
    
    images.forEach((img) => imageObserver.observe(img));
  },

  /**
   * Prefetch next page resources
   */
  prefetchNextPage(href: string): void {
    if (typeof window === 'undefined') return;
    
    const link = document.createElement('link');
    link.rel = 'prefetch';
    link.href = href;
    document.head.appendChild(link);
  }
};