# ADR-008: Phase 1 国内版本纯本地模式 + 云功能暂缓至 V2.0

**状态**: 已采纳（取代 ADR-007）
**日期**: 2026-07-15
**决策者**: 创始人 + 主 Agent
**优先级**: 高（V1.3 上架前置条件）
**关联**: [ADR-005 国内 Android only](ADR-005-android-cn-only.md), [ADR-007 已撤销](ADR-007-r012-tcb-migration.md)

---

## 背景

V1.2 cloud-milestone (2026-07-14) 发布后，启动 V1.3 国内 Android 上架准备。

**[ADR-007](ADR-007-r012-tcb-migration.md) 决策** (2026-07-15 11:25)：
- 选腾讯云开发 CloudBase (TCB)
- 个人版 ¥19.9/月
- 5-7 周迁移工作量

**创始人 2026-07-15 13:50 复盘**：
- 明确 TCB 个人版**实际是 19.9 元/月，不是免费**
- 不符合"免费额度"约束
- 微信云开发（真正免费的国内 BaaS）6-8 周迁移工作量大（不值得）

---

## 决策

**采纳新方案：Phase 1（V1.3 国内上架）使用纯本地数据库模式，云功能 UI/代码完整保留作为 V2.0 启用基础**

### 决策核心

| 维度 | 决策 |
|---|---|
| **V1.3 模式** | 纯本地（Hive / SQLite on device） |
| **云代码** | 完整保留（`lib/core/supabase/`, `lib/data/sync/`） |
| **云 UI 菜单** | 完整保留（设置页面、auth 屏幕） |
| **云 entry 默认行为** | UI 显示但提示"Phase 2 启用 / V2.0 启用" |
| **数据结构** | 100% 本地，零数据上云 |
| **V1.3 上架后** | 用户无须 ICP 备案 / 无国内云依赖 |

### V2.0 启用条件（占位）

等 V2.0 阶段重新评估，可能路径：
- (a) 找到真正的免费国内 BaaS（如某个新平台）
- (b) 接受 ¥19.9/月 TCB 个人版（240 元/年）
- (c) 海外市场扩展（保持 Supabase）
- (d) 永久纯本地（云架构代码归档但不删）

---

## 撤销 ADR-007

**ADR-007 [腾讯云开发 CloudBase 迁移决策]** 由本 ADR (ADR-008) **撤销**。

**撤销原因**：
- TCB 个人版不是免费（19.9 元/月）
- 不符合创始人"免费额度"约束
- 替代方案已确定（纯本地 Phase 1）

**保留价值**：
- ADR-007 的技术分析（TCB vs 华为 vs 阿里 vs 自建）作为决策历史保留
- 5-7 周迁移工作量估算作为 V2.0 时参考
- [tcb-setup-guide.md](../../03-management/tcb-setup-guide.md) 标记为 deprecated（作为决策历史保留）

---

## 不动的部分（关键承诺）

| 项 | 状态 | 备注 |
|---|---|---|
| `lib/core/supabase/supabase_service.dart` | ✅ 完整保留 | V2.0 启用时直接用 |
| `lib/data/sync/sync_engine.dart` | ✅ 完整保留 | Phase 1 不启动 |
| `lib/main.dart` 的 SyncEngine 启动 | ✅ 保留但**不触发** | V2.0 启用时改 1 行 flag |
| `lib/data/repositories/*` | ✅ 完整保留 | 已有双写 / 云 / 本地逻辑 |
| `lib/presentation/screens/supabase_settings_screen.dart` | ✅ UI 完整 | 仅顶部加"Phase 1 暂未启用" banner |
| `lib/presentation/screens/auth_screen.dart` | ✅ UI 完整 | 仅顶部加"云功能 V2.0 启用" 提示 |
| `supabase/migrations/*.sql` | ✅ 完整保留 | V2.0 启用时直接复用 |
| `docs/03-management/security/` | ✅ 保留 | V2.0 keystore v2 仍可复用 |
| keystore v2 (备份) | ✅ 保留 | V1.3 国内上架前仍可启用 |

**承诺**：未来 V2.0 启用云功能时，**几乎不需要重写代码**——只需要：
1. 改 1 行 `lib/main.dart` 的 flag
2. 把 Supabase URL / Key 写回 UI 默认值
3. 关闭 V1.3 加的 banner

---

## V1.3 新决策树

### 用户使用路径（V1.3 国内 Android）

```
用户安装 V1.3
  ↓
打开 APP → 默认纯本地模式
  ↓
创建旅程 + 添加成员 + 记账 + 结算
  ↓
（不询问云同步 / 不显示"登录"按钮）
  ↓
数据存本地 Hive
  ↓
如果用户点"云端"菜单 → 显示"Phase 2 启用"
```

### 关键 UX 改动（极小）

- `supabase_settings_screen.dart`：顶部加 1 个 `Container` 显示 banner
  ```dart
  if (kPhase1CloudDisabled) Container(
    color: Colors.amber.shade100,
    child: Text('🟡 Phase 1 国内版本暂未启用云同步（V2.0 启用）'),
  )
  ```
- `auth_screen.dart`：在"联系 GitHub" 文字下加一行
  ```dart
  Text('当前为本地模式，云端功能 V2.0 启用'),
  ```

**V1.3 上架完全功能可用**（v0.3.5 main.dart 默认值调整）：
- 默认 `isCloudMode = false`（已是默认值）
- 默认 `currentUserId = null`（用户选择本地模式）
- 实测：跟 V1.0.0-local 行为一致（已经走过）

---

## 时间表（新方案大幅压缩）

```
2026-07-15  ADR-008 决策 ✅ (现在)
2026-07-16  用户启动 R011 软著申请 (1-2 月等待)
2026-07-16  用户启动国内 Android 商店账号注册
2026-07-20  V1.3 上架资料准备 (隐私政策 / 截图 / 描述)
2026-08-15  软著下来 (1-2 月等待)
2026-08-25  ICP 备案 (腾讯云代办 TCB 子域名，**但 Phase 1 用不上**)
                  ▲
                  │ Phase 1 不需要 ICP！如果有国内任何 Web 服务才需要
                  │ V1.3 Phase 1 是 APP 不提供 Web 服务，理论上不需要 ICP
                  │ 但保险起见仍建议办 (防止后续需要)
2026-09-15  V1.3 国内 Android 上架 (小米/OPPO 试水)
```

**对比原方案**：
- 原: 5-7 周 (含 TCB 5-7 周迁移)
- 新: **~6 周** (去掉了 TCB 迁移, 仅保留 1-2 周资料准备 + 1-2 周软著等)

**实际可并行**：
- 软著办理与上线准备并行
- 上架准备与商店账号注册并行
- 总压缩到 **4-6 周内 V1.3 可上架**

---

## V1.3 上架需要的材料（更精简）

| 资源 | 工作量 | 阻塞 | 备注 |
|---|---|---|---|
| R011 软件著作权 | 1-2 月 | ⏳ 长尾阻塞 | 必须先有 |
| ICP 备案 | 7-10 工作日 | ❌ **Phase 1 不需要** | 仅 APP 不提供 Web 服务时 |
| 隐私政策 (中文) | 1-2 天 | ❌ 不阻塞 | V1.3 本地无数据收集声明 |
| 用户协议 | 1 天 | ❌ 不阻塞 | 模板即可 |
| 商店截图 (5 张) | 1 天 | ⏳ 必须 | 各商店共享 |
| 商店描述 | 0.5 天 | ⏳ 必须 | 中文文案 |
| 商店账号注册 | 1-3 天 / 个 | ⏳ 必须 | 小米 / OPPO 分别注册 |
| **V1.3 APK 重新打包** | 0.5 天 | ⏳ 必须 | 用 V2 keystore 重新签名（防泄露旧 weak pwd）|

---

## 与已有决策的关系

| 决策 | 关系 |
|---|---|
| [ADR-005 国内 Android only](ADR-005-android-cn-only.md) | ✅ 仍然有效 |
| [ADR-004 PRD P0 暂缓](ADR-004-prd-v0.3-p0-defer.md) | ✅ 仍然有效 |
| [ADR-006 V2 keystore](ADR-006-keystore-v2.md) | ✅ 仍然有效（V1.3 重新签名用） |
| [ADR-007 TCB 迁移](ADR-007-r012-tcb-migration.md) | ❌ **本 ADR 撤销** |

---

## 影响

### 对 R012 / R014

- **R012 ICP 备案**：从"高风险 待评估" → "**Phase 1 不需要**（未来启用云时再评估）"
- **R014 TCB 迁移风险**：直接关闭（ADR-007 撤销）
- 新增 R015 "V2.0 启用云时再评估 R012/R014"

### 对 V1.3 上架计划

时间压缩 **6 周 vs 原 5-7 周**：
- 不删除任何代码风险
- 不引入新依赖风险
- V1.3 同 V1.0.0-local 路径，但有 V1.1 + V1.2 全部改进

### 对商业模式（PRD §1.4）

保持不变：
- 免费版：纯本地，永久免费
- 高级版：¥18/月，Phase 1 是"Pro Badge / 多主题 / 高级导出"等 UI 差异化
- ❌ 高级版**不能**卖"云同步"作为卖点（V1.3 phase1 没有云）
- V2.0 启用云后：高级版可以加入"云同步"差异化

### 对 V2.0 规划

V2.0 路线保留（云启用决策待 V1.3 国内上架成功 + 收入验证后）：
- 候选 1：找到真正免费的国内 BaaS
- 候选 2：接受 ¥19.9/月 TCB 个人版
- 候选 3：海外市场扩张（Supabase 不动）
- 候选 4：永久本地化（云架构代码转 archived 状态）

---

## 工作清单（撤销 ADR-007 + 决策 ADR-008）

| # | 文件/动作 | 状态 |
|---|---|---|
| 1 | `docs/02-architecture/04-adr/ADR-008-phase1-local-only-cloud-deferred.md` (本文档) | ✅ |
| 2 | `docs/02-architecture/04-adr/ADR-007-r012-tcb-migration.md` 头部加 "已撤销 by ADR-008" | ⏳ |
| 3 | `docs/03-management/tcb-setup-guide.md` 头部加 "deprecated by ADR-008" | ⏳ |
| 4 | `CHANGELOG.md` Unreleased 加 ADR-008 | ⏳ |
| 5 | `MILESTONE.md` 下一个里程碑 v1.3-local-cn-stores | ⏳ |
| 6 | `roadmap/roadmap.md` v0.3.4 修订 | ⏳ |
| 7 | `docs/03-management/issue-tracker.md` ISSUE-034 改 + ISSUE-036 关闭 + ISSUE-037 新增 | ⏳ |
| 8 | `docs/03-management/risk-register.md` R012/R014 状态变 + R015 新增 | ⏳ |
| 9 | `docs/01-requirements/02-prd.md` §1.4 v0.3.3 微调 | ⏳ |
| 10 | （可选）代码层最标记：`lib/main.dart` 加 `_phase1CloudDisabled = true` | ⏳ |

---

*ADR-008 的存在意义：在 V2.0 时（重新评估云功能时），**第一站打开本文档**就能了解"2026-07-15 为何 Phase 1 纯本地"，避免重复决策；同时 ADR-007 撤销信息清晰可追溯。*
