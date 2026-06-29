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
  console.log('--- page loaded, waiting 30s ---');
  await page.waitForTimeout(30000);
  // 检查 Flutter 是否渲染
  const info = await page.evaluate(() => {
    const cv = document.querySelector('flt-glass-pane');
    const allCanvases = document.querySelectorAll('canvas');
    return {
      hasGlassPane: !!cv,
      glassPaneHTML: cv ? cv.outerHTML.substring(0, 200) : null,
      canvasCount: allCanvases.length,
      firstCanvas: allCanvases[0] ? {
        w: allCanvases[0].width,
        h: allCanvases[0].height,
        clientW: allCanvases[0].clientWidth,
        clientH: allCanvases[0].clientHeight,
      } : null,
      bodyText: document.body.innerText.substring(0, 200),
    };
  });
  console.log('--- page state ---');
  console.log(JSON.stringify(info, null, 2));
  await browser.close();
})();