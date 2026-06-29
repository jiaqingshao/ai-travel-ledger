const { chromium } = require('C:\\Users\\jiaqi\\.openclaw\\workspace\\node_modules\\playwright');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: ['--no-sandbox', '--disable-dev-shm-usage']
  });
  const ctx = await browser.newContext({ viewport: { width: 420, height: 900 } });
  const page = await ctx.newPage();
  page.on('console', msg => console.log('[console]', msg.type(), msg.text()));
  page.on('pageerror', err => console.log('[pageerror]', err.message));
  await page.goto('http://localhost:8765/index.html?screen=trip_list', { waitUntil: 'load', timeout: 60000 });
  for (let i = 0; i < 6; i++) {
    await page.waitForTimeout(10000);
    const info = await page.evaluate(() => ({
      hasGlassPane: !!document.querySelector('flt-glass-pane'),
      canvasCount: document.querySelectorAll('canvas').length,
      flutterView: !!document.querySelector('flutter-view'),
      flutterReady: !!window._flutter_loader || !!window.flutterCanvasKit,
    }));
    console.log(`t=${(i+1)*10}s:`, JSON.stringify(info));
    if (info.hasGlassPane) break;
  }
  await browser.close();
})();