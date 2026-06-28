# AI 旅行账本 - 问题管理表(Issue Tracker)

**版本**: v0.1
**日期**: 2026-06-28
**作者**: PM(主 Agent)
**状态**: 启用

**变更历史**:
| 日期 | 变更内容 | 变更人 |
|---|---|---|
| 2026-06-28 | 初始版本(汇总 BUG-001/002 + 已知问题)| PM |

---

## 一、问题统计

| 等级 | 总数 | 已修复 | 进行中 | 待修复 |
|---|---|---|---|---|
| **P0 致命** | 0 | 0 | 0 | 0 |
| **P1 严重** | 3 | 2 | 1 | 0 |
| **P2 一般** | 5 | 1 | 1 | 3 |
| **P3 轻微** | 2 | 0 | 0 | 2 |
| **总计** | **10** | **3** | **2** | **5** |

**最近重要里程碑**：
- 🎯 **2026-06-28 21:32** dev Agent 完成真实浏览器集成测试 + 6 大根因修复（commit 251a681），407/407 PASS
- 🗂️ **2026-06-29 00:12** 测试项目（围棋/五子棋）归档完成 → `docs/99-archive/`；BUG-001/002 标记为“已归档”
- 🛡️ **2026-06-29 00:22** ISSUE-010 记录 PM 误判 subagent 状态被 kill；补充防误判规则到 PM SOUL.md

---

---

## 二、问题清单(按时间倒序)

### ✅ BUG-002 - 浏览器缩放下五子棋落子偏移【已归档】

| 字段 | 值 |
|---|---|
| **Bug ID** | BUG-002 |
| **等级** | P1 严重 |
| **模块** | go-game(围棋)| 🗂️ 已归档 |
| **报告时间** | 2026-06-28 21:05 |
| **报告人** | 用户(实测)|
| **修复时间** | 2026-06-28 21:32 |
| **修复人** | PM(主修) + dev Agent(真实浏览器集成测试 + 6 大根因修复)|
| **状态** | ✅ 已修复 + 🗂️ 已归档(2026-06-29)|
| **Commit** | `072fb0b`(PM 相对位置算法)+ `a1d79b8` + `94f390a`(lockCanvasSize 辅助)+ `251a681`(dev 真实浏览器集成测试 + 6 大根因修复 v1.0.2)|
| **归档位置** | QA 报告 → `docs/99-archive/go-game-v1.0.2-qa-report.md` |

**PM 修复**:
- 改用**相对位置 × 逻辑尺寸**算法:`relX = (clientX - rect.left) / rect.width; px = relX * canvas.width`
- 保留 `lockCanvasSize()` 作为防御性辅助
- 版本 v1.0.1 → v1.0.2
- Node 模拟 100%/125%/90%/75%/50% zoom PASS

**dev Agent 集成测试 + 修复**(commit 251a681):
1. CSS aspect-ratio 在某些 Chromium 被忽略 → 删 aspect-ratio,JS syncCanvasSize() 强锁尺寸
2. `.dev-overlay <pre>` 拦截 click → pointer-events: none
3. `.board-wrap` 缺 position: relative → 补上
4. `.hover-stone` 视觉偏移 ~14px → 移 transform,手算 left/top
5. eventToCell 改用 offsetX/offsetY 优先 + 三重 fallback
6. 新增 ResizeObserver + window resize + orientationchange + fonts.ready 多重监听

**dev Agent 测试覆盖**:407/407 = 100% PASS
- test_qa.js: 30/30
- test_qa_v2.js: 15/15
- test_qa_v101.js: 12/12
- test_browser_integration.js (Playwright 真实 Chromium): 350/350

**用户验收**:✅ 用户实测确认修复(2026-06-29)

---

### ✅ BUG-001 - 五子棋坐标偏移 2 格【已归档】

| 字段 | 值 |
|---|---|
| **Bug ID** | BUG-001 |
| **等级** | P1 严重 |
| **模块** | go-game / gomoku(五子棋/围棋)| 🗂️ 已归档 |
| **报告时间** | 2026-06-28 01:00 |
| **报告人** | 用户 |
| **修复时间** | 2026-06-28 01:05 (PM commit) / 16:29 (dev commit f52ab91) |
| **修复人** | dev Agent + PM |
| **状态** | ✅ 已修复 + 🗂️ 已归档(2026-06-29)|
| **Commit** | `78184a6`(PM 初次 commit)+ `f52ab91`(dev 强化版)|

**根因**:
`getCellMetrics()` 中 `padding = 28` 硬编码居中,CSS 缩放时画布居中失效。`eventToCell` 缺乏防御性检查。

**修复方案**:
- 改为 `padding = (W - cell*(size-1)) / 2` 自适应居中
- `eventToCell` 增加 `rect.width===0` 防御性检查
- 新增 `touchstart` 触屏事件支持
- 版本 v1.0.0 → v1.0.1

**验证**:
- dev Agent 验证(4 项):A10 往返精度、四角坐标、6 种宽度、吸附半径 ✅
- qa Agent 复测(15 项):W=760/W=800、13路/9路、边界值、居中验证 ✅

---

### 🔧 ISSUE-003 - Gateway 重启失败

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-003 |
| **等级** | P1 严重 |
| **模块** | OpenClaw 基础设施 |
| **报告时间** | 2026-06-26(首次发现)|
| **报告人** | 用户(多次报告"重启没成功,我都手动帮助你的")|
| **当前状态** | 🔧 进行中(用户手动重启绕过)|

**症状**:
- `npx openclaw` 重启命令失败
- Gateway 是通过 Scheduled Task 注册的,但实际由 node 进程直接运行
- 用户多次反馈"一样失败"

**根因分析**:
- Scheduled Task 模式与 node 进程直接运行存在不一致
- 重启信号可能未正确传递

**临时方案**:用户手动重启 Gateway(PID 9128 → 19048 → 现在又变 9128)

**永久方案**:⏳ 待研究,可能需要修改 Scheduled Task 或重启脚本

---

### ⏳ ISSUE-004 - 企业微信文件发送失败(错误码 93006)

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-004 |
| **等级** | P2 一般 |
| **模块** | 企业微信集成 |
| **报告时间** | 2026-06-26 |
| **报告人** | 用户 |

**症状**:
- 通过企业微信发送文件失败
- 错误码 93006 = `invalid chatid`
- 需要明确 target(聊天对象)

**当前状态**:⏳ 未开始修复

**可能方案**:
- 在 OpenClaw UI 中选择具体聊天对象
- 配置默认 target
- 联系企业微信 API 文档确认 93006 含义

---

### ⏳ ISSUE-005 - GitHub 远程仓库未创建

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-005 |
| **等级** | P2 一般 |
| **模块** | DevOps |
| **报告时间** | 2026-06-25 |
| **报告人** | PM |

**症状**:
- 代码无法 push 到 GitHub 备份
- 当前 8 个 commit 都在本地 main 分支
- 多端协作受阻

**当前状态**:⏳ 等待用户在 github.com 创建 `ai-travel-ledger` 空仓库并提供 URL

**影响**:
- 代码备份风险
- 团队协作无法开始
- 阻塞 Phase 1 正式开发

---

### ⏳ ISSUE-006 - context_token 用量高(91k/262k = 35%)

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-006 |
| **等级** | P2 一般 |
| **模块** | OpenClaw 运行时 |
| **报告时间** | 2026-06-26 |
| **报告人** | 系统报告 |

**症状**:
- 会话上下文用量已达 91k/262k(35%)
- 4 次压缩历史

**当前状态**:⏳ 用户未确认是否需要优化

**可能方案**:
- 缩短 memory_search 结果
- 增加 compaction 频率
- 清理无用上下文

---

### ⏳ ISSUE-007 - 五子棋 Dev Agent 卡死(LLM API 超时)

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-007 |
| **等级** | P2 一般 |
| **模块** | AI 模型调用 |
| **报告时间** | 2026-06-28 21:14 |
| **报告人** | PM 监控 |

**症状**:
- dev Agent 调用 MiniMax M3 时长时间 hang
- 子进程 CPU 占用低(idle 状态),但 LLM API 无响应
- 会话停滞 3+ 分钟

**影响**:
- BUG-002 第一次修复尝试失败
- 后续任务分配可能受影响

**可能方案**:
- 设置 LLM API 调用 timeout(如 60 秒)
- dev Agent 默认 fallback 到 Qwen3.6 35B 本地模型
- 重要修复可由 PM 直修(已实践)

---

### ⏳ ISSUE-008 - qa Agent message 工具卡死

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-008 |
| **等级** | P2 一般 |
| **模块** | AI Agent 工具 |
| **报告时间** | 2026-06-28 01:44 |
| **报告人** | PM 监控 |

**症状**:
- qa Agent 完成任务后调用 `message` 工具
- `Action send requires a target` 错误
- Agent 不知道汇报给谁,停滞等待

**影响**:
- qa 报告无法自动送达 PM

**可能方案**:
- 在 OpenClaw 文档中明确 Agent 汇报规范
- 给 Agent 配置默认 target
- 或让 Agent 用 file_write + 日报 cron 自动归档

---

### ✅ ISSUE-010 — PM 误判 subagent 状态而 kill dev【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-010 |
| **等级** | P2 一般 |
| **模块** | PM Agent 进程管理 |
| **报告时间** | 2026-06-29 00:19 |
| **报告人** | 用户提醒 + PM 自报 |
| **修复时间** | 2026-06-29 00:22 |
| **修复人** | PM |
| **状态** | ✅ 已修复（cron 重试已安排 + PM SOUL.md 防误判规则已补）|

**症状**：
- W1 E-001 dev subagent 派单后跑 2 小时
- PM 检查发现 PID 5448 CPU 仅 2.3%（158s/6780s）、内存 530MB
- 读取 git log 发现 dev 只做了 housekeeping（归档 go-game + 微调数据模型）
- PM 主观判断“dev 走岔路”，主动 `kill` 了 PID 5448
- 用户随后提醒：M3 5h 配额已用完，dev 是在撞限等待 retry，不是走岔路
- **PM 违反了自己刚写的 §5 「速率限制 1h 重试」规则**

**根因**：
1. PM **没有看 subagent 的 error 字段**就 kill（应该只看 error 包含 `rate_limit` 才动）
2. PM **混淆了“CPU 低 = 走岔路”** 和 “CPU 低 = LLM 撞限等待” 两个完全不同的状态
3. PM **对自己的规则不够信任**——刚制定的 §5 还没执行就违反

**经验教训（PM 必读）**：
- 🚫 **低 CPU + 长跑 ≠ 走岔路**，可能是 LLM 撞限在 sleep
- ✅ **低 CPU + 长跑 + 有 commit 输出** → dev 在干活
- ✅ **低 CPU + 长跑 + 无新 commit + 无 error 字段** → 可能是撞限等待
- ✅ **明确看到 error 字段含 `rate_limit` / `429`** → 才能判断为撞限

**永久方案**（已实施）：
1. ✅ PM SOUL.md §5.6 补充明确规则：未看到 `rate_limit` / `429` 错误证据前 **禁止 kill subagent**
2. ✅ 补充“低 CPU 状态诊断检查表”（避免再混淆）
3. ✅ 建立“撞限等待期”默认行为：cron.add(at: +1h) 自动重试，PM 只需监控不需主动 kill
4. ✅ 创建参考表：在事件或会话中看到 subagent “撞限”信号时，**第一反应是 cron.add**，不是 `kill`

**Cron 重试记录**：
- 任务：W1 E-001 重试（更严格 scope）
- Cron ID：`5b3caa21-7d8f-4c92-849d-8b2e19e9c7b6`
- Next Run：`2026-06-29T01:19:00+08:00`
- Session Target：`isolated`

**防再犯检查表**（PM 看到 subagent 长时间低 CPU 时强制执行）：
- [ ] subagent 是否在 commit 输出？（git log 看最近 30 分钟）
- [ ] subagent 是否在写文件？（看 LastWriteTime）
- [ ] subagent 的 error 字段是否包含 `rate_limit` / `429`？
- [ ] 上一次成功的 LLM 调用是什么时候？
- [ ] 是否可以静默等待 5 分钟（cron 1h 后自动 retry）？

**只有以上 5 项都明确是“走岔路”证据时，才考虑 kill。**

---

### ⏳ ISSUE-009 — UI 真实截图生成失败

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-009 |
| **等级** | P3 轻微 |
| **模块** | 图像生成 |
| **报告时间** | 2026-06-28 11:17 |
| **报告人** | PM |

**症状**:
- 调用 `image_generate` 生成 UI 设计图失败
- 错误:`OpenAI API key or Codex OAuth missing`
- 已尝试 3 个屏幕(旅程列表/记账/结算)

**当前状态**:⏳ 未解决

**替代方案**:
- 方案 A:Flutter Widget 真实截图(需要写渲染脚本)
- 方案 B:HTML + Puppeteer(需安装)
- 方案 C:继续用 ASCII 线框图

---

## 三、问题管理流程

### 3.1 问题分级

| 等级 | 定义 | 处理时效 | 合并门槛 |
|---|---|---|---|
| **P0 致命** | 功能不可用、崩溃、数据丢失 | 立即修复(24h) | 不可合并 |
| **P1 严重** | 主要功能异常、影响核心流程 | 当前 Phase 内 | 不可合并 |
| **P2 一般** | 次要功能异常、体验问题 | 可延期下一 Phase | 可合并 |
| **P3 轻微** | 文案、样式、优化建议 | V1.1 处理 | 可合并 |

### 3.2 问题生命周期

```
[报告] → [Triage 分级] → [派单] → [修复] → [验证] → [关闭归档]
                                    ↓
                              [复测失败] → [重派]
```

### 3.3 必填字段

每个问题必须包含:
- **Issue ID**:`BUG-XXX` 或 `ISSUE-XXX` 编号
- **等级**:P0/P1/P2/P3
- **模块**:受影响的功能/服务
- **报告时间** + **报告人**
- **症状描述** + **复现步骤**
- **当前状态**:待处理/进行中/已修复/已关闭

### 3.4 关闭条件

- [ ] 修复代码已 commit
- [ ] dev 自测通过
- [ ] qa 复测通过(如适用)
- [ ] 用户验收(如适用)
- [ ] 文档/日志已更新
- [ ] 关联 commit hash 记录

---

## 四、统计仪表板

### 4.1 按模块

| 模块 | 问题数 | 已修复 | 进行中 |
|---|---|---|---|
| go-game / gomoku | 2 | 2 | 0 |
| OpenClaw 基础设施 | 2 | 0 | 2 |
| 企业微信 | 1 | 0 | 0 |
| DevOps / Git | 1 | 0 | 0 |
| AI 模型 | 1 | 0 | 0 |
| 图像生成 | 1 | 0 | 0 |
| UI 设计 | 1 | 0 | 0 |
| **PM 进程管理** | **1** | **1** | **0** |

### 4.2 按修复者

| 修复者 | 修复数 | 占比 |
|---|---|---|
| PM 直修 | 1 | 33% |
| dev Agent | 2 | 67% |
| qa Agent | 0 | 0% |
| 用户手动绕过 | 1 | (Gateway 重启) |

### 4.3 月度趋势(2026-06)

| 周次 | 新增 | 修复 | 累计开放 |
|---|---|---|---|
| W1 | 4 | 2 | 2 |
| W2 | 0 | 0 | 2 |
| W3 | 5 | 2 | 5 |
| W4 | 0 | 0 | 5 |

---

## 五、与现有文档关系

| 文档 | 关系 |
|---|---|
| `event-log.md` | 任务执行故障(任务级别)→ Issue Tracker 是问题级别 |
| `risk-register.md` | 风险(未来可能)→ Issue Tracker 是已发生问题 |
| `daily-YYYY-MM-DD.md` | 日报里引用 Issue ID |
| `project-development-guidelines.md §5.2` | 引用本表跟踪 Bug |

---

## 六、附录

### A. Issue ID 命名规范

- `BUG-XXX`:代码 Bug(3 位数字,从 001 开始)
- `ISSUE-XXX`:其他问题(配置/环境/工具)

### B. 链接

- 关联 Git Commit:`072fb0b`, `a1d79b8`, `78184a6`, `f52ab91`
- 相关文档:event-log.md, risk-register.md
- 测试报告:go-game/qa-test-report.json

---

*本文档为问题跟踪的唯一权威来源,所有问题必须在本文档登记*
*最后更新:2026-06-28 21:29*
