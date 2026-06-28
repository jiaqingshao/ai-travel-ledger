# 📋 QA 全量回归测试报告 - v1.0.2

| 项目         | AI 旅行账本 / 围棋 (go-game) |
| ------------ | ----------------------------- |
| 测试版本     | **v1.0.2**                    |
| 对比基线     | v1.0.1（真实浏览器回归 BUG-001）|
| QA 执行时间  | 2026-06-28 21:00 (GMT+8)      |
| 测试角色     | qa (独立验证方)               |

---

## 1️⃣ 测试结果汇总表

| 测试套件                    | 用例数 | 通过 | 失败 | 通过率    | 状态 |
| --------------------------- | ------ | ---- | ---- | --------- | ---- |
| `test_qa.js` (单元)          | 30     | 30   | 0    | 100.0%    | 🟢   |
| `test_qa_v2.js` (round-trip) | 15     | 15   | 0    | 100.0%    | 🟢   |
| `test_qa_v101.js` (NaN 防御) | 12     | 12   | 0    | 100.0%    | 🟢   |
| **`test_browser_integration.js`** (Playwright) | **350** | **350** | **0** | **100.0%** | 🟢 |
| **总计**                    | **407** | **407** | **0** | **100.0%** | **🟢** |

> **独立验证结论：407/407 全通过 ✅**

---

## 2️⃣ v1.0.2 新增：浏览器集成测试（关键修复证据）

### 2.1 测试设计

`test_browser_integration.js` 使用 **真实 Chromium 浏览器**（Playwright 1.61 驱动），
模拟用户点击事件 (`page.mouse.click`)，验证 `window.__goGame.state.board` 的实际落点
是否与点击的棋盘交点匹配。

**测试覆盖**：
- **12 个 viewport 场景**：1280x800, 1440x900, 1024x768, 1366x768, 900x700, 768x1024,
  700x900, 414x800, 375x667, 320x568, 1280x800@DPR=2, 1280x800@DPR=1.25
- **3 种棋盘规格**：19 路、13 路、9 路
- **每个场景的 5x5 等距交点**：cell 中心 = `padding + (size-1)*i/4 * cell`
- **窗口缩放响应测试**：每个场景再 setViewportSize(800x600) 验证 ResizeObserver/syncCanvasSize 工作

**关键不变式验证（v1.0.2 新增）**：
```js
canvas.width === canvas.clientWidth === rect.width    // scaleX 必须 = 1.000
canvas.height === canvas.clientHeight === rect.height  // scaleY 必须 = 1.000
```

### 2.2 关键测试场景输出（节选）

```
[1. 桌面标准 1280x800] viewport=1280x800 dpr=1
  19路: canvas=760x760 rect=760x760 scaleX=1.000 padding=28.00 cell=39.111
    ✅ 20/20 通过
  13路: canvas=760x760 rect=760x760 scaleX=1.000 padding=28.00 cell=58.667
    ✅ 20/20 通过
  9路: canvas=760x760 rect=760x760 scaleX=1.000 padding=28.00 cell=88.000
    ✅ 20/20 通过

[3. 桌面紧凑 1024x768] viewport=1024x768 dpr=1
  19路: canvas=642x642 rect=642x642 scaleX=1.000 padding=28.00 cell=32.556
    ✅ 25/25 通过   ← 响应式：canvas 自动缩到 642
  缩放后 (800x600): canvas=716x716 scaleX=1.000   ← ResizeObserver 触发同步

[6. 平板竖屏 768x1024] viewport=768x1024 dpr=1
  19路: canvas=684x684 rect=684x684 scaleX=1.000 padding=28.00 cell=34.889
    ✅ 25/25 通过

[8. 移动端 414x800]
  19路: canvas=330x330 rect=330x330 scaleX=1.000 padding=28.00 cell=15.222
    ✅ 25/25 通过   ← 响应式：canvas 自动缩到 330

[9. 移动端 iPhone 375x667]
  19路: canvas=291x291 rect=291x291 scaleX=1.000 padding=28.00 cell=13.056
    ✅ 25/25 通过   ← 响应式：canvas 自动缩到 291

[11. HiDPI (DPR=2) 1280x800]
  19路: canvas=760x760 rect=760x760 scaleX=1.000 padding=28.00 cell=39.111
    ✅ 20/20 通过   ← 高 DPI 下仍正确

总点数: 350 | 通过: 350 | 失败: 0 | 通过率: 100.00%
```

### 2.3 修复前后对比

| 场景                   | v1.0.1 (测试通过但用户报 bug)  | v1.0.2 (集成测试 100% 通过) |
| ---------------------- | ------------------------------- | ---------------------------- |
| 1024x768 canvas 尺寸  | 642x642 (CSS) / 760x760 (内部) | **642x642 (CSS) / 642x642 (内部)** ✅ |
| 1024x768 scaleX        | 760/642 = **1.184** ❌          | **1.000** ✅                  |
| 375x667 canvas 尺寸    | 760x760 (溢出 viewport!)        | **291x291** ✅                |
| 用户点击 cell 9 → 落点 | 实际落 cell 11 (+2!) ❌         | **落 cell 9 (精确)** ✅       |
| 窗口缩放后             | scaleX 变化、点击偏移 ❌         | ResizeObserver 同步、scaleX=1 ✅ |

---

## 3️⃣ 版本号验证

| 文件           | 行号       | 实际值                       | 期望值                | 结果 |
| -------------- | ---------- | ---------------------------- | --------------------- | ---- |
| `game.js`      | 29         | `const VERSION = "v1.0.2";`  | `v1.0.2`              | ✅    |
| `index.html`   | 38         | `│    版  本：v1.0.2    ...`  | 中央信息显示 `v1.0.2` | ✅    |
| v1.0.1 残留    | -          | 仅在 game.js CHANGELOG 注释  | 仅允许在历史注释      | ✅    |

**版本升级生效 ✅**

---

## 4️⃣ 修复根因清单（v1.0.2 BUG-001 真实浏览器回归）

| #   | 根因                                                         | 修复                                                       |
| --- | ------------------------------------------------------------ | ---------------------------------------------------------- |
| 1   | `aspect-ratio: 1/1` + `width: 100%` + `height: auto` + `max-width: 760px` 组合下，canvas CSS 盒高度被回退到固有 760，导致 canvas CSS ≠ canvas.width，scaleX > 1 | 删除 `aspect-ratio`，新增 `syncCanvasSize()` 在 `newBoard / resize / ResizeObserver / fonts.ready` 触发时**显式设置 canvas.style.width = canvas.style.height = 760（响应式封顶）** |
| 2   | `.dev-overlay <pre>` 默认 `pointer-events: auto`（不继承），在棋盘上方覆盖一块，click 被 pre 拦截 | CSS `pointer-events: none` + `user-select: none` 显式继承到 pre  |
| 3   | `.board-wrap` 没有 `position: relative`，`.dev-overlay` 错位到 `.app` 覆盖整个 app | CSS `.board-wrap { position: relative; }`                  |
| 4   | `.hover-stone` 用 `transform: translate(-50%, -50%)` 但 JS 计算时减了 `canvas.rect.left`，导致 hover-stone 视觉位置相对鼠标偏移 ~14px | 移除 `transform: translate(-50%)`，JS 直接写 `hover.left = mouse - board-shadow.rect.left - 14`  |
| 5   | `eventToCell` 仅用 `clientX/Y - rect.left`，纯函数测试通过但真实浏览器某些 DPR / 字体加载 / 缩放下 rect 不稳定 | 增加 `evt.offsetX/offsetY` 优先路径 + 三重 fallback       |
| 6   | 缺少 ResizeObserver / window resize / 字体加载监听，棋盘尺寸变化后 canvas.width 与 clientWidth 不一致但未同步 | 新增 `requestSyncCanvasSize()` + ResizeObserver + window resize + orientationchange + document.fonts.ready 多重触发 |

**关键不变式（v1.0.2）**：
```js
canvas.width === canvas.clientWidth === canvas.getBoundingClientRect().width
=> scaleX = canvas.width / rect.width === 1.000
```

---

## 5️⃣ 关键日志

### 5.1 `test_qa.js`（30 个 BUG-001 用例）

```
总数: 30 | 通过: 30 | 失败: 0 | 通过率: 100.0%
📌 结论: 🟢 全部通过
```

### 5.2 `test_qa_v2.js`（15 个 round-trip 用例）

```
QA 结论: PASS | 15/15 通过
```

### 5.3 `test_qa_v101.js`（12 个 NaN/异常输入防御用例）

```
v1.0.1 防御性测试: PASS | 12/12 通过
```

### 5.4 `test_browser_integration.js`（350 个真实点击用例）

```
📊 浏览器集成测试结果
  场景数: 12
  点击数: 350
  通过:   350
  失败:   0
  通过率: 100.00%
✅ v1.0.2 浏览器集成测试: PASS
```

---

## 6️⃣ 质量门禁结论

| 门禁项                       | 要求                       | 实际                          | 结果 |
| ---------------------------- | -------------------------- | ----------------------------- | ---- |
| BUG-001 回归 (30)            | 30/30 PASS                 | 30/30 PASS                    | ✅    |
| Round-trip (15)              | 15/15 PASS                 | 15/15 PASS                    | ✅    |
| NaN 防御 (12)                | 12/12 PASS                 | 12/12 PASS                    | ✅    |
| **真实浏览器集成 (350)**      | **100% PASS**              | **350/350 PASS**              | ✅    |
| 总通过率                     | 100%                       | **407/407 = 100.0%**          | ✅    |
| 版本号 game.js               | `VERSION = "v1.0.2"`       | 已生效                        | ✅    |
| 版本号 index.html            | 中央显示 v1.0.2            | 已生效                        | ✅    |
| v1.0.1 残留                  | 仅允许在历史注释           | 符合                          | ✅    |
| 不变式 scaleX=1              | 所有场景                   | 全部 1.000                    | ✅    |
| 响应式断点                   | 320x568 → 1440x900         | canvas 始终正方形且 click 准确 | ✅    |

### 🟢 **QA 终判：PASS ✅**

- 无 P0 / P1 bug
- 无失败用例
- 真实浏览器 + 数学双重验证一致（407/407）
- v1.0.2 修复了 v1.0.1 在真实浏览器中未覆盖的 6 个根因

---

## 7️⃣ 备注 / 风险提示

1. **Playwright Chromium 版本**：测试使用本地已有的 `chromium-1223`（Playwright 1.61 兼容）。
   如未来升级 Playwright，需要 `npx playwright install chromium-headless-shell` 重新拉取匹配版本。

2. **`test_browser_integration.js` 需要 Playwright 依赖**：
   ```bash
   npm install playwright --no-save
   npx playwright install chromium-headless-shell
   ```
   安装 Playwright 时网络下载可能失败，本环境已缓存 `chromium-1223`。

3. **建议 CI/CD 接入**：将 `test_browser_integration.js` 加入 CI 流水线，作为真实浏览器回归门禁。

---

**QA Agent 签字：qa-v102-browser-regression**
**报告生成时间：2026-06-28 21:00 GMT+8**
**报告路径：`projects/ai-travel-ledger/go-game/qa-report-v102.md`**
