import { test, expect } from '@playwright/test';

test('Request a return/refund for a paid order', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Ready for a new adventure?' })).toBeVisible();

  // Add an item to the cart and place an order.
  await page.getByRole('link', { name: 'Adventurer GPS Watch' }).click();
  await page.getByRole('button', { name: 'Add to shopping bag' }).click();
  await page.getByRole('link', { name: 'shopping bag' }).click();
  await expect(page.getByRole('heading', { name: 'Shopping bag' })).toBeVisible();

  await page.getByRole('link', { name: 'Check out' }).click();
  await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  await page.getByRole('button', { name: 'Place order' }).click();

  await expect(page.getByRole('heading', { name: 'Orders' })).toBeVisible();

  // Wait for the (simulated) payment to be processed so the order becomes eligible for return.
  const paidStatus = page.locator('.orders-item .status').first();
  await expect(paidStatus).toHaveText('Paid', { timeout: 30_000 });

  // Navigate to the order detail page and request a return for the purchased item.
  await page.locator('.orders-item .order-number a').first().click();
  await expect(page.getByText('Status: Paid')).toBeVisible();

  await page.getByLabel(/units to return for/i).first().fill('1');
  await page.getByRole('button', { name: 'Request return / refund' }).click();

  await expect(page.getByText('Your return request was submitted successfully.')).toBeVisible();
  await expect(page.getByText(/Status: (ReturnRequested|Returned)/)).toBeVisible({ timeout: 30_000 });
});
