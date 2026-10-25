// Renders the 1024x500 Play Store feature graphic from feature_graphic.html.
// Needs Node with Playwright and network access for the Fredoka font:
//   node tool/store/render_feature_graphic.js assets/play-store/feature-graphic.png
//   node tool/store/render_feature_graphic.js assets/play-store/feature-graphic-es.png "Cuenta cada pieza, bate tu récord"
const { chromium } = require('playwright');
const path = require('path');

const [out, tag] = process.argv.slice(2);
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  const query = tag ? `?tag=${encodeURIComponent(tag)}` : '';
  await page.goto(`file://${path.join(__dirname, 'feature_graphic.html')}${query}`);
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: out });
  await browser.close();
})();
