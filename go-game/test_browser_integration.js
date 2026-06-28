// =====================================================================
// v1.0.2 BUG-001 浏览器集成测试 (Playwright)
//
// 测试目标：
//   1) 真实 Chromium 渲染 index.html
//   2) page.mouse.click(x, y) 触发真实 DOM click 事件
//   3) 验证 window.__goGame.state.lastMove 与点击位置一致
//   4) 覆盖 19/13/9 路 × 多种 viewport 尺寸
//   5) 覆盖窗口缩放、棋盘大小切换、响应式断点
//
// 测试通过标准：
//   - 所有点击都必须落在预期的网格交点上
//   - scaleX 和 scaleY 必须都等于 1.0（保证 canvas.width === rect.width）
//   - 任何点击位置偏移 > 0.5 格都会标记为 FAIL
// =====================================================================

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const INDEX_HTML = 'file:///' + path.resolve(__dirname, 'index.html').replace(/\\/g, '/');
const chromePath = process.env.LOCALAPPDATA + '\\ms-playwright\\chromium-1223\\chrome-win64\\chrome.exe';

// 验证 v1.0.2 关键不变式
function assertInvariants(canvasInfo, label) {
  const errs = [];
  if (Math.abs(canvasInfo.canvasWidth - canvasInfo.rectWidth) > 1) {
    errs.push(`canvas.width (${canvasInfo.canvasWidth}) != rect.width (${canvasInfo.rectWidth})`);
  }
  if (Math.abs(canvasInfo.canvasHeight - canvasInfo.rectHeight) > 1) {
    errs.push(`canvas.height (${canvasInfo.canvasHeight}) != rect.height (${canvasInfo.rectHeight})`);
  }
  if (Math.abs(canvasInfo.scaleX - 1) > 0.001) {
    errs.push(`scaleX=${canvasInfo.scaleX.toFixed(4)} != 1.0`);
  }
  if (Math.abs(canvasInfo.scaleY - 1) > 0.001) {
    errs.push(`scaleY=${canvasInfo.scaleY.toFixed(4)} != 1.0`);
  }
  return errs;
}

// 计算交点的 viewport 坐标
function gridToViewport(canvasInfo, gx, gy) {
  const { canvasWidth, padding, cell } = canvasInfo;
  const px = padding + gx * cell;
  const py = padding + gy * cell;
  // canvas CSS 尺寸 = canvasWidth（保证的不变式），viewport 坐标 = rect.left + px
  return { x: canvasInfo.rectLeft + px, y: canvasInfo.rectTop + py };
}

// 收集 canvas 状态（来自 game.js 暴露的 window.__goGame）
async function readCanvasInfo(page) {
  return await page.evaluate(() => {
    const info = window.__goGame.getCanvasInfo();
    const { cell, padding } = (function () {
      const c = document.getElementById('board');
      const W = c.width;
      const size = window.__goGame.state.size;
      const cell = (W - 56) / (size - 1);
      const padding = (W - cell * (size - 1)) / 2;
      return { cell, padding };
    })();
    return { ...info, cell, padding, size: window.__goGame.state.size };
  });
}

// 在 5x5 等距网格上点击
async function runGridClicks(page, info, points) {
  const results = [];
  for (const [gx, gy] of points) {
    const v = gridToViewport(info, gx, gy);
    if (v.x < 0 || v.y < 0 || v.x > info.viewportW || v.y > info.viewportH) {
      results.push({ gx, gy, skipped: true });
      continue;
    }
    // 重置棋局以避免 lastMove 复用旧值
    await page.evaluate(() => {
      window.__goGame.newBoard(window.__goGame.state.size);
    });
    await page.mouse.click(v.x, v.y);
    await page.waitForTimeout(20);
    // 检查点击位置是否落在了预期的格子上
    const result = await page.evaluate(({ gx, gy }) => {
      const cell = window.__goGame.state.board[gy][gx];
      const last = window.__goGame.state.lastMove;
      return { cell, last };
    }, { gx, gy });
    const ok = result.cell !== 0 && result.last && result.last.x === gx && result.last.y === gy;
    results.push({ gx, gy, clickX: v.x, clickY: v.y, cell: result.cell, last: result.last, ok });
  }
  return results;
}

async function main() {
  console.log('='.repeat(78));
  console.log('🐛 v1.0.2 BUG-001 浏览器集成测试 (Playwright)');
  console.log('='.repeat(78));
  console.log('Node:', process.version, '| Chromium:', chromePath.split('\\').pop());
  console.log('');

  const browser = await chromium.launch({ headless: true, executablePath: chromePath });

  // 测试场景列表
  const scenarios = [
    { label: '1. 桌面标准 1280x800',          viewport: { width: 1280, height: 800 },  sizes: [19, 13, 9] },
    { label: '2. 桌面宽屏 1440x900',          viewport: { width: 1440, height: 900 },  sizes: [19] },
    { label: '3. 桌面紧凑 1024x768',          viewport: { width: 1024, height: 768 },  sizes: [19] },
    { label: '4. 笔记本 1366x768',            viewport: { width: 1366, height: 768 },  sizes: [19] },
    { label: '5. 中等窗口 900x700',           viewport: { width: 900,  height: 700 },  sizes: [19] },
    { label: '6. 平板竖屏 768x1024',          viewport: { width: 768,  height: 1024 }, sizes: [19] },
    { label: '7. 平板横屏 700x900',           viewport: { width: 700,  height: 900 },  sizes: [19] },
    { label: '8. 移动端 414x800',             viewport: { width: 414,  height: 800 },  sizes: [19] },
    { label: '9. 移动端 iPhone 375x667',      viewport: { width: 375,  height: 667 },  sizes: [19] },
    { label: '10. 移动端紧凑 320x568',        viewport: { width: 320,  height: 568 },  sizes: [19] },
    { label: '11. HiDPI (DPR=2) 1280x800',    viewport: { width: 1280, height: 800 },  sizes: [19], dpr: 2 },
    { label: '12. 1.25× DPR 模拟缩放',         viewport: { width: 1280, height: 800 },  sizes: [19], dpr: 1.25 },
  ];

  let totalPass = 0, totalFail = 0, totalClick = 0;
  const failureDetails = [];

  for (const sc of scenarios) {
    console.log(`\n[${sc.label}] viewport=${sc.viewport.width}x${sc.viewport.height} dpr=${sc.dpr || 1}`);
    const ctx = await browser.newContext({
      viewport: sc.viewport,
      deviceScaleFactor: sc.dpr || 1,
    });
    const page = await ctx.newPage();
    await page.goto(INDEX_HTML);
    await page.waitForFunction(() => window.__goGame && window.__goGame.state && window.__goGame.getCanvasInfo);
    // 等 layout 稳定
    await page.waitForTimeout(100);

    for (const sz of sc.sizes) {
      await page.evaluate((s) => {
        window.__goGame.newBoard(s);
        window.__goGame.syncCanvasSize();
      }, sz);
      await page.waitForTimeout(50);

      const info = await readCanvasInfo(page);
      info.viewportW = sc.viewport.width;
      info.viewportH = sc.viewport.height;

      // 验证 v1.0.2 不变式
      const errs = assertInvariants(info, sc.label);
      if (errs.length) {
        console.log(`  ❌ ${sz}路 - 不变式违反:`);
        errs.forEach(e => console.log(`     - ${e}`));
        totalFail += errs.length;
      }

      console.log(`  ${sz}路: canvas=${info.canvasWidth}x${info.canvasHeight} rect=${info.rectWidth}x${info.rectHeight} scaleX=${info.scaleX.toFixed(3)} padding=${info.padding.toFixed(2)} cell=${info.cell.toFixed(3)}`);

      // 5x5 等距测试点（仅取 viewport 内可见的）
      const points = [];
      for (let i = 0; i < 5; i++) {
        const idx = Math.round((sz - 1) * i / 4);
        for (let j = 0; j < 5; j++) {
          const idy = Math.round((sz - 1) * j / 4);
          points.push([idx, idy]);
        }
      }

      const results = await runGridClicks(page, info, points);
      let p = 0, f = 0;
      for (const r of results) {
        if (r.skipped) continue;
        totalClick++;
        if (r.ok) { p++; totalPass++; }
        else { f++; totalFail++; if (failureDetails.length < 20) failureDetails.push({ scenario: sc.label, size: sz, ...r }); }
      }
      const status = f === 0 ? '✅' : '❌';
      console.log(`    ${status} ${p}/${p + f} 通过`);
    }

    // 额外测试：窗口缩放响应（resizing the viewport）
    if (sc.sizes.includes(19)) {
      console.log(`  -- 缩放响应测试 (window resize) --`);
      await page.setViewportSize({ width: 800, height: 600 });
      await page.waitForTimeout(100);
      const info1 = await readCanvasInfo(page);
      info1.viewportW = 800; info1.viewportH = 600;
      const errs1 = assertInvariants(info1, sc.label + ' 缩放后');
      if (errs1.length) {
        console.log(`    ❌ 800x600 缩放后不变式违反:`);
        errs1.forEach(e => console.log(`       - ${e}`));
        totalFail += errs1.length;
      } else {
        console.log(`    ✅ 800x600 缩放后: canvas=${info1.canvasWidth}x${info1.canvasHeight} scaleX=${info1.scaleX.toFixed(3)}`);
      }
      const points1 = [[0, 0], [4, 4], [9, 9], [14, 14]];
      const r1 = await runGridClicks(page, info1, points1);
      for (const r of r1) {
        if (r.skipped) continue;
        totalClick++;
        if (r.ok) totalPass++; else { totalFail++; failureDetails.push({ scenario: sc.label + ' 缩放后', size: 19, ...r }); }
      }

      // 还原
      await page.setViewportSize(sc.viewport);
      await page.waitForTimeout(100);
    }

    await ctx.close();
  }

  await browser.close();

  console.log('\n' + '='.repeat(78));
  console.log('📊 浏览器集成测试结果');
  console.log('='.repeat(78));
  console.log(`  场景数: ${scenarios.length}`);
  console.log(`  点击数: ${totalClick}`);
  console.log(`  通过:   ${totalPass}`);
  console.log(`  失败:   ${totalFail}`);
  console.log(`  通过率: ${totalClick === 0 ? 'N/A' : ((totalPass / totalClick) * 100).toFixed(2) + '%'}`);

  if (failureDetails.length) {
    console.log('\n  失败详情（前 20）:');
    failureDetails.slice(0, 20).forEach((f, i) => {
      console.log(`    ${i + 1}. [${f.scenario}] ${f.size}路 gx=${f.gx} gy=${f.gy} click=(${f.clickX?.toFixed(1)},${f.clickY?.toFixed(1)}) -> lastMove=${f.last ? `(${f.last.x},${f.last.y})` : 'null'}`);
    });
  }

  console.log('='.repeat(78));
  if (totalFail === 0 && totalPass > 0) {
    console.log('✅ v1.0.2 浏览器集成测试: PASS');
  } else {
    console.log('❌ v1.0.2 浏览器集成测试: FAIL');
  }
  console.log('='.repeat(78));

  // 输出 JSON 报告
  const report = {
    version: 'v1.0.2',
    timestamp: new Date().toISOString(),
    totalScenarios: scenarios.length,
    totalClicks: totalClick,
    passed: totalPass,
    failed: totalFail,
    passRate: totalClick === 0 ? 0 : totalPass / totalClick,
    failures: failureDetails,
  };
  fs.writeFileSync(path.join(__dirname, 'browser_integration_report.json'), JSON.stringify(report, null, 2));
  console.log('详细报告: browser_integration_report.json');

  process.exit(totalFail === 0 ? 0 : 1);
}

main().catch(err => {
  console.error('FATAL:', err);
  process.exit(1);
});
