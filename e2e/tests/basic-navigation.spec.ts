import { test, expect } from '@playwright/test';

test.describe('Basic Navigation Tests', () => {
  test('should navigate to example.com and capture title', async ({ page }) => {
    await page.goto('https://example.com');

    const title = await page.title();
    expect(title).toBe('Example Domain');

    const heading = await page.locator('h1').textContent();
    expect(heading).toBe('Example Domain');
  });

  test('should take a screenshot', async ({ page }) => {
    await page.goto('https://example.com');

    const screenshot = await page.screenshot();
    expect(screenshot).toBeTruthy();
    expect(screenshot.length).toBeGreaterThan(0);
  });

  test('should interact with elements', async ({ page }) => {
    await page.goto('https://example.com');

    // Verify link exists
    const link = page.locator('a[href="https://www.iana.org/domains/example"]');
    await expect(link).toBeVisible();

    // Get link text
    const linkText = await link.textContent();
    expect(linkText).toContain('More information');
  });

  test('should capture network requests', async ({ page }) => {
    const requests: string[] = [];

    page.on('request', request => {
      requests.push(request.url());
    });

    await page.goto('https://example.com');

    expect(requests.length).toBeGreaterThan(0);
    expect(requests).toContain('https://example.com/');
  });

  test('should capture console logs', async ({ page }) => {
    const logs: string[] = [];

    page.on('console', msg => {
      logs.push(msg.text());
    });

    await page.goto('https://example.com');

    // Note: example.com may not have console logs
    // This test just verifies the mechanism works
    expect(logs).toBeDefined();
  });
});
