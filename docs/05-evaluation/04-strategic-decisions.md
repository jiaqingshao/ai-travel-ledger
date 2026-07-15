# 战略决策清单 (v2)

**3 个战略问题需要你做决策**(沿用 v1 + v2 新增的隐含决策)。
每个决策都有 3 个选项,本文档列清楚每个选项的代价和影响,帮你决定。

---

## 决策 D-1: PRD v0.3 三个 P0 功能(语音/重复/统计)做不做?

### v2 现状

V1.2 期间(2026-07-12 ~ 07-14)项目**实现了大量新功能**,但 **E-008/009/010 三个 P0 仍然是 0 行代码**:

| 编号 | 功能 | PRD v0.3 状态 | v2 代码状态 |
|---|---|---|---|
| E-005 | 分享导出(子集:附件上传) | P1 | ✅ **已完整实现**(attachment picker / storage / preview) |
| E-006 | 历史与统计 | P1 | ❌ archived_trips 已实现,统计未做 |
| E-007 | 复杂分摊 | P1 | ❌ SplitRuleEditPage 已实现 5 种基础规则 |
| **E-008** | **语音记账** | **P0** | ❌ 无 STT,无 voice_recording.dart |
| **E-009** | **重复费用** | **P0** | ❌ 无 recurring_expense.dart,无 worker |
| **E-010** | **旅程统计图表** | **P0** | ❌ 无 statistics_screen,fl_chart 在 pubspec 但没人 import |

### v2 矛盾点

V1.2 期间**给 v1 评估增加了**这些证据:

| 文档 | 内容 | v2 含义 |
|---|---|---|
| `CHANGELOG.md` V1.2 段落 | 详细列了 step 1-4(attachment 数据层 / UI / 列表徽章 / 行程汇总) | V1.2 把 E-005 的子集做完了,**但 E-008/009/010 一个都没做** |
| `MILESTONE.md` | "AI 旅行账本从'纯本地工具'升级为'云端协作工具'" + 83 commits + 250/250 测试 | 里程碑是"云端同步",**不是"3 大 P0"**——证明 E-008/009/010 在 V1.2 不是优先级 |
| `roadmap.md`(v2 未变) | E-008/009/010 仍标"未开始" | roadmap 跟 v1 一致没更新 |
| `epic-008-voice-recording/epic.md` | 还在 `99-archive/test-misc/` | 继续放着没动 |
| `issue-tracker.md:737` | 最后同步 2026-07-12 01:35,**没有 E-008/009/010 任何 ISSUE** | 3 个 P0 在 issue 跟踪里**完全不存在** |

**v2 评估新增的论据**:
- V1.2 期间**资源能投入 7 个新 dart 文件 + 4 个 test + 3 个新 doc**(attachment 全套 + release 流程 + Supabase 可选化),证明**"1-2 周补 E-008/009/010" 是可行的**
- 但**实际选择是把资源花在 attachment + cloud**(更易测,差异化更大),**不是因为 PRD 改了**

### 决策选项(沿用 v1)

#### 选项 A: 砍掉,降级 V1.1(⭐ v2 继续推荐)

**动作**:同 v1
- 改 `02-prd.md`:E-008/009/010 标 "P1, V1.1 候选,不在 v0.3 交付"
- 改 `03-fsd-detailed.md`:删 §8/§9/§10
- 改 `04-user-stories.md`:US-013/014/015/016/017 移到 V1.1 backlog
- 改 `roadmap.md`:E-008/009/010 标 "V1.1"
- 删 `99-archive/test-misc/epic-008-009-010/` 占位

**v2 优点**(新增):
- ✅ **跟 CHANGELOG V1.2 + MILESTONE v1.2 cloud 的"实际方向"一致** —— 这俩文档都是 E-005/E-007 路线,**没有 E-008/009/010 的痕迹**
- ✅ issue-tracker 没有 E-008/009/010 ISSUE → 砍了不会"丢失工作"
- ✅ **里程碑已达**(v1.2 cloud-milestone),可以重新命名 milestone 路径

**v2 缺点**(新增):
- ❌ "语音记账"作为 PRD 评估里的"差异化卖点"**仍未实现**

#### 选项 B: 加快实现(1-2 周工作量) — **v2 评估认为是可行的**

**动作**:同 v1
- E-008 语音:Android STT + Qwen3.6(2-3 天)
- E-009 重复:Hive + worker + supabase(3-4 天)
- E-010 统计:fl_chart(2-3 天)

**v2 优点**(新增):
- ✅ V1.2 期间已显示团队**有 1-2 周投入新功能的产能**(attachment 全套 4 步就是 1 周)
- ✅ fl_chart 已经在 pubspec.yaml 里,**省去依赖学习**
- ✅ Qwen3.6 35B 本地模型已可用(`lib/core/ai_config.dart` + `lib/core/ai_service.dart`),语音转文字后可以直接本地分类

**v2 缺点**(新增):
- ❌ voice_recording.dart 需要 Android STT 权限,Flutter 端要用 `speech_to_text` 包,未在 pubspec
- ❌ recurring_expense 需要 workmanager 调度,国产手机后台管理策略已知问题(查 issue-tracker 看是否有相关记录)

#### 选项 C: 维持现状(继续"在路上")

**v2 评估强烈不推荐**。v2 新增证据:**roadmap + issue-tracker + CHANGELOG + MILESTONE 4 个文档互相矛盾**,这种状态已经持续 5+ 天,V1.2 期间没人统一口径。

### 我的推荐

**v2 仍选 A**。理由:
1. v2 评估**强化了 v1 推荐**:`CHANGELOG V1.2` + `MILESTOME v1.2` 都把资源花在 E-005/E-007,**没人提议 E-008/009/010**
2. V1.2 milestone = "云端同步"是**真正的差异化卖点**(国内自驾游场景普遍无网,**离线优先**比"语音记账"更刚需)
3. 砍 E-008/009/010 不影响发布:V1.2 已经发布 cloud-milestone,**功能完整可用**
4. PRD 文档 1 小时改完,1-2 周补 3 个功能 ≠ 1 周发版

**A 的具体动作**见 `03-fix-priorities.md` PR-10。

---

## 决策 D-2: 领先 origin/main commit 何时推?推到哪?

### v2 现状

V1.2 期间**新增量更大**(原 v1 "领先 20 commit"基础上):

| 时间段 | commits | 新增文件 |
|---|---|---|
| v1 评估时(7-12) | 67 本地 | — |
| V1.2 step 1(7-12 18:57) | +1 | attachment + .g |
| V1.2 step 2(7-12 22:30) | +3 | UI 集成 + test |
| V1.2 step 3(7-12 22:40) | +1 | 列表徽章 |
| V1.2 step 4(7-13 00:06) | +1 | 行程汇总 |
| scripts + supabase-config + milestone(7-14) | +5 | 6 个 PS1 + 2 个 config |
| CHANGELOG + MILESTONE(7-14) | +2 | 顶层文档 |
| **预估总计** | **~80 commit 领先** | — |

具体数字待 `git log --oneline | wc -l` 实际跑(本评估**没跑**,标 🔵 推测)。

### v2 决策选项(沿用 v1)

#### 选项 A: 推 Gitee + GitHub(⭐推荐)

**v2 新增优点**:
- ✅ V1.2 cloud-milestone 已经发布,**代码更值得公开**(质量比 V1 评估时高)
- ✅ Gitee 私有仓免费,**附件功能**对云存储用量友好
- ✅ V1.2 step1-4 的"分阶段本地版本"展示了 CI/CD 思路,可以公开吸引开发者

**v2 新增风险**:
- ❌ 推送前**必须**修 S-3(邮箱) + S-4(URL)+ S-1/S-2(SQL bug),**否则公开 = 公开事故**
- ❌ 推送前**必须**解 N-1 决策,**否则文档自相矛盾**
- ❌ V1.2 cloud-milestone APK 含真实 `zvqnawllsdmisntkxdwp` URL,**已泄露**(本评估多次警告)

#### 选项 B: 推 Gitee 单仓

#### 选项 C: 暂存不推

### 我的推荐

**v2 仍选 A**,但**前置条件**比 v1 更严格:

| # | 前置 | 必须先做哪个 PR? |
|---|---|---|
| 1 | 修 S-3 / S-4(邮箱 + URL) | **PR-1** |
| 2 | 修 S-1 / S-2(SQL bug) | **PR-2** |
| 3 | 解 N-1 决策 + 改 PRD | **PR-10** |
| 4 | 跑一遍 `git log --stat` + `wc -l lib/**/*.dart` 校对 CHANGELOG 数字(V2-7) | 一次性命令 |
| 5 | 重新生成 keystore 强密码(S-14 / S-25) | **PR-9** |

---

## 决策 D-3: Android 模拟器问题(已决策跳过) — 沿用 v1

用户明确要求不评估与 Android 模拟器相关的问题。**v2 沿用**。

---

## 决策 D-4(🆕 v2): V1.2 step 2/3/4-local 三个 release 目录是否补 README?

### v2 现状

`release/v1.2-step2-local/`、`v1.2-step3-local/`、`v1.2-step4-local/` 这 3 个目录只有 APK,没 README/CHANGELOG。其他版本都有。

### 决策选项

#### 选项 A: 补 README(推荐)

**动作**:每个目录补 `README.md`(版本日期 + SHA1 + 改了什么 + 已知问题)
**时间**:30 分钟(V2-5 已在 PR-5a 规划)
**优点**:跟 `docs/02-architecture/07-release-build-guide.md` 的规范一致

#### 选项 B: 合并成 v1.2.0+0-cloud 一个目录

**动作**:删 3 个 step-local 目录,把所有变更合到 cloud 版
**优点**:目录整洁
**缺点**:丢历史(测试了哪些、跟 cloud 版的差异)

#### 选项 C: 不管,等以后重构 release 流程时再说

**风险**:`troubleshooting/2026-07-11-emulator-boot-report.md` 同款 —— 没维护的目录会越来越乱

### 我的推荐

**选 A**(已经排进 PR-5a)。V2-5 已识别。

---

## 决策 D-5(🆕 v2): `lib/core/supabase/supabase_config.dart` 是否删除?

### v2 现状

`lib/core/supabase/supabase_config.dart`(旧,45 行) 和 `lib/config/supabase_config.dart`(新,93 行) **类名都是 `SupabaseConfig`**。

- 新文件用 `String.fromEnvironment` 编译时注入(更安全)
- 旧文件用 `defaultValue` 占位字符串(更不安全)
- `main.dart` 第 5 行 `import 'config/supabase_config.dart'`(用新的)

### 决策选项

#### 选项 A: 删旧文件(V2-3 推荐)

**动作**:删 `lib/core/supabase/supabase_config.dart` 整个文件
**风险**:**中**(如果其他地方有 import 会编译失败;但 v2 已 grep 没人 import 它)
**验证**:`grep -rn "supabase_config" lib/` 应只 1 命中

#### 选项 B: 保留旧的,改名为 `LegacySupabaseConfig`

**优点**:留个 fallback 路径
**缺点**:**没有引用方**,留 dead code

#### 选项 C: 合并两个,保留新的逻辑

**优点**:统一
**缺点**:工作量比 A 大

### 我的推荐

**选 A**(已经排进 PR-5)。理由:**没人 import 旧的,删了无副作用**。

---

## 决策 D-6(🆕 v2): 一览表是不是需要彻底重写?

### v2 现状(V2-4)

`项目文件目录结构一览表.md` 写于 2026-07-08,数字全面过时:

| 项 | 一览表写的 | 实际 | 偏差 |
|---|---|---|---|
| 总文件 | 196 | ~250+ | +27% |
| Dart | 64 | 60(含 .g) | -6% |
| 业务代码 | 10,890 行 | ~12,000+ | +10% |
| Markdown | 60 | 50 | -17% |
| SQL | 2 | 3 | +50% |
| 测试 | 225/225 | 234-250(自相矛盾) | +4-11% |

### 决策选项

#### 选项 A: 跑 find 重写(推荐,PR-5b 部分涵盖)

**动作**:
```bash
cd "C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger"
echo "md 总数:" $(find . -name "*.md" -not -path "*/.git/*" -not -path "*/05-evaluation/*" -not -path "*/99-archive/*" -not -path "*/99-reference/*" -not -path "*/node_modules/*" -not -path "*/build/*" | wc -l)
echo "dart 总数:" $(find lib -name "*.dart" | wc -l)
echo "dart 不含 .g:" $(find lib -name "*.dart" -not -name "*.g.dart" | wc -l)
echo "sql 总数:" $(find supabase -name "*.sql" | wc -l)
echo "test 总数:" $(find test -name "*.dart" | wc -l)
echo "业务代码行数:" $(find lib -name "*.dart" -not -name "*.g.dart" -exec cat {} \; | wc -l)
```

**时间**:10 分钟

#### 选项 B: 加自动化校验脚本

**动作**:`tools/check-docs-vs-code.sh` + pre-commit hook,每次提交自动比对
**优点**:长期避免失修
**时间**:2 小时(本评估范围外,V1.1 候选)

#### 选项 C: 不管

**风险**:跟 V2-7 / V2-8 一样,文档失修持续

### 我的推荐

**先选 A**(PR-5b),**V1.1 再加 B**。

---

## 决策时间表(v2)

| 决策 | 阻塞什么 | v2 建议时间 |
|---|---|---|
| **D-1 PRD 三大 P0** | S-15 / S-16 文档修复 / M-30 修复 / V2-7 一致性 | **本周内必决**(比 v1 更紧) |
| **D-2 Git 推送** | 团队协作 / 备份 / 公开 / 公开前的修复 | **新 PC 部署前** |
| D-3 模拟器 | 无(已跳过) | 永不 |
| D-4 release README | V2-5 | 本周(已排 PR-5a) |
| D-5 SupabaseConfig 旧文件 | N-3 | 本周(已排 PR-5) |
| D-6 一览表重写 | V2-4 | 本周(已排 PR-5b) |

---

*完成时间:2026-07-14 | 阻塞决策:2 个 N-类(沿用) + 3 个 v2 新决策(D-4/D-5/D-6 已排进 PR,无需阻塞) | 不阻塞但建议:0 个(模拟器已跳过)*