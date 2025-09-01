'use client';

import { useEffect } from 'react';
import { PerformanceUtils } from '@/lib/critical-css';

/**
 * Hook for applying performance optimizations
 */
export function usePerformanceOptimization() {
  useEffect(() => {
    // Apply performance optimizations after component mount
    const applyOptimizations = () => {
      // Lazy load images
      PerformanceUtils.lazyLoadImages();
      
      // Preload resources
      if (typeof window !== 'undefined') {
        // Preload fonts
        const fontPreload = document.createElement('link');
        fontPreload.rel = 'preload';
        fontPreload.as = 'font';
        fontPreload.type = 'font/woff2';
        fontPreload.href = 'https://fonts.gstatic.com/s/inter/v12/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiA.woff2';
        fontPreload.crossOrigin = 'anonymous';
        document.head.appendChild(fontPreload);
      }
    };

    // Apply optimizations after a short delay to avoid blocking initial render
    const timeoutId = setTimeout(applyOptimizations, 100);

    return () => clearTimeout(timeoutId);
  }, []);

  // Return performance utilities for manual use
  return {
    prefetchNextPage: PerformanceUtils.prefetchNextPage,
    deferScript: PerformanceUtils.deferScript,
  };
}

/**
 * Hook for monitoring Core Web Vitals
 */
export function useWebVitals() {
  useEffect(() => {
    // Only run in browser
    if (typeof window === 'undefined') return;

    // Monitor resource loading performance
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach((entry) => {
        // Log slow resources in development
        if (process.env.NODE_ENV === 'development' && entry.duration > 100) {
          console.warn('Slow resource:', {
            name: entry.name,
            duration: entry.duration,
            type: entry.entryType,
          });
        }
      });
    });

    try {
      observer.observe({ entryTypes: ['resource', 'navigation'] });
    } catch (error) {
      console.warn('Performance Observer not supported:', error);
    }

    return () => observer.disconnect();
  }, []);
}

/**
 * Hook for optimizing images
 */
export function useImageOptimization() {
  useEffect(() => {
    if (typeof window === 'undefined') return;

    // Add loading="lazy" to images that don't have it
    const images = document.querySelectorAll('img:not([loading])');
    images.forEach((img) => {
      const htmlImg = img as HTMLImageElement;
      // Don't lazy load images in the first viewport
      const rect = htmlImg.getBoundingClientRect();
      if (rect.top > window.innerHeight) {
        htmlImg.loading = 'lazy';
      }
    });

    // Add decoding="async" for better performance
    const allImages = document.querySelectorAll('img:not([decoding])');
    allImages.forEach((img) => {
      (img as HTMLImageElement).decoding = 'async';
    });
  }, []);
}