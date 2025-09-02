import { test, expect } from '@playwright/test';

test.describe('Article Reading Experience', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should display article title and content', async ({ page }) => {
    // Check main heading
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Robbed by AppleCare');

    // Check subtitle
    await expect(page.locator('p').filter({ hasText: /premium support service/ })).toBeVisible();

    // Check TL;DR section
    await expect(page.getByRole('heading', { name: 'TL;DR' })).toBeVisible();
    await expect(page.locator('.callout')).toBeVisible();

    // Check article metadata
    await expect(page.getByText(/min read/)).toBeVisible();
    await expect(page.getByText(/words/)).toBeVisible();
  });

  test('should have proper navigation structure', async ({ page }) => {
    // Check navigation bar
    await expect(page.locator('nav')).toBeVisible();
    
    // Check theme toggle
    await expect(page.getByTestId('theme-toggle')).toBeVisible();

    // Check back to top button
    await expect(page.getByTestId('back-to-top')).toBeVisible();
  });

  test('should display evidence gallery', async ({ page }) => {
    // Check evidence section
    await expect(page.getByRole('heading', { name: 'Evidence' })).toBeVisible();
    
    // Check evidence gallery
    await expect(page.getByTestId('evidence-gallery')).toBeVisible();
    
    // Check evidence items
    const evidenceItems = page.getByTestId(/evidence-\d+/);
    await expect(evidenceItems.first()).toBeVisible();
  });

  test('should display timeline section', async ({ page }) => {
    // Scroll to timeline section
    await page.locator('#timeline').scrollIntoViewIfNeeded();
    
    // Check timeline heading
    await expect(page.getByRole('heading', { name: 'Timeline' })).toBeVisible();
    
    // Check timeline items
    await expect(page.getByText('Day 1: Initial Contact')).toBeVisible();
    await expect(page.getByText('Day 7: First Escalation')).toBeVisible();
    await expect(page.getByText('Day 14: The Runaround')).toBeVisible();
    await expect(page.getByText('Day 21: Case Closed')).toBeVisible();
  });

  test('should display Discourse comments section', async ({ page }) => {
    // Check discussion heading
    await expect(page.getByRole('heading', { name: 'Discussion' })).toBeVisible();
    
    // Check comments section
    await expect(page.locator('#comments')).toBeVisible();
    
    // Check loading state or comments
    const commentsSection = page.locator('#comments');
    await expect(commentsSection).toBeVisible();
  });

  test('should have proper semantic HTML structure', async ({ page }) => {
    // Check main article element
    await expect(page.locator('article')).toBeVisible();
    
    // Check header element
    await expect(page.locator('header')).toBeVisible();
    
    // Check footer element
    await expect(page.locator('footer')).toBeVisible();
    
    // Check section elements (should have at least 3: tldr, evidence, timeline, comments)
    const sections = page.locator('section');
    const sectionCount = await sections.count();
    expect(sectionCount).toBeGreaterThanOrEqual(3);
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    // Check h1 exists and is unique
    const h1Elements = page.locator('h1');
    await expect(h1Elements).toHaveCount(1);
    
    // Check h2 elements exist
    const h2Elements = page.locator('h2');
    await expect(h2Elements.first()).toBeVisible();
    
    // Check h3 elements exist in timeline
    const h3Elements = page.locator('h3');
    await expect(h3Elements.first()).toBeVisible();
  });

  test('should display social sharing section', async ({ page }) => {
    // Scroll to footer
    await page.locator('footer').scrollIntoViewIfNeeded();
    
    // Check share section
    await expect(page.getByText('Share this article')).toBeVisible();
    await expect(page.getByTestId('social-share')).toBeVisible();
  });

  test('should display last updated date', async ({ page }) => {
    // Scroll to footer
    await page.locator('footer').scrollIntoViewIfNeeded();
    
    // Check last updated
    await expect(page.getByText(/Last updated:/)).toBeVisible();
  });
});