# ADR-004: PRD v0.3 三大 P0 功能（语音/重复/统计）暂缓至 V1.1

**状态**: 已采纳
**日期**: 2026-07-15
**决策者**: 创始人 + 主 Agent

---

## 背景

2026-06-28 v0.3 PRD（基于市场调研）新增 3 个 MVP P0 功能：
- **E-008 语音记账**（Android STT + Qwen3.6 LLM 自动归类）
- **E-009 重复费用**（工作日/周/月/年 + 自定义日期 + 组维度）
- **E-010 旅程统计图表**（饼图 / 柱状图 / 折线 + 分享）

但 V1.2 cloud-milestone 已于 2026-07-14 完成并发布（87 commits + 249/250 测试），
**实际投入聚焦在"云端同步 + 附件上传"，而非上述 3 个 P0**。

V1.2 期间发现 5 处文档失修互相矛盾：

| # | 证据 | 内容 |
|---|---|---|
| 1 | `docs/01-requirements/02-prd.md` §3.5-3.7 | ⚠️ 标 P0（**声称**） |
| 2 | `roadmap/roadmap.md` 总览表 | ⚠️ 标 P0/MVP（**声称**） |
| 3 | `CHANGELOG.md` Unreleased | ❌ 没有这 3 个 |
| 4 | `MILESTONE.md` 下一个候选 | ❌ 只有 v1.3-team / v2.0-enterprise / v2.0-ai |
| 5 | `pubspec.yaml` | ⚠️ fl_chart 已加但**无人 import**；speech_to_text / workmanager **未加** |
| 6 | `docs/99-archive/test-misc/epic-008-009-010/` | ❌ epic.md **已被归档**（从未实施） |
| 7 | `docs/03-management/issue-tracker.md` | ❌ 没有任何对应 ISSUE |

注：roadmap + PRD "声称 P0"；CHANGELOG + MILESTONE + epic + pubspec + issue-tracker "实际未做"。
**5 vs 2 反向证据 = 项目已经自然放弃在 V1.2 实施 E-008/009/010**，只是未正式化决策。

## 候选方案

### 方案 1: 暂缓 E-008/009/010 至 V1.1 候选（推荐）✅

**行动**:
- PRD / FSD / UserStories / Roadmap 4 份文档统一标 "V1.1 候选，暂缓实施"
- `docs/99-archive/test-misc/epic-008-009-010/` → `roadmap/epic-008-009-010/`（按 roadmap 同位置）
- `pubspec.yaml` `fl_chart` 加注释"V1.1 候选保留，不删除避免破坏 lock"
- epic.md 加 ADR-004 引用，便于后续重新启动时找到决策上下文

**优点**:
- ✅ 7 处文档从此一致（PRD / Roadmap / CHANGELOG / MILESTONE / pubspec / epic / issue-tracker）
- ✅ V1.2 cloud-milestone 聚焦"自驾游场景云端同步"差异化，逻辑闭合
- ✅ V1.3 候选（实时协作 / Google Play / Sentry）有清晰路线
- ✅ 不打断 V1.2 已形成的"里程碑方法"节奏
- ✅ 工作量 1-2 小时 vs 1-2 周，资源回报率高
- ✅ 后续随时可重启（决策 + epic 上下文都在）

**缺点**:
- ❌ "语音记账"国内差异化卖点未实现（百事 AA / 来福记账 / 叨叨记账 已做）
- ❌ v0.3 PRD 评估时规划的"差异化"路线没兑现
- ❌ 5+ 天失修状态对外不专业（但已修复）

### 方案 2: 1-2 周补完 E-008/009/010

**子任务**:
- E-008 语音（2-3 天）：`speech_to_text` + Android STT + 录音 UI + Qwen3.6 LLM 归类
- E-009 重复（3-4 天）：`workmanager` + 周期规则 + Hive 持久化 + Supabase sync
- E-010 统计（2-3 天）：`statistics_screen.dart` + 饼图/柱状图/折线 + 截图分享

**优点**:
- 兑现 v0.3 PRD 承诺
- V1.2 期间已显示产能（87 commits / 2 周 ≈ 7.5 工作日）

**缺点**:
- ❌ 打断 V1.3 候选（实时协作 / Google Play / Sentry）推迟 1-2 周
- ❌ 国产手机 workmanager 后台调度已知不稳定（risk-register 历史）
- ❌ 中文方言 STT 准确率 90% 测试成本高（需录数据集）
- ❌ 推翻 V1.2 "聚焦里程碑方法"，回到"什么都做但不精"老路

### 方案 3: 维持现状（不决）

**风险**:
- 7 处失修持续恶化
- V1.3 路线图更难规划
- 新人 onboarding 看到文档自相矛盾会困惑

## 决策

**选择方案 1：暂缓 E-008/009/010 至 V1.1 候选**

立即行动（详见本文档底部的"工作清单"）：
1. 创建本 ADR（已做）
2. 更新 PRD / FSD / US / Roadmap 4 份主文档
3. 移动 epic.md 到 roadmap/ 同级
4. 更新 CHANGELOG / MILESTONE / issue-tracker
5. 加 pubspec 注释
6. 创建对应 ISSUE 条目到 issue-tracker（标记 V1.1 backlog）

## 影响

### 接受的变化

- **PRD 砍掉 3 个 P0**：v1.0 / V1.2 实际 P0 仅 5 个（E-001 ~ E-005）
- **roadmap 重排**：MVP 段从 7 个 Epic 缩到 4 个；E-008/009/010 移到 V1.1 候选
- **里程碑节奏**：M1 (MVP 内测) 验收标准从"P0 全部完成" → "P0 4 个完成"（E-001 ~ E-004）
- **未来可重启**：V1.1 / V1.2 / V2.0 任何阶段都可重新启用（决策 + epic 都在）

### 后续启动条件（V1.1 时）

如需重新启用 E-008/009/010，需重新评估：
1. **市场调研**：自驾游场景的真实需求（"驾驶时记账"是否符合实际场景）
2. **资源评估**：1-2 周开发 + 中文 STT 数据集测试
3. **差异化**：是否仍是核心差异化卖点（V1.3 阶段可能已被实时协作 / Play 上架覆盖）

### 不动的部分

- `pubspec.yaml` 中 `fl_chart 0.66.2` 保留（**不删除**，避免破坏 pubspec.lock；V1.1 候选可直接用）
- `lib/core/ai_config.dart` + `lib/core/ai_service.dart`（Qwen3.6 LLM 集成代码）保留，作为 E-008 自动归类预研
- E-005 子集（V1.2 附件）继续往前推进

## 工作清单

| # | 文件 | 改动 | 状态 |
|---|---|---|---|
| 1 | `docs/02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md` | 新建本文件 | ✅ |
| 2 | `docs/01-requirements/02-prd.md` | §3.5-3.7 标"暂缓，详见 ADR-004" + §0 增加决策章节 | ⏳ |
| 3 | `docs/01-requirements/03-fsd-detailed.md` | §8/§9/§10 标"暂缓" | ⏳ |
| 4 | `docs/01-requirements/04-user-stories.md` | US-013/014/015/016/017 标"暂缓" | ⏳ |
| 5 | `roadmap/roadmap.md` | E-008/009/010 移到 V1.1 候选 + 加决策日期 | ⏳ |
| 6 | `roadmap/epic-008-voice-recording/` | 从 99-archive/test-misc/ 移动 + 加 ADR-004 引用 | ⏳ |
| 7 | `roadmap/epic-009-recurring-expenses/` | 同上 | ⏳ |
| 8 | `roadmap/epic-010-statistics/` | 同上 | ⏳ |
| 9 | `CHANGELOG.md` | Unreleased 加 ADR-004 决策记录 | ⏳ |
| 10 | `MILESTONE.md` | 下个里程碑候选加 ADR-004 引用 + 加"V1.1 启用"说明 | ⏳ |
| 11 | `docs/03-management/issue-tracker.md` | 头部决策摘要 + 加 3 个 V1.1 backlog ISSUE | ⏳ |
| 12 | `pubspec.yaml` | fl_chart 加注释 | ⏳ |
| 13 | `docs/05-evaluation/*.md` | 6 份核对文档正式化为评估 v3 | ⏳ |

**预计完成时间**: 1-2 小时（纯文档，零代码改动）

---

*ADR-004 的存在意义：在 V1.1 重新启动任何 P0 时，开发者**第一站打开本文档**，就能看到"2026-07-15 为什么暂缓"的完整决策上下文。*
*而不是重新翻 PR、查 chat 历史、猜原因。*
