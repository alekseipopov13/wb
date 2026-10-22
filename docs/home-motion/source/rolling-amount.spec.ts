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

test('group moves during counting with stable decimal spacing', async ({page}) => {
 await page.goto('/wb-test/');
 await page.waitForTimeout(800);
 for(const mode of ['shopping','accounts']) {
  const result = await page.evaluate(async mode => {
   const read=()=>Array.from(document.querySelectorAll('.rolling-amount .amount-digit-cell,.rolling-amount .amount-currency,.hide-balance')).map(el=>el.getBoundingClientRect().x);
   const visibleCenter=()=>{
    const first=Array.from(document.querySelectorAll('.rolling-amount .amount-digit-cell')).find(el=>el.textContent)!;
    return (first.getBoundingClientRect().left + document.querySelector('.hide-balance')!.getBoundingClientRect().right)/2;
   };
   const startCenter=visibleCenter();
   const beforeWidth=document.querySelector('.balance-number')!.getBoundingClientRect().width;
   const values=[read()];
   (document.querySelector(`#tab-${mode}`) as HTMLButtonElement).click();
   const start=performance.now();
   while(performance.now()-start<330){await new Promise(requestAnimationFrame);values.push(read());}
   await new Promise(resolve=>setTimeout(resolve,500));
   return {values,startCenter,endCenter:visibleCenter(),beforeWidth,afterWidth:document.querySelector('.balance-number')!.getBoundingClientRect().width};
  }, mode);
  for(const sample of result.values){
   expect(sample).toHaveLength(result.values[0].length);
   const shift=sample[0]-result.values[0][0];
   sample.forEach((x,i)=>expect(Math.abs(x-result.values[0][i]-shift)).toBeLessThan(.1));
  }
  expect(Math.abs(result.values.at(-1)![0]-result.values[0][0])).toBeGreaterThan(10);
  expect(Math.abs(result.startCenter-201)).toBeLessThan(.5);
  expect(Math.abs(result.endCenter-201)).toBeLessThan(.5);
  expect(Math.abs(result.afterWidth-result.beforeWidth)).toBeGreaterThan(30);
 }
});

test('digits keep a gap before ruble throughout both transitions', async ({page}) => {
 await page.goto('/wb-test/');
 for (const mode of ['shopping', 'accounts', 'shopping']) {
  await page.locator(`#tab-${mode}`).click();
  const gaps = await page.locator('.rolling-amount').evaluate(async el => {
   const samples: number[] = [];
   const started = performance.now();
   while (performance.now() - started < 850) {
    const digits = document.createRange();
    digits.selectNodeContents(el.firstElementChild!);
    const currency = document.createRange();
    const text = el.lastElementChild!.lastChild!;
    const symbol = text.textContent!.indexOf('₽');
    currency.setStart(text, symbol);
    currency.setEnd(text, symbol + 1);
    samples.push(currency.getBoundingClientRect().left - digits.getBoundingClientRect().right);
    await new Promise(requestAnimationFrame);
   }
   return samples;
  });
  // Range includes glyph side bearings beyond the fixed decimal cell.
  expect(Math.min(...gaps)).toBeGreaterThanOrEqual(5.5);
  expect(Math.max(...gaps)-Math.min(...gaps)).toBeLessThan(.2);
  expect(Math.max(...gaps)).toBeLessThan(12);
 }
});

test('amount stays centred without oscillation or a detached currency', async ({page}) => {
 await page.goto('/wb-test/');
 await page.waitForTimeout(600);
 for(const mode of ['shopping','accounts']) {
  await page.locator(`#tab-${mode}`).click();
  const samples = await page.evaluate(async () => {
   const result:{center:number;spacing:number;lastDigitX:number;cellWidths:number[]}[]=[];
   const start=performance.now();
   while(performance.now()-start<850){
    const number=document.querySelector('.balance-number')!.getBoundingClientRect();
    const eye=document.querySelector('.hide-balance')!.getBoundingClientRect();
    const cells=Array.from(document.querySelectorAll('.rolling-amount .amount-digit-cell')).map(el=>el.getBoundingClientRect());
    result.push({center:(number.left+eye.right)/2,spacing:cells.at(-1)!.x-cells.at(-2)!.x,lastDigitX:cells.at(-1)!.x,cellWidths:cells.map(r=>r.width)});
    await new Promise(requestAnimationFrame);
   }
   return result;
  });
  expect(Math.max(...samples.map(s=>s.center))-Math.min(...samples.map(s=>s.center))).toBeLessThan(.1);
  expect(Math.abs(samples[0].center-201)).toBeLessThan(.5);
  expect(Math.max(...samples.map(s=>s.spacing))-Math.min(...samples.map(s=>s.spacing))).toBeLessThan(.1);
  const direction = mode === 'shopping' ? 1 : -1;
  for(let i=1;i<samples.length;i++) expect((samples[i].lastDigitX-samples[i-1].lastDigitX)*direction).toBeGreaterThanOrEqual(-.1);
  for(const s of samples)expect(Math.max(...s.cellWidths)-Math.min(...s.cellWidths)).toBeLessThan(.1);
 }
});


test('balance spacing matches the Figma section', async ({page}) => {
 await page.goto('/wb-test/');
 await page.waitForTimeout(600);
 const geometry=await page.evaluate(()=>{
  const rect=(selector:string)=>document.querySelector(selector)!.getBoundingClientRect();
  const tabs=rect('.balance-tabs'),line=rect('.balance-line'),number=rect('.balance-number'),eye=rect('.hide-balance'),cards=rect('.account-carousel');
  return {top:line.top-tabs.bottom,height:line.height,bottom:cards.top-line.bottom,eyeGap:eye.left-number.right,amountWidth:number.width,numberHeight:number.height,numberY:number.top-line.top,iconY:rect('.hide-balance img').top-line.top};
 });
 expect(geometry.top).toBe(12);
 expect(geometry.height).toBe(65);
 expect(geometry.bottom).toBe(12);
 expect(geometry.eyeGap).toBe(8);
 expect(geometry.numberHeight).toBe(58);
 expect(geometry.numberY).toBe(3.5);
 expect(geometry.iconY).toBe(20.5);
 expect(Math.abs(geometry.amountWidth-208)).toBeLessThan(1);
});
