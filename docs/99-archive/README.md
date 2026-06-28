# 测试项目归档说明

**版本**: v0.1
**日期**: 2026-06-29
**作者**: PM（主 Agent）

---

## 归档背景

在 2026-06-25 ~ 2026-06-28 期间，我们用**五子棋**和**围棋**作为测试项目，验证 OpenClaw 三 Agent 团队（PM + dev + qa）的工作流、提交规范、问题跟踪流程。

**测试目标**（全部达成 ✅）：
- ✅ 验证 dev Agent 能独立完成代码任务
- ✅ 验证 qa Agent 能独立完成测试 + 复测
- ✅ 验证 PM 能协调两个 Agent 派任务
- ✅ 验证 Git 提交规范（feat/fix/docs + 原子化）
- ✅ 验证问题管理表（issue-tracker.md）流程
- ✅ 验证真实浏览器集成测试（dev Agent 跑通 Playwright）

## 归档内容

| 原始路径 | 归档路径 | 说明 |
|---|---|---|
| `go-game/qa-report-v102.md` | `docs/99-archive/go-game-v1.0.2-qa-report.md` | 围棋 v1.0.2 最终 QA 测试报告 |
| `go-game/browser_integration_report.json` | `docs/99-archive/go-game-v1.0.2-browser-integration.json` | 浏览器集成测试结果 |
| `gomoku/README.md` | `docs/99-archive/gomoku-README.md` | 五子棋 README |

## 不归档的内容（已删除）

- `go-game/game.js, index.html, style.css` — 最终代码（保留在 commit `251a681` 历史中可查）
- `go-game/test_*.js` — 测试脚本（保留在 commit 历史中）
- `go-game/v2_console.txt`, `reproduce.log` — 临时调试日志
- `go-game/repro_*.png` — 复现截图（临时文件）
- `gomoku/*` — 五子棋源代码（保留在 commit `e89a03f6` 历史中可查）

## 归档原因

1. **测试项目不是产品代码**：五子棋/围棋只是 Agent 协作测试，不进入 AI 旅行账本产品
2. **保持 lib/ 目录干净**：避免污染主项目代码结构
3. **历史可追溯**：所有代码都在 git commit 历史中可查（`git log --all`）
4. **专注 Phase 1**：清理后可以专注 AI 旅行账本正式开发

## 未来如需复用

如果未来需要类似测试项目，可以：
1. 从 git 历史恢复（`git checkout <commit-hash> -- go-game/`）
2. 或参考归档的 QA 报告格式（`docs/99-archive/go-game-v1.0.2-qa-report.md`）

## Bug 归档

| Bug ID | 标题 | 状态 | 详情 |
|---|---|---|---|
| BUG-001 | 围棋坐标偏移 2 格 | ✅ 已修复（v1.0.1 + v1.0.2）| commit f52ab91, 251a681 |
| BUG-002 | 浏览器缩放落子偏移 | ✅ 已修复（v1.0.2）| commit 072fb0b, 94f390a, a1d79b8 |

完整 Bug 跟踪见 [`docs/03-management/issue-tracker.md`](../03-management/issue-tracker.md)

---

*归档完成时间：2026-06-29 00:12 (Asia/Shanghai)*
*清理者：PM Agent*
