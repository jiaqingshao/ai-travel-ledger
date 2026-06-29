// W4 E-004 结算引擎 4 张截图
// 用 Flutter Web URL ?screen=... 路由（main.dart 已支持）
const { chromium } = require('C:\\Users\\jiaqi\\.openclaw\\workspace\\node_modules\\playwright');
const path = require('path');

const OUT_DIR = 'C:\\Users\\jiaqi\\.openclaw\\workspace\\projects\\ai-travel-ledger\\docs\\99-archive\\screenshots';
const BASE = 'http://localhost:8765/index.html';

const SCREENS = [
  { name: 'w4-trip-list',           screen: 'trip_list' },
  { name: 'w4-trip-detail',         screen: 'trip_detail' },
  { name: 'w4-settlement',          screen: 'settlement' },
  { name: 'w4-group-settlement',    screen: 'group_settlement' },
];

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: ['--no-sandbox', '--disable-dev-shm-usage']
  });
  const context = await browser.newContext({
    viewport: { width: 420, height: 900 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  for (let i = 0; i < SCREENS.length; i++) {
    const s = SCREENS[i];
    const url = `${BASE}?screen=${s.screen}`;
    console.log(`[${i+1}/${SCREENS.length}] ${s.name} → ${url}`);
    try {
      await page.goto(url, { waitUntil: 'load', timeout: 60000 });
      // 等 Flutter 真正渲染：等到 canvas 元素出现并有非空尺寸
      await page.waitForFunction(() => {
        const cv = document.querySelector('flt-glass-pane, flutter-view, canvas');
        if (!cv) return false;
        const r = cv.getBoundingClientRect();
        return r.width > 100 && r.height > 100;
      }, { timeout: 45000 }).catch(() => {});
      await page.waitForTimeout(20000); // 给 Flutter 充足时间渲染 + 路由 push
      const outPath = path.join(OUT_DIR, `${s.name}.png`);
      // 优先截 flt-glass-pane 元素（Flutter Web 的渲染根）
      const glassPane = await page.$('flt-glass-pane');
      if (glassPane) {
        await glassPane.screenshot({ path: outPath });
      } else {
        await page.screenshot({ path: outPath, fullPage: true });
      }
      console.log(`  ✓ saved: ${outPath}`);
    } catch (e) {
      console.log(`  ✗ failed: ${e.message}`);
    }
  }

  await browser.close();
  console.log('Done!');
})();
