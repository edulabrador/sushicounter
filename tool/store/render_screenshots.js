// Play Store phone screenshots (1080x1920) of the design preview.
// 1. flutter build web -t tool/design_preview.dart --no-web-resources-cdn
// 2. Serve build/web on port 8765 (python3 -m http.server 8765)
// 3. node tool/store/render_screenshots.js assets/play-store/screenshots/en en-US
//    node tool/store/render_screenshots.js assets/play-store/screenshots/es es-ES
const { chromium } = require('playwright');
const [out, locale] = process.argv.slice(2);
const W = 360, H = 640;
(async () => {
  const browser = await chromium.launch();
  const open = async (query) => {
    const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3, locale });
    await page.goto(`http://localhost:8765/?${query}`); await page.waitForTimeout(4500); return page;
  };
  const tab = async (p, i) => { await p.mouse.click(W / 6 * (2 * i + 1), H - 40); await p.waitForTimeout(1500); };
  let p = await open('count=17');
  await p.screenshot({ path: `${out}/1-counter.png` }); await p.close();
  p = await open(''); await tab(p, 1);
  await p.screenshot({ path: `${out}/2-history.png` }); await p.close();
  p = await open(''); await tab(p, 2);
  await p.screenshot({ path: `${out}/3-stats.png` });
  await p.mouse.move(6, 320);
  // Scroll to the bottom: keep wheeling until the page stops changing.
  let last = null;
  for (let i = 0; i < 40; i++) {
    for (let j = 0; j < 5; j++) { await p.mouse.wheel(0, 100); await p.waitForTimeout(120); }
    await p.waitForTimeout(600);
    const shot = (await p.screenshot()).toString('base64');
    if (shot === last) break; last = shot;
  }
  await p.waitForTimeout(800);
  for (let i = 0; i < 3; i++) { await p.mouse.wheel(0, -100); await p.waitForTimeout(300); }
  await p.waitForTimeout(1500);
  await p.screenshot({ path: `${out}/4-achievements.png` }); await p.close();
  p = await open('count=17&appearance=light');
  await p.screenshot({ path: `${out}/5-light.png` }); await p.close();
  await browser.close();
})();
