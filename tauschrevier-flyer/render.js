const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  for (const [v,h] of [['feed',1350],['story',1920]]) {
    const p = await b.newPage({ viewport: { width: 1080, height: h }, deviceScaleFactor: 1 });
    await p.goto('file://' + __dirname + '/flyer.html?v=' + v);
    await p.evaluate(() => document.fonts.ready);
    await p.waitForTimeout(300);
    await p.screenshot({ path: `tauschrevier-${v}.png` });
  }
  await b.close();
})();
