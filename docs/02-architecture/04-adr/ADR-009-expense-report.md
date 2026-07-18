# ADR-009: 费用报告功能 (新增需求变更)

**状态**: 已采纳
**日期**: 2026-07-18
**决策者**: 创始人
**优先级**: P2 一般 (V1.3 上架后启动)
**来源**: 用户真机测试 v1.3.0-phase1-local-test 时提出

---

## 背景

2026-07-18 用户在测试 v1.3.0-phase1-local-test APK (commit `0418f26`) 时提出增强需求：

> "增加一个费用报告功能, 用户点击后生成截止到目前的费用开始分析报告"

**当前状态**: 项目无费用报告功能, 仅有旅程汇总 (归档列表查看) + 结算 (按人数算应收应付)。
**与历史关系**: PRD v0.3 §3.7 (E-010) 曾定义过类似需求, 但 [ADR-004](ADR-004-prd-v0.3-p0-defer.md) (2026-07-15) 将 E-010 暂缓至 V1.1 候选。本 ADR 重新唤醒 E-010, 并扩展为费用报告功能。

---

## 决策

**采纳**: V1.3 上架后启动 "费用报告" 功能开发

### 范围 (MVP, 分阶段交付)

**Phase 1 (P2 一期, 2-3 周)**:
- 页面入口: 结算页/旅程详情/归档旅程均可入口
- 全旅程汇总卡片:
  - 总支出 + 人均 + 笔数 + 时间范围
  - 按类别饼图 (油费/餐饮/住宿/交通/其他, 10 个内置类别)
  - 人均柱状图 (谁花得多, 含参与人排名)
  - 时间趋势折线 (每日/每周消费节奏)

**Phase 2 (P2 二期, 1-2 周)**:
- 报告分享 (生成长图 PNG + 系统分享)
- 报告导出 (PDF)
- 时间范围筛选 (本月/本季/年/全部)

**Phase 3 (V2.0, 复用 V2.0 云能力)**:
- AI 文字总结 (调用 LLM 生成 "这次旅行平均每人 X 元, 吃饭最多...")
- 多人协作报告 (混合数据, 多旅程合并)

---

## 不在本期范围

- **语音输入**: ADR-004 暂缓
- **导出 Excel/PDF**: 列为 V2.0 候选 (iText 等库量大)
- **打印支持**: 暂不做 (国内打印场景少)
- **AI 智能洞察**: 见 Phase 3, V2.0

---

## 候选方案对比

### 方案 A: 集成 fl_chart (推荐 ⭐)

**实现**: 直接使用 `fl_chart` (pubspec 已加依赖, ADR-006 升级备注保留)。

**优点**:
- ✅ 已加依赖, 不需安装新包
- ✅ 离线渲染, 不依赖外部 CDN
- ✅ 国内合规 (用户偏好: 不依赖外部服务)
- ✅ 包体积无明显增加
- ✅ 4 种图表 API 完整 (饼图/柱状图/折线/雷达)

**缺点**:
- ❌ 文档相对英文, 中文社区资源少
- ❌ 性能优化需手动 (大数据集需采样)

### 方案 B: 集成 charts_flutter (Google 官方)

**优点**: Flutter 官方图表库
**缺点**: 维护慢, 包体积大, Android 上有问题

### 方案 C: 自定义 CustomPainter

**优点**: 完全控制 UI
**缺点**: 工作量大 (3-4 周只写图表), 不在 5 周内能交付

### 决策: **方案 A (fl_chart)**

---

## V1.3 影响

| 项 | 影响 |
|---|---|
| Phase 1 上架 | ✅ 不阻塞, 报告功能 V1.3 上架后启动 |
| pubspec.yaml | 已有 fl_chart, 移除 V1.1 标注 "未使用" 注 |
| Hive 数据 | 已支持, 无 schema 变更 |
| 现有页面 | 结算页 + 旅程详情页 + 归档列表 加 "费用报告" 入口 |
| 测试 | 新增 20+ 测试 (汇总计算 / 图表数据格式化 / 分享) |
| 工作量 | 4-6 周 (Phase 1: 2-3 周, Phase 2: 1-2 周) |

---

## 设计约束

### 数据来源

仅从本地 Hive 计算, Phase 1 = ADR-008 纯本地:
- `Box<Expense>` (当前活跃)
- `Box<TransferRecord>` (已结清)
- `Box<Member>` + `Box<Group>` (成员/分组)

### 隐私

- 不上传任何数据
- 分享的图片为本地生成本地分享
- 用户偏好: 不上云, 不发推特, 不调用外部 AI API

### 性能

- 100 笔费用 < 1s 计算
- 1000 笔费用 < 3s 计算 (需采样 + 异步)
- 图表渲染 < 500ms

---

## Phase 1 详细设计 (本期)

### 数据模型 (无新增)

```dart
// 复用现有 SettlementEngine.calculateNetBalancesFromExpenses
// 计算: 净收支 / 人均柱状图

// 新增聚合函数 (在 SettlementEngine 旁边)
class ExpenseReport {
  final double totalAmount;
  final int expenseCount;
  final Map<ExpenseCategory, double> byCategory;
  final Map<String, double> byMember; // memberId -> amount
  final List<TimePoint> trend; // (date, amount)
  final DateTime generatedAt;
}
```

### UI 入口

```
旅程详情页
  ├─ 当前 Tab: 费用列表 / 结算 / 分组
  └─ 新 Tab: 报告 (icon: chart)

结算页底部
  └─ 按钮: "查看报告"

归档旅程详情
  └─ 按钮: "查看当时的报告"
```

### UX 流程

```
用户进入报告页
  ↓
显示 loading + 骨架屏 (< 1s)
  ↓
顶卡: 汇总数字 (本期 ¥1234, 8 笔, 人均 ¥411)
  ↓
分类饼图 (油费 30%, 餐饮 25%, 住宿 20%, ...)
  ↓
人均柱状图 (人 1: ¥411, 人 2: ¥300)
  ↓
时间趋势折线 (7 天折线)
  ↓
底部按钮: [分享图片] [导出 Excel - V2.0]
```

---

## V1.3 上架后的具体 PR 计划

### Phase 1 (PR-Z5 ~ PR-Z7, 预计 2-3 周):

**PR-Z5: 报告数据层** (3 天)
- `lib/domain/services/expense_report_service.dart` (聚合计算)
- `test/domain/expense_report_service_test.dart` (汇总/饼图/柱状图/折线数据)
- 无 UI 改动

**PR-Z6: 报告 UI** (5 天)
- `lib/presentation/screens/expense_report_screen.dart` (主页面)
- `lib/presentation/widgets/report_*_chart.dart` (4 个图表 widget)
- `lib/presentation/providers/expense_report_provider.dart` (Riverpod provider)
- 集成到旅程详情页 + 结算页 + 归档页

**PR-Z7: 报告分享 + PDF** (3 天)
- `lib/presentation/utils/share_utils.dart` (生成长图 + 系统分享)
- `screenshot` 包集成 (pubspec.yaml 依赖 + Android 配置)

---

## 时间表 (预计)

| Phase | 工作量 | 截止 |
|---|---|---|
| V1.3 上架 | 4-6 周 | 2026-09-30 (PR-Z 系列完成后) |
| PR-Z5 数据层 | 3 天 | 2026-10 第一周 |
| PR-Z6 UI | 5 天 | 2026-10 第二周 |
| PR-Z7 分享 | 3 天 | 2026-10 第三周 |
| 真机测试 | 1 周 | 2026-10 第四周 |
| **v1.4.0 发布 (含报告功能)** | 2026-11 第一周 |

**注意**: 仅在 V1.3 上架成功后才启动 PR-Z5+。

---

## 关联

- 来源: 用户 2026-07-18 真机测试反馈
- 关联 ISSUE: 待创建 (本期未定 issue, 等 V1.3 上架后创建 ISSUE-042~044)
- 关联 ADR: [ADR-004 E-010 暂缓](ADR-004-prd-v0.3-p0-defer.md), [ADR-008 Phase 1 纯本地](ADR-008-phase1-local-only-cloud-deferred.md)
- 关联决策: 跟 ADR-007 撤销无关, 跟 ADR-008 Phase 1 不冲突

---

## 风险

| 风险 | 概率 | 影响 | 等级 | 缓解 |
|---|---|---|---|---|
| fl_chart 学习曲线 | 中 | 中 | 中 | 先做 PR-Z5 (纯逻辑测试) 不依赖 UI |
| 1000+ 笔费用性能 | 低 | 中 | 低 | 抽样 + 异步 compute |
| 用户不接受报告样式 | 中 | 低 | 低 | PR-Z6 完成后真机测试, 不接受再调整 |
| Phase 2 PDF 库大 | 中 | 低 | 低 | 用户偏好, 可砍掉 PDF |

---

## 待确认

启动 PR-Z5 之前, 需要创始人确认:

- [ ] **范围**: 是否同意 Phase 1 + Phase 2 (不含 Phase 3 AI)
- [ ] **入口**: 3 个入口 (旅程详情 / 结算页 / 归档页) 是否够用
- [ ] **样式**: 4 个图表够用 vs 加 雷达图 / 散点图
- [ ] **时间**: 4-6 周工期可接受

---

*ADR-009 制定时间: 2026-07-18*
*待 V1.3 上架后启动 PR-Z5 数据层*
