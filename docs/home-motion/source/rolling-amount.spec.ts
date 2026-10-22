import { test, expect } from '@playwright/test';

test('total counts through intermediate values, reverses and stays private', async ({page}) => {
 await page.goto('/wb-test/');
 const amount = page.locator('.rolling-amount');
 await expect(amount).toHaveText('95 775 ₽');
 await page.locator('#tab-shopping').click();
 await page.waitForTimeout(80);
 const intermediate = Number((await amount.innerText()).replace(/\D/g, ''));
 expect(intermediate).toBeGreaterThan(95775);
 expect(intermediate).toBeLessThan(154261);
 await page.locator('#tab-accounts').click();
 await expect(amount).toHaveText('95 775 ₽');
 await page.getByRole('button',{name:'Скрыть баланс'}).click();
 await page.locator('#tab-shopping').click();
 await expect(page.getByTestId('balance').locator('.privacy-value')).toHaveCSS('opacity','0');
 await expect(amount).toHaveText('154 261 ₽');
 await page.getByRole('button',{name:'Показать баланс'}).click();
 await expect(page.getByTestId('balance').locator('.privacy-value')).toHaveCSS('opacity','1');
});

test('reduced motion shows the final amount immediately', async ({page}) => {
 await page.emulateMedia({ reducedMotion: 'reduce' });
 await page.goto('/wb-test/');
 await page.locator('#tab-shopping').click();
 expect(await page.locator('.rolling-amount').textContent()).toBe('154 261 ₽');
});

test('comparison page restores staggered slide-up animation', async ({page}) => {
 await page.goto('/wb-test-1/');
 await expect(page.locator('.amount-current')).toHaveText('95 775 ₽');
 await expect(page.locator('.rolling-amount')).toHaveCount(0);
 await page.locator('#tab-shopping').click();
 await page.waitForTimeout(80);
 const characters = page.locator('.amount-current').last().locator('.amount-character');
 const offsets = await characters.evaluateAll(elements => elements.map(el => new DOMMatrix(getComputedStyle(el).transform).m42));
 expect(offsets[0]).toBeLessThan(offsets[5]);
 expect(offsets[5]).toBeGreaterThan(0);
 await expect(page.locator('.amount-current')).toHaveCount(1);
 await expect(page.locator('.amount-current')).toHaveText('154 261 ₽');
 await page.locator('#tab-accounts').click();
 await expect(page.locator('.amount-current')).toHaveCount(1);
 await expect(page.locator('.amount-current')).toHaveText('95 775 ₽');
});

test('eye moves through intermediate positions as amount width changes', async ({page}) => {
 await page.goto('/wb-test/');
 const eye = page.locator('.hide-balance');
 const currency = page.locator('.amount-currency');
 await page.waitForTimeout(550);
 const start = (await eye.boundingBox())!.x;
 const currencyStart = (await currency.boundingBox())!.x;
 await page.locator('#tab-shopping').click();
 await page.waitForTimeout(150);
 const middle = (await eye.boundingBox())!.x;
 const currencyMiddle = (await currency.boundingBox())!.x;
 await page.waitForTimeout(500);
 const end = (await eye.boundingBox())!.x;
 const currencyEnd = (await currency.boundingBox())!.x;
 expect(currencyMiddle).toBeGreaterThan(currencyStart + .5);
 expect(currencyMiddle).toBeLessThan(currencyEnd - .5);
 expect(Math.abs((middle - currencyMiddle) - (end - currencyEnd))).toBeLessThan(1);
 expect(middle).toBeGreaterThan(start + .5);
 expect(middle).toBeLessThan(end - .5);
 await page.locator('#tab-accounts').click();
 await page.waitForTimeout(150);
 const returning = (await eye.boundingBox())!.x;
 expect(returning).toBeLessThan(end - .5);
 expect(returning).toBeGreaterThan(start + .5);
});

test('digits keep a gap before ruble throughout both transitions', async ({page}) => {
 await page.goto('/wb-test/');
 for (const mode of ['shopping', 'accounts', 'shopping']) {
  await page.locator(`#tab-${mode}`).click();
  const gaps = await page.locator('.rolling-amount').evaluate(async el => {
   const samples: number[] = [];
   const started = performance.now();
   while (performance.now() - started < 650) {
    const digits = document.createRange();
    digits.selectNodeContents(el.firstElementChild!);
    const currency = document.createRange();
    const text = el.lastElementChild!.firstChild!;
    const symbol = text.textContent!.indexOf('₽');
    currency.setStart(text, symbol);
    currency.setEnd(text, symbol + 1);
    samples.push(currency.getBoundingClientRect().left - digits.getBoundingClientRect().right);
    await new Promise(requestAnimationFrame);
   }
   return samples;
  });
  expect(Math.min(...gaps)).toBeGreaterThan(4);
 }
});
