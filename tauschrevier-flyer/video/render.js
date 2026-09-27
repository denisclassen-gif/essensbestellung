// Rendert clip.html Bild für Bild (oder als Kontaktbogen) mit Playwright.
// node render.js sheet            -> Standbilder je Beat in sheet/
// node render.js frames [fps]     -> alle Bilder in frames/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const DUR = 22;
const mode = process.argv[2] || 'frames';
const FPS = +(process.argv[3] || 30);
(async () => {
  const browser = await chromium.launch();
  const url = 'file://' + path.join(__dirname, 'clip.html');
  const times = mode === 'sheet'
    ? Array.from({ length: 44 }, (_, i) => +(i * 0.5 + 0.25).toFixed(3))
    : Array.from({ length: DUR * FPS }, (_, i) => i / FPS);
  const outDir = path.join(__dirname, mode === 'sheet' ? 'sheet' : 'frames');
  fs.mkdirSync(outDir, { recursive: true });
  const WORKERS = 4;
  let next = 0;
  await Promise.all(Array.from({ length: WORKERS }, async () => {
    const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
    await page.goto(url);
    await page.evaluate(() => window.ready);
    while (next < times.length) {
      const i = next++;
      await page.evaluate(t => window.seek(t), times[i]);
      const name = mode === 'sheet' ? `s${String(i).padStart(2, '0')}.png` : `f${String(i).padStart(5, '0')}.png`;
      await page.screenshot({ path: path.join(outDir, name), type: 'png' });
      if (i % 60 === 0) console.log(mode, i, '/', times.length);
    }
  }));
  await browser.close();
})();
