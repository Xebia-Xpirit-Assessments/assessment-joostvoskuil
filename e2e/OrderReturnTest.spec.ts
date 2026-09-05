import { test, expect } from '@playwright/test';

test('Request a return for a paid order', async ({ page }) => {
  test.setTimeout(4 * 60_000);

  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Ready for a new adventure?' })).toBeVisible();

  await page.getByRole('link', { name: 'Adventurer GPS Watch' }).click();
  await page.getByRole('button', { name: 'Add to shopping bag' }).click();
  await page.getByRole('link', { name: 'shopping bag' }).click();
  await expect(page.getByRole('heading', { name: 'Shopping bag' })).toBeVisible();

  await page.getByRole('link', { name: 'Check out' }).click();
  await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();

  await page.getByLabel('Address').fill('1 Main Street');
  await page.getByLabel('City').fill('Seattle');
  await page.getByLabel('State').fill('WA');
  await page.getByLabel('Zip code').fill('98101');
  await page.getByLabel('Country').fill('USA');
  await page.getByRole('button', { name: 'Place order' }).click();

  await page.waitForURL('**/user/orders');
  await expect(page.getByRole('heading', { name: 'Orders' })).toBeVisible();

  const orderNumberLink = page.locator('.orders-list .order-number a').first();
  await expect(orderNumberLink).toBeVisible();
  await orderNumberLink.click();

  // Orders progress through the pipeline asynchronously (grace period + processing);
  // poll for the order to reach a status that is eligible for a return request.
  await expect(page.locator('.order-summary .status')).toHaveText(/Paid|Shipped/, { timeout: 3 * 60_000 });

  await page.getByLabel('return units').fill('1');
  await page.getByRole('button', { name: 'Request return' }).click();

  await expect(page.getByText('Your return request has been submitted.')).toBeVisible();
  await expect(page.locator('.order-summary .status')).toHaveText('ReturnRequested');
});
