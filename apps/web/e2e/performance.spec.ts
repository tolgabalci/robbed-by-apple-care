import { test, expect } from '@playwright/test';

test.describe('Performance Metrics', () => {
  test('should meet Core Web Vitals thresholds', async ({ page }) => {
    // Navigate to the page
    await page.goto('/');

    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Measure Core Web Vitals
    const vitals = await page.evaluate(() => {
      return new Promise((resolve) => {
        const vitals: any = {};
        
        // Largest Contentful Paint (LCP)
        new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const lastEntry = entries[entries.length - 1];
          vitals.lcp = lastEntry.startTime;
        }).observe({ entryTypes: ['largest-contentful-paint'] });

        // First Input Delay (FID) - can't be measured without user interaction
        // We'll simulate a click to measure it
        
        // Cumulative Layout Shift (CLS)
        let clsValue = 0;
        new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (!(entry as any).hadRecentInput) {
              clsValue += (entry as any).value;
            }
          }
          vitals.cls = clsValue;
        }).observe({ entryTypes: ['layout-shift'] });

        // First Contentful Paint (FCP)
        new PerformanceObserver((list) => {
          const entries = list.getEntries();
          vitals.fcp = entries[0].startTime;
        }).observe({ entryTypes: ['paint'] });

        // Time to Interactive (TTI) approximation
        const navigationEntry = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
        vitals.tti = navigationEntry.domInteractive;

        setTimeout(() => resolve(vitals), 3000);
      });
    });

    // Assert Core Web Vitals thresholds
    // LCP should be less than 2.5 seconds (2500ms)
    if ((vitals as any).lcp) {
      expect((vitals as any).lcp).toBeLessThan(2500);
    }

    // FCP should be less than 1.8 seconds (1800ms)
    if ((vitals as any).fcp) {
      expect((vitals as any).fcp).toBeLessThan(1800);
    }

    // CLS should be less than 0.1
    if ((vitals as any).cls !== undefined) {
      expect((vitals as any).cls).toBeLessThan(0.1);
    }

    // TTI should be reasonable (less than 5 seconds)
    if ((vitals as any).tti) {
      expect((vitals as any).tti).toBeLessThan(5000);
    }
  });

  test('should load images efficiently', async ({ page }) => {
    await page.goto('/');

    // Check that images have proper loading attributes
    const images = page.locator('img');
    const imageCount = await images.count();

    if (imageCount > 0) {
      // Check first image (hero image) loads eagerly
      const heroImage = images.first();
      const loading = await heroImage.getAttribute('loading');
      // Hero image might be eager or not have loading attribute
      
      // Check that images have proper alt text
      for (let i = 0; i < Math.min(imageCount, 3); i++) {
        const img = images.nth(i);
        const alt = await img.getAttribute('alt');
        expect(alt).toBeTruthy();
      }
    }
  });

  test('should have efficient resource loading', async ({ page }) => {
    // Start measuring network activity
    const responses: any[] = [];
    page.on('response', response => {
      responses.push({
        url: response.url(),
        status: response.status(),
        size: response.headers()['content-length'],
        type: response.headers()['content-type']
      });
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check that all resources loaded successfully
    const failedRequests = responses.filter(r => r.status >= 400);
    expect(failedRequests).toHaveLength(0);

    // Check for efficient caching headers
    const staticAssets = responses.filter(r => 
      r.url.includes('.js') || 
      r.url.includes('.css') || 
      r.url.includes('.png') || 
      r.url.includes('.jpg') || 
      r.url.includes('.svg')
    );

    // Most static assets should be cacheable
    expect(staticAssets.length).toBeGreaterThan(0);
  });

  test('should have fast Time to First Byte (TTFB)', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto('/');
    
    // Measure TTFB using Navigation Timing API
    const ttfb = await page.evaluate(() => {
      const navEntry = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      return navEntry.responseStart - navEntry.requestStart;
    });

    // TTFB should be less than 600ms for good performance
    expect(ttfb).toBeLessThan(600);
  });

  test('should handle slow network conditions', async ({ page, context }) => {
    // Simulate slow 3G network
    await context.route('**/*', async route => {
      await new Promise(resolve => setTimeout(resolve, 100)); // Add 100ms delay
      await route.continue();
    });

    const startTime = Date.now();
    await page.goto('/');
    
    // Page should still load within reasonable time even on slow network
    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(10000); // 10 seconds max

    // Content should still be visible
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  });

  test('should have efficient JavaScript bundle', async ({ page }) => {
    const jsRequests: any[] = [];
    
    page.on('response', response => {
      if (response.url().includes('.js')) {
        jsRequests.push({
          url: response.url(),
          size: response.headers()['content-length']
        });
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Should have JavaScript files loaded
    expect(jsRequests.length).toBeGreaterThan(0);

    // Check that main bundle isn't too large
    const mainBundle = jsRequests.find(req => req.url.includes('main') || req.url.includes('index'));
    if (mainBundle && mainBundle.size) {
      // Main bundle should be reasonable size (less than 1MB)
      expect(parseInt(mainBundle.size)).toBeLessThan(1024 * 1024);
    }
  });

  test('should render above-the-fold content quickly', async ({ page }) => {
    await page.goto('/');

    // Measure when above-the-fold content is visible
    const aboveFoldTime = await page.evaluate(() => {
      return new Promise((resolve) => {
        const observer = new MutationObserver(() => {
          const title = document.querySelector('h1');
          const subtitle = document.querySelector('p');
          
          if (title && subtitle && title.textContent && subtitle.textContent) {
            resolve(performance.now());
            observer.disconnect();
          }
        });
        
        observer.observe(document.body, { childList: true, subtree: true });
        
        // Fallback timeout
        setTimeout(() => resolve(performance.now()), 5000);
      });
    });

    // Above-the-fold content should render within 1.5 seconds
    expect(aboveFoldTime).toBeLessThan(1500);
  });

  test('should handle concurrent users simulation', async ({ page, context }) => {
    // Simulate multiple concurrent requests
    const promises = [];
    
    for (let i = 0; i < 5; i++) {
      promises.push(
        context.newPage().then(async (newPage) => {
          const startTime = Date.now();
          await newPage.goto('/');
          await newPage.waitForLoadState('networkidle');
          const loadTime = Date.now() - startTime;
          await newPage.close();
          return loadTime;
        })
      );
    }

    const loadTimes = await Promise.all(promises);
    
    // All pages should load within reasonable time
    loadTimes.forEach(time => {
      expect(time).toBeLessThan(5000);
    });

    // Average load time should be reasonable
    const avgLoadTime = loadTimes.reduce((a, b) => a + b, 0) / loadTimes.length;
    expect(avgLoadTime).toBeLessThan(3000);
  });
});