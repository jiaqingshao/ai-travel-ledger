const { chromium } = require('C:\\Users\\jiaqi\\.openclaw\\workspace\\node_modules\\playwright');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: ['--no-sandbox', '--disable-dev-shm-usage']
  });
  const ctx = await browser.newContext({ viewport: { width: 420, height: 900 } });
  const page = await ctx.newPage();
  page.on('request', r => { if (r.url().includes('localhost')) console.log('[req]', r.url().substring(0, 100)); });
  page.on('response', r => { if (r.url().includes('localhost')) console.log('[res]', r.status(), r.url().substring(0, 100)); });
  page.on('console', msg => console.log('[console]', msg.type(), msg.text().substring(0, 200)));
  page.on('pageerror', err => console.log('[pageerror]', err.message.substring(0, 200)));
  await page.goto('http://localhost:8765/index.html?screen=trip_list', { waitUntil: 'load', timeout: 60000 });
  await page.waitForTimeout(15000);
  await browser.close();
})();