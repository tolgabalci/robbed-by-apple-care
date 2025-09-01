import { test, expect } from '@playwright/test';

test.describe('Responsive Design', () => {
  test.describe('Desktop View', () => {
    test.use({ viewport: { width: 1280, height: 720 } });

    test('should display desktop layout correctly', async ({ page }) => {
      await page.goto('/');

      // Check navigation is visible
      await expect(page.locator('nav')).toBeVisible();
      
      // Check navigation links are visible on desktop
      const navLinks = page.locator('nav a');
      if (await navLinks.count() > 0) {
        await expect(navLinks.first()).toBeVisible();
      }

      // Check article layout
      await expect(page.locator('article')).toHaveCSS('max-width', '896px'); // max-w-4xl
      
      // Check hero image is properly sized
      const heroImage = page.locator('img').first();
      if (await heroImage.count() > 0) {
        await expect(heroImage).toBeVisible();
      }
    });

    test('should display evidence gallery in grid layout', async ({ page }) => {
      await page.goto('/');
      
      // Check evidence gallery grid
      const evidenceGallery = page.getByTestId('evidence-gallery');
      await expect(evidenceGallery).toBeVisible();
      
      // Check grid layout classes are applied
      const gridContainer = page.locator('.grid');
      if (await gridContainer.count() > 0) {
        await expect(gridContainer.first()).toBeVisible();
      }
    });
  });

  test.describe('Tablet View', () => {
    test.use({ viewport: { width: 768, height: 1024 } });

    test('should display tablet layout correctly', async ({ page }) => {
      await page.goto('/');

      // Check article is still centered
      await expect(page.locator('article')).toBeVisible();
      
      // Check navigation adapts to tablet
      await expect(page.locator('nav')).toBeVisible();
      
      // Check text sizes are appropriate
      const title = page.getByRole('heading', { level: 1 });
      await expect(title).toBeVisible();
    });

    test('should handle evidence gallery on tablet', async ({ page }) => {
      await page.goto('/');
      
      // Evidence gallery should still be visible
      const evidenceGallery = page.getByTestId('evidence-gallery');
      await expect(evidenceGallery).toBeVisible();
    });
  });

  test.describe('Mobile View', () => {
    test.use({ viewport: { width: 375, height: 667 } });

    test('should display mobile layout correctly', async ({ page }) => {
      await page.goto('/');

      // Check article is responsive
      await expect(page.locator('article')).toBeVisible();
      
      // Check navigation is mobile-friendly
      await expect(page.locator('nav')).toBeVisible();
      
      // Check title scales down appropriately
      const title = page.getByRole('heading', { level: 1 });
      await expect(title).toBeVisible();
      
      // Check metadata stacks properly on mobile
      const metadata = page.locator('.gap-2');
      await expect(metadata.first()).toBeVisible();
    });

    test('should handle evidence gallery on mobile', async ({ page }) => {
      await page.goto('/');
      
      // Evidence gallery should be single column on mobile
      const evidenceGallery = page.getByTestId('evidence-gallery');
      await expect(evidenceGallery).toBeVisible();
    });

    test('should handle navigation on mobile', async ({ page }) => {
      await page.goto('/');
      
      // Navigation should be compact on mobile
      const nav = page.locator('nav');
      await expect(nav).toBeVisible();
      
      // Theme toggle should still be accessible
      await expect(page.getByTestId('theme-toggle')).toBeVisible();
    });

    test('should handle timeline on mobile', async ({ page }) => {
      await page.goto('/');
      
      // Timeline should stack vertically on mobile
      await expect(page.getByRole('heading', { name: 'Timeline' })).toBeVisible();
      
      // Timeline items should be readable
      await expect(page.getByText('Day 1: Initial Contact')).toBeVisible();
    });
  });

  test.describe('Large Desktop View', () => {
    test.use({ viewport: { width: 1920, height: 1080 } });

    test('should display large desktop layout correctly', async ({ page }) => {
      await page.goto('/');

      // Article should still be constrained to max-width
      await expect(page.locator('article')).toBeVisible();
      
      // Navigation should show all elements
      await expect(page.locator('nav')).toBeVisible();
      
      // Evidence gallery should use full grid on large screens
      const evidenceGallery = page.getByTestId('evidence-gallery');
      await expect(evidenceGallery).toBeVisible();
    });
  });

  test.describe('Orientation Changes', () => {
    test('should handle landscape to portrait on mobile', async ({ page }) => {
      // Start in landscape
      await page.setViewportSize({ width: 667, height: 375 });
      await page.goto('/');
      
      await expect(page.locator('article')).toBeVisible();
      
      // Switch to portrait
      await page.setViewportSize({ width: 375, height: 667 });
      
      // Content should still be visible and properly laid out
      await expect(page.locator('article')).toBeVisible();
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    });
  });

  test.describe('Zoom Levels', () => {
    test('should handle 150% zoom level', async ({ page, context }) => {
      // Simulate 150% zoom by reducing viewport
      await page.setViewportSize({ width: 853, height: 480 }); // 1280/1.5, 720/1.5
      await page.goto('/');

      // Content should still be accessible
      await expect(page.locator('article')).toBeVisible();
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
      
      // Navigation should still work
      await expect(page.locator('nav')).toBeVisible();
    });

    test('should handle 200% zoom level', async ({ page }) => {
      // Simulate 200% zoom
      await page.setViewportSize({ width: 640, height: 360 }); // 1280/2, 720/2
      await page.goto('/');

      // Content should still be readable
      await expect(page.locator('article')).toBeVisible();
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    });
  });
});