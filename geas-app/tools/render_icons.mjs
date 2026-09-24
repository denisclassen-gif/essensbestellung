// Rendert tools/icon.svg in die benötigten PNG-Größen (einmalig, benötigt Playwright).
import { chromium } from "/opt/node22/lib/node_modules/playwright/index.mjs";
import { readFileSync } from "node:fs";
const svg = readFileSync(new URL("./icon.svg", import.meta.url), "utf8");
const targets = [
  [1024, "../ios/GEASHilfe/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"],
  [512, "../web/icon-512.png"],
  [180, "../web/icon-180.png"],
];
const browser = await chromium.launch();
for (const [size, out] of targets) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  await page.setContent(`<body style="margin:0">${svg.replace("<svg ", `<svg width="${size}" height="${size}" `)}</body>`);
  await page.screenshot({ path: new URL(out, import.meta.url).pathname, omitBackground: false });
  await page.close();
}
await browser.close();
