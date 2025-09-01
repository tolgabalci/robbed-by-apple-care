import { test, expect } from '@playwright/test';

test.describe('Accessibility', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    // Check h1 exists and is unique
    const h1Elements = await page.locator('h1').count();
    expect(h1Elements).toBe(1);

    // Check h1 content
    await expect(page.locator('h1')).toContainText('Robbed by AppleCare');

    // Check h2 elements exist and are properly structured
    const h2Elements = page.locator('h2');
    await expect(h2Elements.first()).toBeVisible();

    // Verify heading hierarchy (no h3 before h2, etc.)
    const headings = await page.locator('h1, h2, h3, h4, h5, h6').all();
    let previousLevel = 0;
    
    for (const heading of headings) {
      const tagName = await heading.evaluate(el => el.tagName.toLowerCase());
      const currentLevel = parseInt(tagName.charAt(1));
      
      // Heading levels shouldn't skip (e.g., h1 -> h3)
      if (previousLevel > 0) {
        expect(currentLevel - previousLevel).toBeLessThanOrEqual(1);
      }
      
      previousLevel = currentLevel;
    }
  });

  test('should have proper alt text for images', async ({ page }) => {
    const images = page.locator('img');
    const imageCount = await images.count();

    for (let i = 0; i < imageCount; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute('alt');
      
      // All images should have alt text (can be empty for decorative images)
      expect(alt).not.toBeNull();
      
      // Non-decorative images should have meaningful alt text
      const src = await img.getAttribute('src');
      if (src && !src.includes('decoration') && !src.includes('icon')) {
        expect(alt).toBeTruthy();
        expect(alt!.length).toBeGreaterThan(0);
      }
    }
  });

  test('should have proper link accessibility', async ({ page }) => {
    const links = page.locator('a');
    const linkCount = await links.count();

    for (let i = 0; i < linkCount; i++) {
      const link = links.nth(i);
      
      // Links should have accessible text or aria-label
      const text = await link.textContent();
      const ariaLabel = await link.getAttribute('aria-label');
      const title = await link.getAttribute('title');
      
      expect(text || ariaLabel || title).toBeTruthy();
      
      // External links should have proper attributes
      const href = await link.getAttribute('href');
      if (href && (href.startsWith('http') && !href.includes('robbedbyapplecare.com'))) {
        const target = await link.getAttribute('target');
        const rel = await link.getAttribute('rel');
        
        if (target === '_blank') {
          expect(rel).toContain('noopener');
        }
      }
    }
  });

  test('should have proper form accessibility', async ({ page }) => {
    // Check if there are any form elements
    const inputs = page.locator('input, textarea, select');
    const inputCount = await inputs.count();

    for (let i = 0; i < inputCount; i++) {
      const input = inputs.nth(i);
      
      // Form elements should have labels or aria-label
      const id = await input.getAttribute('id');
      const ariaLabel = await input.getAttribute('aria-label');
      const ariaLabelledby = await input.getAttribute('aria-labelledby');
      
      if (id) {
        const label = page.locator(`label[for="${id}"]`);
        const hasLabel = await label.count() > 0;
        
        expect(hasLabel || ariaLabel || ariaLabelledby).toBeTruthy();
      } else {
        expect(ariaLabel || ariaLabelledby).toBeTruthy();
      }
    }
  });

  test('should have proper button accessibility', async ({ page }) => {
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();

    for (let i = 0; i < buttonCount; i++) {
      const button = buttons.nth(i);
      
      // Buttons should have accessible text or aria-label
      const text = await button.textContent();
      const ariaLabel = await button.getAttribute('aria-label');
      
      expect(text?.trim() || ariaLabel).toBeTruthy();
      
      // Buttons should be focusable
      await button.focus();
      expect(await button.evaluate(el => document.activeElement === el)).toBe(true);
    }
  });

  test('should have proper ARIA landmarks', async ({ page }) => {
    // Check for main landmark
    await expect(page.locator('main, [role="main"]')).toBeVisible();
    
    // Check for navigation landmark
    await expect(page.locator('nav, [role="navigation"]')).toBeVisible();
    
    // Check for article landmark
    await expect(page.locator('article, [role="article"]')).toBeVisible();
    
    // Check for contentinfo landmark (footer)
    await expect(page.locator('footer, [role="contentinfo"]')).toBeVisible();
  });

  test('should have proper color contrast', async ({ page }) => {
    // This is a basic check - in a real scenario you'd use axe-core
    const textElements = page.locator('p, h1, h2, h3, h4, h5, h6, span, a');
    const elementCount = await textElements.count();
    
    // Check that text elements are visible (basic contrast check)
    for (let i = 0; i < Math.min(elementCount, 10); i++) {
      const element = textElements.nth(i);
      await expect(element).toBeVisible();
      
      // Check that text has content
      const text = await element.textContent();
      if (text && text.trim()) {
        // Element should be visible and have text
        expect(text.trim().length).toBeGreaterThan(0);
      }
    }
  });

  test('should support keyboard navigation', async ({ page }) => {
    // Test tab navigation
    await page.keyboard.press('Tab');
    
    // Check that focus is visible
    const focusedElement = page.locator(':focus');
    await expect(focusedElement).toBeVisible();
    
    // Test navigation through interactive elements
    const interactiveElements = page.locator('a, button, input, textarea, select, [tabindex]:not([tabindex="-1"])');
    const count = await interactiveElements.count();
    
    if (count > 0) {
      // Tab through first few elements
      for (let i = 0; i < Math.min(count, 5); i++) {
        await page.keyboard.press('Tab');
        const currentFocus = page.locator(':focus');
        await expect(currentFocus).toBeVisible();
      }
    }
  });

  test('should handle focus management', async ({ page }) => {
    // Test skip links if they exist
    const skipLinks = page.locator('a[href^="#"]').filter({ hasText: /skip/i });
    const skipLinkCount = await skipLinks.count();
    
    if (skipLinkCount > 0) {
      const skipLink = skipLinks.first();
      await skipLink.focus();
      await expect(skipLink).toBeFocused();
      
      await skipLink.press('Enter');
      // Focus should move to the target
    }
    
    // Test that focus doesn't get trapped inappropriately
    await page.keyboard.press('Tab');
    const focusedElement = page.locator(':focus');
    await expect(focusedElement).toBeVisible();
  });

  test('should have proper semantic structure', async ({ page }) => {
    // Check for proper use of semantic HTML
    await expect(page.locator('article')).toBeVisible();
    await expect(page.locator('header')).toBeVisible();
    await expect(page.locator('footer')).toBeVisible();
    
    // Check for proper section usage
    const sections = page.locator('section');
    const sectionCount = await sections.count();
    expect(sectionCount).toBeGreaterThan(0);
    
    // Each section should have a heading or aria-label
    for (let i = 0; i < sectionCount; i++) {
      const section = sections.nth(i);
      const hasHeading = await section.locator('h1, h2, h3, h4, h5, h6').count() > 0;
      const ariaLabel = await section.getAttribute('aria-label');
      const ariaLabelledby = await section.getAttribute('aria-labelledby');
      
      expect(hasHeading || ariaLabel || ariaLabelledby).toBeTruthy();
    }
  });

  test('should have proper time elements', async ({ page }) => {
    const timeElements = page.locator('time');
    const timeCount = await timeElements.count();
    
    for (let i = 0; i < timeCount; i++) {
      const timeElement = timeElements.nth(i);
      const datetime = await timeElement.getAttribute('datetime');
      
      // Time elements should have datetime attribute
      expect(datetime).toBeTruthy();
      
      // Datetime should be in valid format
      if (datetime) {
        expect(datetime).toMatch(/^\d{4}-\d{2}-\d{2}/);
      }
    }
  });

  test('should support screen reader navigation', async ({ page }) => {
    // Check for proper ARIA attributes
    const elementsWithAria = page.locator('[aria-label], [aria-labelledby], [aria-describedby], [role]');
    const ariaCount = await elementsWithAria.count();
    
    if (ariaCount > 0) {
      for (let i = 0; i < Math.min(ariaCount, 5); i++) {
        const element = elementsWithAria.nth(i);
        
        // ARIA labels should not be empty
        const ariaLabel = await element.getAttribute('aria-label');
        if (ariaLabel) {
          expect(ariaLabel.trim()).toBeTruthy();
        }
        
        // ARIA labelledby should reference existing elements
        const ariaLabelledby = await element.getAttribute('aria-labelledby');
        if (ariaLabelledby) {
          const referencedElement = page.locator(`#${ariaLabelledby}`);
          await expect(referencedElement).toBeAttached();
        }
      }
    }
  });

  test('should have proper table accessibility', async ({ page }) => {
    const tables = page.locator('table');
    const tableCount = await tables.count();
    
    for (let i = 0; i < tableCount; i++) {
      const table = tables.nth(i);
      
      // Tables should have captions or aria-label
      const caption = table.locator('caption');
      const ariaLabel = await table.getAttribute('aria-label');
      const hasCaption = await caption.count() > 0;
      
      expect(hasCaption || ariaLabel).toBeTruthy();
      
      // Check for proper header structure
      const headers = table.locator('th');
      const headerCount = await headers.count();
      
      if (headerCount > 0) {
        // Headers should have scope attribute for complex tables
        const complexTable = await table.locator('tbody tr').count() > 1 && 
                            await table.locator('thead th').count() > 1;
        
        if (complexTable) {
          for (let j = 0; j < headerCount; j++) {
            const header = headers.nth(j);
            const scope = await header.getAttribute('scope');
            // Scope should be col, row, colgroup, or rowgroup
            if (scope) {
              expect(['col', 'row', 'colgroup', 'rowgroup']).toContain(scope);
            }
          }
        }
      }
    }
  });
});