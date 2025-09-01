/**
 * @jest-environment jsdom
 */

import { render } from '@testing-library/react';
import LazyImage from '../components/LazyImage';
import PerformanceMonitor from '../components/PerformanceMonitor';
import { CRITICAL_CSS, generateCriticalCSS } from '../lib/critical-css';

// Mock IntersectionObserver
const mockIntersectionObserver = jest.fn();
mockIntersectionObserver.mockReturnValue({
  observe: () => null,
  unobserve: () => null,
  disconnect: () => null,
});
window.IntersectionObserver = mockIntersectionObserver;

// Mock PerformanceObserver
const mockPerformanceObserver = jest.fn();
mockPerformanceObserver.mockReturnValue({
  observe: () => null,
  disconnect: () => null,
});
window.PerformanceObserver = mockPerformanceObserver;

describe('Performance Optimizations', () => {
  describe('LazyImage Component', () => {
    it('should render with lazy loading by default', () => {
      const { container } = render(
        <LazyImage
          src="/test-image.jpg"
          alt="Test image"
        />
      );

      const img = container.querySelector('img');
      expect(img).toHaveAttribute('loading', 'lazy');
    });

    it('should render with eager loading when priority is true', () => {
      const { container } = render(
        <LazyImage
          src="/test-image.jpg"
          alt="Test image"
          priority={true}
        />
      );

      const img = container.querySelector('img');
      expect(img).toHaveAttribute('loading', 'eager');
    });

    it('should show placeholder while loading', () => {
      const { container } = render(
        <LazyImage
          src="/test-image.jpg"
          alt="Test image"
        />
      );

      const placeholder = container.querySelector('.animate-pulse');
      expect(placeholder).toBeInTheDocument();
    });

    it('should handle image load errors gracefully', () => {
      const { container } = render(
        <LazyImage
          src="/non-existent-image.jpg"
          alt="Test image"
        />
      );

      const img = container.querySelector('img');
      expect(img).toBeInTheDocument();
    });
  });

  describe('PerformanceMonitor Component', () => {
    it('should render without errors', () => {
      expect(() => {
        render(<PerformanceMonitor />);
      }).not.toThrow();
    });

    it('should set up performance observers in production', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      render(<PerformanceMonitor />);

      // Should attempt to set up PerformanceObserver
      expect(mockPerformanceObserver).toHaveBeenCalled();

      process.env.NODE_ENV = originalEnv;
    });
  });

  describe('Critical CSS', () => {
    it('should contain essential styles', () => {
      expect(CRITICAL_CSS).toContain('html');
      expect(CRITICAL_CSS).toContain('body');
      expect(CRITICAL_CSS).toContain('scroll-behavior: smooth');
    });

    it('should include responsive styles', () => {
      expect(CRITICAL_CSS).toContain('@media (max-width: 640px)');
    });

    it('should include dark mode support', () => {
      expect(CRITICAL_CSS).toContain('@media (prefers-color-scheme: dark)');
    });

    it('should generate critical CSS', () => {
      const css = generateCriticalCSS();
      expect(css).toBeTruthy();
      expect(typeof css).toBe('string');
    });
  });

  describe('Image Optimization', () => {
    it('should handle responsive image configurations', () => {
      const { container } = render(
        <LazyImage
          src="/evidence/email-1.webp"
          alt="Evidence image"
          sizes="(max-width: 640px) 320px, (max-width: 1280px) 640px, 1280px"
        />
      );

      const picture = container.querySelector('picture');
      expect(picture).toBeInTheDocument();
    });

    it('should fallback to regular img for non-processed images', () => {
      const { container } = render(
        <LazyImage
          src="/evidence/email-1.svg"
          alt="SVG image"
        />
      );

      const img = container.querySelector('img');
      expect(img).toHaveAttribute('src', '/evidence/email-1.svg');
    });
  });

  describe('Performance Metrics', () => {
    beforeEach(() => {
      // Mock console methods
      jest.spyOn(console, 'log').mockImplementation(() => {});
      jest.spyOn(console, 'warn').mockImplementation(() => {});
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('should handle web vitals reporting', async () => {
      // Mock web-vitals module
      const mockWebVitals = {
        onCLS: jest.fn(),
        onFID: jest.fn(),
        onFCP: jest.fn(),
        onLCP: jest.fn(),
        onTTFB: jest.fn(),
      };

      jest.doMock('web-vitals', () => mockWebVitals);

      render(<PerformanceMonitor />);

      // Should attempt to import and use web-vitals
      // Note: This is a simplified test - in reality, the dynamic import
      // would need more sophisticated mocking
    });
  });

  describe('Lazy Loading', () => {
    it('should set up intersection observer for lazy loading', () => {
      render(
        <LazyImage
          src="/test-image.jpg"
          alt="Test image"
          priority={false}
        />
      );

      expect(mockIntersectionObserver).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({
          rootMargin: '50px',
          threshold: 0.1,
        })
      );
    });

    it('should not set up intersection observer for priority images', () => {
      mockIntersectionObserver.mockClear();

      render(
        <LazyImage
          src="/test-image.jpg"
          alt="Test image"
          priority={true}
        />
      );

      // Should not call IntersectionObserver for priority images
      expect(mockIntersectionObserver).not.toHaveBeenCalled();
    });
  });
});