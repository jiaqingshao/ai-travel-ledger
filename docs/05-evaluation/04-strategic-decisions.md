# 战略决策清单

**3 个战略问题需要你做决策**。每个决策都有 3 个选项,本文档列清楚每个选项的代价和影响,帮你决定。

---

## 决策 D-1: PRD v0.3 三个 P0 功能(语音/重复/统计)做不做?

### 当前状态

PRD v0.3 自我标记 E-008 / E-009 / E-010 为 P0 MVP 功能,但 **lib/ 里 0 个相关文件**:

| 编号 | 功能 | PRD 状态 | 代码状态 |
|---|---|---|---|
| E-008 | 语音记账 | P0 MVP(NEW in v0.3) | ❌ 无 `voice_recording.dart`、无 STT |
| E-009 | 重复费用 | P0 MVP(NEW in v0.3) | ❌ 无 `recurring_expense.dart`、无 worker |
| E-010 | 旅程统计图表 | P0 MVP(NEW in v0.3) | ❌ 无 `statistics_screen.dart`、fl_chart 在 pubspec 但没人 import |

**roadmap.md 第 18-23 行自己写"全部未开始"**,但 roadmap 没有任何"v0.3 新增"标记解释为什么。

### 矛盾点

| 文档 | 写的 |
|---|---|
| PRD v0.3 | "🆕 v0.3 变更:基于 2026-06-28 市场调研,新增 3 个 MVP P0 功能" |
| FSD v0.4 | "§8 语音记账 / §9 重复费用 / §10 旅程统计" 详写 |
| 用户故事 16/017 | 验收标准写得很具体 |
| `项目文件目录结构一览表.md` | 仍然写"22 屏幕 + 5 model"(2026-07-08 之前) |
| `roadmap.md` | E-008/009/010 = 未开始 |
| `epic-001/002/003/004/epic.md` | 全标"未开始",但 E-001/002/003/004 实际已实现 |
| **代码** | **0 实现** |

### 决策选项

#### 选项 A: 砍掉,降级 V1.1(⭐推荐)

**动作**:
- 改 `02-prd.md`:E-008/009/010 标 "P1, V1.1 候选,不在 v0.3 交付"
- 改 `03-fsd-detailed.md`:删 §8/§9/§10(或标 "V1.1 草案")
- 改 `04-user-stories.md`:US-013/014/015/016/017 移到 V1.1 backlog
- 改 `01-brainstorm.md`(如果存在):删语音/重复/统计相关条目
- 改 `02-prd.md` "v0.3 变更"段落,改成"v0.3 变更:无功能新增,仅性能优化与测试覆盖"
- 改 `roadmap.md`:E-008/009/010 标 "V1.1"
- 删 `99-archive/test-misc/epic-008-009-010/` 占位
- 不动 `lib/`(代码现状跟降级后的承诺一致)

**优点**:
- ✅ **产品诚信** —— 不再虚假承诺
- ✅ **快速** —— 1-2 小时改完文档
- ✅ **统一** —— roadmap/PRD/代码三方一致
- ✅ **清晰** —— 用户知道 v0.3 实际是 "4 P0 + 4 已完成 Epic",V1.1 才上 3 个新 P0

**缺点**:
- ❌ 失去"语音记账"这个 **差异化的卖点** (PRD 评估显示是"竞品分析里的创新点")
- ❌ V1.1 工作量加大

**风险**:
- 内部测试时已有真机体验记录(issue-tracker 多次提到"语音记账"),用户可能已经习惯
- 但**:目前没实现,用户没真正用过**(issue-tracker 查不到 E-008/009/010 相关 bug,只有真机 UI 反馈)

---

#### 选项 B: 加快实现(1-2 周工作量)

**动作**:
- E-008 语音:用 Android 系统 STT + Qwen3.6 本地 LLM 做分类(2-3 天)
- E-009 重复:加 `recurring_expenses` Hive box + supabase 迁移 + workmanager 定时(3-4 天)
- E-010 统计:加 `statistics_screen.dart` + fl_chart 集成(2-3 天)
- 同步:重写 `项目文件目录结构一览表.md`、`roadmap.md`、PR 描述

**优点**:
- ✅ 履行 PRD 承诺
- ✅ 增强产品差异(语音记账是国内空白)

**缺点**:
- ❌ 1-2 周额外工作量
- ❌ 写完必须完整测(语音识别准确率 > 90% 是 PRD 验收标准,**做不到就是 bug**)
- ❌ 当前 v0.2.0+2 已在用户手上,新功能要再发 v0.3.0

**风险**:
- STT 准确率:中文场景 ≥ 90% 很难,方言更难
- fl_chart 集成有学习成本
- workmanager 定时任务在国产手机上被各种杀死(已知问题)

---

#### 选项 C: 维持现状(继续"在路上")

**动作**:什么都不做

**优点**:
- 零工作量

**缺点**:
- ❌ **产品诚信风险** —— 文档承诺的 P0 永远不实现,用户/投资人/审核员会问
- ❌ 内部 review 永远过不去
- ❌ 新成员按 roadmap 找不到代码
- ❌ 团队目标感丢失

**风险**:
- 上架审核被质疑
- 内部士气降低

---

### 我的推荐

**选 A**。理由:
1. **3 个 P0 没实现 + 文档说已实现** = 失信比"功能少"严重
2. 当前 v0.2.0+2 已在用户手上,**功能可用**,不是"半成品"
3. 修文档 1-2 小时,补功能 1-2 周
4. PRD 里写的"差异化"卖点(语音记账)在国内只有"百事 AA"有,你没做也不会马上失市场
5. 真正高频用的:**6 种分摊算法 + 4 宫格结算 + 离线** —— 这些已经做完了

**A 的具体动作**见 `03-fix-priorities.md` PR-9。

---

## 决策 D-2: 领先 origin/main 20 commit 何时推?推到哪?

### 当前状态

`pc-migration-guide.md:64-66`:
> "GitHub push 失败(github.com 国内连接超时)"

`daily-reports/2026-07-10.md`:
> "main 合并完成:`ab3441e merge dev → main`"
> "GitHub push 失败(github.com 国内连接超时)"

**问题**:
- 你开发了 20+ commit,合并到 main 了,**但 origin/main 还没收到**(SSH 不可达 / HTTP 慢)
- 如果你新 PC 拉代码,只能从 `openclawbackup` ZIP 拉,不能 `git pull`
- 没有 review 流程,只有"PM Agent 改 + 用户确认"
- 备份只在一台 PC(VM 上的 home 目录)

### 决策选项

#### 选项 A: 推 Gitee(国内快)+ GitHub(代理)⭐推荐

**动作**:
```powershell
# 1. 注册 Gitee 账号
# 2. 推送到 Gitee
git remote add gitee https://gitee.com/<your-name>/ai-travel-ledger.git
git push gitee main

# 3. 配置 SSH 代理(让 GitHub push 可达)
# ~/.ssh/config:
# Host github.com
#   ProxyCommand connect -S 127.0.0.1:1080 %h %p
git push origin main

# 4. 流程:dev 开发 → PR → main review → 双 remote 同步
```

**优点**:
- ✅ 国内访问 Gitee 极快(< 1s)
- ✅ GitHub 公开(开源/招聘用)
- ✅ 双仓库不冲突
- ✅ 新 PC `git clone` 走 Gitee 即可

**缺点**:
- ❌ Gitee 私有仓库要付费
- ❌ 要维护两个 remote
- ❌ GitHub 代理配置麻烦(Clash/V2Ray 等)

**风险**:
- Gitee 偶尔会审查(企业项目可能)
- 公开 GitHub 暴露邮箱(已泄露 S-3)

---

#### 选项 B: 推 Gitee 单仓

**动作**:
```powershell
git remote add gitee https://gitee.com/<your-name>/ai-travel-ledger.git
git push gitee main
```

**优点**:
- ✅ 简单
- ✅ 国内访问快
- ✅ 一份代码

**缺点**:
- ❌ 国内服务长期可用性不确定
- ❌ 不能用于"开源/招聘/技术博客引用"
- ❌ 协作者(若有)要注册 Gitee

---

#### 选项 C: 暂存不推,本地开发

**动作**:什么都不做,继续用 ZIP 备份

**优点**:
- 零工作量

**缺点**:
- ❌ 多人协作基本不可能
- ❌ **新 PC 必须手动 ZIP**(你已经做了 1 次,再 1 次 OK,第 3 次呢?)
- ❌ 丢了 = 全丢(没有异地备份)

**风险**:
- VM 硬盘故障 = 全部代码丢
- 公开技术贡献 = 0

---

### 我的推荐

**选 A**。理由:
1. Gitee + GitHub 双开是国产个人项目的标准做法
2. 你已经在 issue-tracker 提过"GitHub 国内超时"——这是已识别问题,趁 PC 切换正好解决
3. `pc-migration-guide.md` 已经写"推到 GitHub"是计划,只是没成
4. S-3 邮箱已经泄露(已发生),S-4 Supabase URL 也已经泄露(已发生)—— 公开 GitHub 不会增加新的泄露
5. 长期看,做开源/技术分享都需要 GitHub 公开仓

**A 的具体动作** 见 `03-fix-priorities.md` PR 之后,作为独立任务跟踪。

---

## 决策 D-3: Android 模拟器问题(已决策跳过)

**用户明确要求**:
> "其中有关安卓模拟器的问题暂时不需要处理和对应,请知晓"

**所以本评估不收录**:
- ISSUE-014 嵌套虚拟化下模拟器启动失败
- `docs/03-management/troubleshooting/2026-07-11-emulator-boot-report.md`(572 行)
- 所有 emulator boot 失败相关 ISSUE
- daily-reports 里关于 emulator 的所有段

**新 PC(嵌套虚拟化)开发策略**:
- ✅ 用真机 USB 调试(已实施,真机测试 checklist 走通 6 个 ISSUE)
- ✅ Chrome Web 模式 `flutter run -d chrome`(已用)
- ❌ 模拟器(嵌套虚拟化限制,跳过)
- ❌ 云模拟器(Appetize.io / BrowserStack)(plan B,可后续)

**后续如需评估模拟器问题**,在另一份 `06-emulator-boot-evaluation/` 目录独立做。

---

## 决策时间表

| 决策 | 阻塞什么 | 建议时间 |
|---|---|---|
| **D-1 PRD 三大 P0** | S-15 / S-16 文档修复 / M-30 修复 | **本周内必决** |
| **D-2 Git 推送** | 团队协作 / 备份 / 公开 | **新 PC 部署前** |
| D-3 模拟器 | 无(已跳过) | 永不 |

---

## 决策后,我建议的立即行动

### 如果选 D-1 = 砍掉

| # | 动作 | 责任 | 时间 |
|---|---|---|---|
| 1 | 改 `02-prd.md` 改 v0.3 变更段 | 你 | 15 分钟 |
| 2 | 改 `03-fsd-detailed.md` 删 §8/§9/§10 | 你 | 30 分钟 |
| 3 | 改 `roadmap.md` 标 E-008/009/010 为 V1.1 | 你 | 15 分钟 |
| 4 | 改 `04-user-stories.md` 移 US-013/014/015/016/017 | 你 | 15 分钟 |
| 5 | 改 `项目文件目录结构一览表.md` | 我(用 find 跑) | 10 分钟 |
| 6 | 删 `99-archive/test-misc/epic-008-009-010/` 占位 | 你 | 5 分钟 |
| 7 | 删 `lib/` 里如果残留的 `voice_/recurring_/statistics_` 引用(grep 确认) | 我(报告) | 5 分钟 |

合计 1.5 小时可完。

### 如果选 D-1 = 加快实现

| # | 动作 | 工作量 |
|---|---|---|
| 1 | E-008 语音记账(Android STT + Qwen3.6) | 2-3 天 |
| 2 | E-009 重复费用(Hive + worker + supabase 迁移) | 3-4 天 |
| 3 | E-010 统计(fl_chart 集成) | 2-3 天 |
| 4 | 文档/roadmap/一览表更新 | 1 天 |
| 5 | 集成测试 | 1 天 |

合计 9-12 天。**约 2 周**。

### 如果选 D-1 = 维持

什么都不做,接受产品诚信风险。**强烈不推荐**。

---

### 如果选 D-2 = Gitee + GitHub

| # | 动作 | 责任 | 时间 |
|---|---|---|---|
| 1 | 注册 Gitee 账号(如果没) | 你 | 5 分钟 |
| 2 | 创建 Gitee 仓(空仓) | 你 | 2 分钟 |
| 3 | `git remote add gitee <url>` | 我跑命令 | 1 分钟 |
| 4 | `git push gitee main` | 我跑 | 1 分钟 |
| 5 | 配置 GitHub 代理(你给代理端口) | 你 | 10 分钟 |
| 6 | `git push origin main` | 我跑 | 1 分钟 |
| 7 | 验证两仓同步 | 我 | 1 分钟 |
| 8 | 改 `pc-migration-guide.md` 改 "推到 GitHub" → "Gitee + GitHub" | 我 | 5 分钟 |

合计 30 分钟(假设代理已配)。

### 如果选 D-2 = Gitee 单仓

| # | 动作 | 时间 |
|---|---|---|
| 1-4 | 同上,跳过 5-7 | 10 分钟 |
| 5 | 改 `pc-migration-guide.md` | 5 分钟 |

合计 15 分钟。

---

## 决策后,做不做都行的"可选"

- **写 PR-9 的文档修改**(已经说了 1.5 小时,做完才能让 S-15 / S-16 / S-17 解决)
- **把领先 20 commit 推送**(决策 D-2)
- **修 pubspec / analysis_options lint**(PR-13,30 分钟)
- **拆 5 个 repo 的 `deleteAllByTrip` 串联调用**(PR-16,2 小时)

---

## 决策记录模板

做决策时,在 `docs/05-evaluation/decisions-log.md` 留记录(我建议你建一个,目前没有这个文件):

```markdown
# 决策日志

## 2026-07-12 D-1: PRD v0.3 三大 P0

**决策**:选项 [A / B / C] (XXX)
**理由**:...
**影响**:
- 文档改动:[列出要改的文件]
- 代码改动:[列出要改的文件]
- 延期影响:[V1.1 时间 / 团队节奏]
**执行**: [列出 PR 编号 + 责任人]
**复查日期**: [定个日期回头看]

## 2026-07-XX D-2: Git 推送
...
```

---

*完成时间:2026-07-12 | 阻塞决策:2 个 | 不阻塞但建议:1 个(模拟器已跳过)*
