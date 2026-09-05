import { test, expect } from '@playwright/test';

// Placing an order and having it processed to a returnable status (Paid/Shipped) takes a
// couple of minutes because the order background workflow includes a grace period before
// stock is confirmed. Refund processing after requesting a return is fast (no grace period),
// so we allow generous time for the first wait and a smaller amount for the second.
test.setTimeout(5 * 60_000);

test('Request a return for an order and see it refunded', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Ready for a new adventure?' })).toBeVisible();

  // Add an item to the shopping bag and check out.
  await page.getByRole('link', { name: 'Adventurer GPS Watch' }).click();
  await page.getByRole('button', { name: 'Add to shopping bag' }).click();
  await page.getByRole('link', { name: 'shopping bag' }).click();
  await expect(page.getByRole('heading', { name: 'Shopping bag' })).toBeVisible();

  await page.getByRole('link', { name: 'Check out' }).click();
  await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  await page.getByRole('button', { name: 'Place order' }).click();

  // Checkout redirects to the orders list; the newest order is the first row.
  await expect(page.getByRole('heading', { name: 'Orders' })).toBeVisible();
  const firstOrderLink = page.locator('a.order-link').first();
  await expect(firstOrderLink).toBeVisible();
  await firstOrderLink.click();

  await expect(page.getByRole('heading', { name: /Order #/ })).toBeVisible();

  // Wait for the order to progress far enough (Paid or Shipped) that a return can be requested.
  await expect.poll(async () => {
    await page.reload();
    return page.locator('.order-status .status').innerText();
  }, { timeout: 4 * 60_000, intervals: [5_000] }).toMatch(/Paid|Shipped/);

  // Request a return for the purchased item.
  await page.getByLabel('return quantity').fill('1');
  await page.getByRole('button', { name: 'Request return' }).click();
  await expect(page.getByText('Your return request has been submitted.')).toBeVisible();
  await expect(page.locator('.order-status .status')).toHaveText('ReturnRequested');

  // The payment processor simulates the refund shortly after the return is requested.
  await expect.poll(async () => {
    await page.reload();
    return page.locator('.order-status .status').innerText();
  }, { timeout: 60_000, intervals: [2_000] }).toBe('Refunded');
});
