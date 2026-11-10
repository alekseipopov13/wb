import { test, expect } from '@playwright/test';

test('skeleton, cashback shrink, referral reveal and tilt run sequentially without layout shift', async ({page}) => {
  await page.goto('/wb-test/', {waitUntil:'domcontentloaded'});
  const home = page.locator('main.phone');
  await expect(home).toHaveAttribute('data-intro', 'loading');
  await expect(home).toHaveAttribute('aria-busy', 'true');
  await expect(page.locator('.home-skeleton')).toBeVisible();
  await page.screenshot({path:'/tmp/wb-intro-skeleton.png'});
  const frames = await page.evaluate(() => new Promise<Array<{phase:string; height:number; header:number; opacity:number; scale:number; angle:number}>>(resolve => {
    const frames: Array<{phase:string; height:number; header:number; opacity:number; scale:number; angle:number}> = [];
    const sample = () => {
      const phase = document.querySelector('main')!.getAttribute('data-intro')!;
      const css = getComputedStyle(document.querySelector('.friends')!);
      const m = new DOMMatrix(css.transform);
      frames.push({phase, height:document.querySelector('.points')!.getBoundingClientRect().height,
        header:document.querySelector('.bank-header')!.getBoundingClientRect().height,
        opacity:Number(css.opacity), scale:Math.hypot(m.a,m.b), angle:Math.atan2(m.b,m.a)*180/Math.PI});
      if(phase === 'ready') resolve(frames); else requestAnimationFrame(sample);
    };
    sample();
  }));
  expect(new Set(frames.map(f=>f.phase))).toEqual(new Set(['loading','loaded','shrinking','referral','tilting','ready']));
  expect(new Set(frames.map(f=>f.header)).size).toBe(1);
  expect(frames.filter(f=>f.phase==='loaded').every(f=>f.height===116 && f.opacity===0)).toBe(true);
  expect(frames.some(f=>f.phase==='shrinking' && f.height>68 && f.height<116 && f.opacity===0)).toBe(true);
  expect(frames.some(f=>f.phase==='referral' && f.opacity>0 && f.opacity<1 && f.scale>.9 && f.scale<1 && f.angle===0)).toBe(true);
  expect(frames.filter(f=>f.phase==='tilting').every(f=>f.opacity===1 && f.height===68)).toBe(true);
  expect(frames.at(-1)!.angle).toBeCloseTo(-10,2);
  await expect(page.locator('.home-skeleton')).toHaveCount(0);
  await page.screenshot({path:'/tmp/wb-intro-ready.png'});
  await page.getByRole('button', {name:'Приглашайте друзей',exact:true}).click();
  await page.getByRole('button', {name:'Назад',exact:true}).click();
  await expect(page.locator('.empty-screen')).toHaveCount(0);
  await expect(home).toHaveAttribute('data-intro', 'ready');
  await expect(page.locator('.home-skeleton')).toHaveCount(0);
});

test('reduced motion skips shimmer and geometric introduction', async ({page}) => {
  await page.emulateMedia({reducedMotion:'reduce'});
  await page.route('**/assets/categories-mailbox.webp', async route => {
    await new Promise(resolve => setTimeout(resolve, 600));
    await route.continue();
  });
  await page.goto('/wb-test/', {waitUntil:'domcontentloaded'});
  const shimmer = page.locator('.skeleton-balance');
  expect(await shimmer.evaluate(el => getComputedStyle(el,'::after').animationName)).toBe('none');
  await expect(page.locator('main.phone')).toHaveAttribute('data-intro','ready');
  await expect(page.locator('.points')).toHaveCSS('height','68px');
  await expect(page.locator('.friends')).toHaveCSS('opacity','1');
});
