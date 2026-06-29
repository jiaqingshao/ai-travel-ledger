// 用 Playwright 截图 Flutter Web app
const { chromium } = require('C:\\Users\\jiaqi\\.openclaw\\workspace\\node_modules\\playwright');
const path = require('path');

const OUT_DIR = 'C:\\Users\\jiaqi\\.openclaw\\workspace\\projects\\ai-travel-ledger\\docs\\99-archive\\screenshots';

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: ['--no-sandbox', '--disable-dev-shm-usage']
  });
  const context = await browser.newContext({
    viewport: { width: 420, height: 900 },  // 移动端尺寸（Flutter 旅行账本是手机 APP）
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  console.log('[1/3] Navigating to Flutter Web app...');
  await page.goto('http://localhost:8765', { waitUntil: 'networkidle', timeout: 60000 });

  console.log('[2/3] Waiting for Flutter to render...');
  // Wait for Flutter canvas to appear
  await page.waitForSelector('flt-glass-pane, canvas, flutter-view', { timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(8000);  // Wait for Flutter to settle

  console.log('[3/3] Taking screenshots...');
  await page.screenshot({ path: `${OUT_DIR}\\flutter-trip-list.png`, fullPage: true });
  console.log('Saved: flutter-trip-list.png');

  // 尝试点击 "新建旅程" 按钮（FAB）
  try {
    // FAB 通常在右下角，坐标 (370, 820) in mobile viewport
    await page.mouse.click(370, 820);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: `${OUT_DIR}\\flutter-trip-create.png`, fullPage: true });
    console.log('Saved: flutter-trip-create.png');
  } catch (e) {
    console.log('Could not click FAB:', e.message);
  }

  await browser.close();
  console.log('Done!');
})();