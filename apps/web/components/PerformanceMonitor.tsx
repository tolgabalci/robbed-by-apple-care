'use client';

import { useEffect } from 'react';

interface WebVitalsMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
}

/**
 * Performance monitoring component that tracks Core Web Vitals
 * and reports them for analysis
 */
export default function PerformanceMonitor() {
  useEffect(() => {
    // Only run in production and when web-vitals is available
    if (process.env.NODE_ENV !== 'production') return;

    const reportWebVitals = (metric: WebVitalsMetric) => {
      // Log to console in development
      if (process.env.NODE_ENV === 'development') {
        console.log('Web Vital:', metric);
      }

      // In production, you would send this to your analytics service
      // Example: Google Analytics, DataDog, New Relic, etc.
      if (typeof window !== 'undefined' && window.gtag) {
        window.gtag('event', metric.name, {
          event_category: 'Web Vitals',
          event_label: metric.id,
          value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
          non_interaction: true,
        });
      }

      // Custom analytics endpoint (example)
      if (process.env.NODE_ENV === 'production') {
        fetch('/api/analytics/web-vitals', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: metric.name,
            value: metric.value,
            rating: metric.rating,
            delta: metric.delta,
            id: metric.id,
            url: window.location.href,
            timestamp: Date.now(),
          }),
        }).catch((error) => {
          console.warn('Failed to report web vital:', error);
        });
      }
    };

    // Dynamically import web-vitals to avoid bundling it in development
    import('web-vitals').then(({ onCLS, onINP, onFCP, onLCP, onTTFB }) => {
      onCLS(reportWebVitals);
      onINP(reportWebVitals); // FID has been replaced with INP in web-vitals v3
      onFCP(reportWebVitals);
      onLCP(reportWebVitals);
      onTTFB(reportWebVitals);
    }).catch((error) => {
      console.warn('Failed to load web-vitals:', error);
    });

    // Additional performance monitoring
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach((entry) => {
        // Monitor long tasks (>50ms)
        if (entry.entryType === 'longtask') {
          console.warn('Long task detected:', {
            duration: entry.duration,
            startTime: entry.startTime,
          });
        }

        // Monitor navigation timing
        if (entry.entryType === 'navigation') {
          const navEntry = entry as PerformanceNavigationTiming;
          const metrics = {
            dns: navEntry.domainLookupEnd - navEntry.domainLookupStart,
            tcp: navEntry.connectEnd - navEntry.connectStart,
            ssl: navEntry.connectEnd - navEntry.secureConnectionStart,
            ttfb: navEntry.responseStart - navEntry.requestStart,
            download: navEntry.responseEnd - navEntry.responseStart,
            domParse: navEntry.domContentLoadedEventEnd - navEntry.responseEnd,
            domReady: navEntry.domContentLoadedEventEnd - navEntry.startTime,
            loadComplete: navEntry.loadEventEnd - navEntry.startTime,
          };

          if (process.env.NODE_ENV === 'development') {
            console.log('Navigation Timing:', metrics);
          }
        }
      });
    });

    // Observe performance entries
    try {
      observer.observe({ entryTypes: ['longtask', 'navigation'] });
    } catch (error) {
      console.warn('Performance Observer not supported:', error);
    }

    return () => {
      observer.disconnect();
    };
  }, []);

  // This component doesn't render anything
  return null;
}

// Extend Window interface for gtag
declare global {
  interface Window {
    gtag?: (
      command: string,
      targetId: string,
      config?: Record<string, any>
    ) => void;
  }
}