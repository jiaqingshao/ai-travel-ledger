# AI 旅行账本 v1.2-step4 - ISSUE-026 step 4 (行程汇总页附件总数)

**发布日期**: 2026-07-13 00:06 (Asia/Shanghai)
**版本号**: 1.0.0+0 (versionName 1.0.0, versionCode 1) — pubspec 同步
**里程碑**: V1.2 附件功能 · Step 4 of 5
**APK 大小**: 24.7 MB
**APK 文件**: `../../release/v1.2-step4-local/ai-travel-ledger-v1.2-step4.apk`
**APK SHA1**: `af03b6abf5990e8c5965c399daccdd13616bbe91`
**Git tag**: 无（中间产物，未打 tag）
**对应 commit**: `76be70e` (汇总页附件总数)

> 这是 V1.2 附件功能的 **第 4 步构建产物**，**不是 GA 版本**。
> 仅用于 V1.2-step4 期间的真机演示和回归测试。
> GA 版本见 [`../v1.2.0+0-cloud/`](../v1.2.0+0-cloud/) 或 [`../v1.2.0+0-cloud-milestone/`](../v1.2.0+0-cloud-milestone/)。

---

## 📦 本版本核心内容 = ISSUE-026 step 4

### Step 4: 行程汇总页附件总数（「本旅程 X 张附件」）

| 改动点 | 说明 |
|---|---|
| `trip_summary_screen` 头部 | 加一行「本旅程 X 张附件」 |
| 显示规则 | 仅 `sum(attachments.length) > 0` 时显示 |
| 数据来源 | 复用 Step 1 的 `attachments: text[]` 字段，直接 SUM |

### 相对前版增量（单一 commit）

```text
+1 commit: 76be70e feat(attachments): ISSUE-026 step 4 行程汇总页附件总数
```

### 配套 Step 1 / 2 / 3（已含）

- 数据模型 + Repository + Supabase Storage 上传（Step 1）
- UI 集成（Step 2）
- 费用列表附件徽章（Step 3）

---

## 🆕 Step 4 新增的用户体验

进入任意旅程汇总页 → 顶部摘要卡片下：

```
📊 行程汇总
本旅程 7 张附件        ← 新增
─────────────────────
总支出 ¥3,580.00
人均 ¥510.00
...
```

**报销前一眼看出本旅程积累了多少票据**，方便核对 vs. 实际报销材料。

---

## 📊 测试

250/250 全过（Step 4 不新增 test，沿用 Step 1-3 全部）

> 注: Step 4 是单一 commit 行为增强，无需新测试，沿用 Step 1-3 测试覆盖。

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 APK 到手机
3. **必须先卸载旧版**
4. 安装后桌面显示"AI 旅行账本"

---

## ⚠️ 已知问题

- ❌ 不支持批量下载附件 → **Step 5 候选**（未排期）
- ❌ 附件暂不支持裁剪 / 旋转 → V1.3 候选

> 本 APK 是**中间产物**，建议直接用 GA 版 `v1.2.0+0-cloud` 体验完整功能。

---

## 🔄 升级路径

```text
v1.0.0-local → v1.2-step2-local → v1.2-step3-local → v1.2-step4-local (本版本) → v1.2.0+0-cloud (GA)
```

Step 4 是 V1.2 拆分 5 步的**倒数第 2 步**（Step 5 长按下载 ZIP 是可选候选，未实施）。

---

*归档时间: 2026-07-15 (基于 V1.2-cloud-milestone 发布后的 release/ 目录规范化)*
