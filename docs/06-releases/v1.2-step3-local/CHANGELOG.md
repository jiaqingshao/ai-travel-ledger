# AI 旅行账本 v1.2-step3 - ISSUE-026 step 3 (费用列表徽章)

**发布日期**: 2026-07-12 22:40 (Asia/Shanghai)
**版本号**: 1.0.0+0 (versionName 1.0.0, versionCode 1) — pubspec 同步
**里程碑**: V1.2 附件功能 · Step 3 of 5
**APK 大小**: 24.7 MB
**APK 文件**: `../../release/v1.2-step3-local/ai-travel-ledger-v1.2-step3.apk`
**APK SHA1**: `fd608a7f961a0be07972a6f66877e5da674bd681`
**Git tag**: 无（中间产物，未打 tag）
**对应 commit**: `e21cc14` (列表徽章)

> 这是 V1.2 附件功能的 **第 3 步构建产物**，**不是 GA 版本**。
> 仅用于 V1.2-step3 期间的真机演示和回归测试。
> GA 版本见 [`../v1.2.0+0-cloud/`](../v1.2.0+0-cloud/) 或 [`../v1.2.0+0-cloud-milestone/`](../v1.2.0+0-cloud-milestone/)。

---

## 📦 本版本核心内容 = ISSUE-026 step 3

### Step 3: 费用列表附件徽章（📎 数字）

| 改动点 | 说明 |
|---|---|
| `expense_list` 卡片 trailing 区域 | 加了一个 `Column` 显示附件数 |
| 显示规则 | 仅 `attachments.length > 0` 时显示 |
| UI 样式 | 📎 emoji + 数字（如 `📎 3`） |
| 4 个新增测试 | test/ 验证显示条件 / 数字正确性 / 0 附件不显示 |

### 相对前版增量（单一 commit）

```text
+1 commit: e21cc14 feat(attachments): ISSUE-026 step 3 费用列表附件徽章 (📎 数字)
+4 tests:   list_badge 单元测试
```

### 配套 Step 1 / 2（已含）

- 数据模型 + Repository + Supabase Storage 上传（Step 1, `34355b4`）
- UI 集成 + 拍照/选图/预览（Step 2, `13aaaff` + `1574451`）

---

## 🆕 Step 3 新增的用户体验

打开任意**有附件**的旅程 → 进费用列表 → 看到每条费用右下角：

```
共 350.00          📎 1
11:23 加油         ◀
                   报销
```

费用列表浏览效率提升：**一眼看到哪些费用有票据**，不用点进详情看。

---

## 📊 测试

238/238 全过（Step 3 新增 4 个 expense_list badge 测试）

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 APK 到手机
3. **必须先卸载旧版** (新 keystore 签名)
4. 安装后桌面显示"AI 旅行账本"

---

## ⚠️ 已知问题

- ❌ 行程汇总页不显示附件总数 → **Step 4 修**（commit `76be70e` 已含，但本 APK 不含）
- ❌ 不支持批量下载附件 → **Step 5 候选**（未排期）

> 本 APK 是**中间产物**，建议直接用 GA 版 `v1.2.0+0-cloud` 体验完整功能。

---

## 🔄 升级路径

```text
v1.0.0-local → v1.2-step2-local → v1.2-step3-local (本版本) → v1.2-step4-local → v1.2.0+0-cloud (GA)
```

---

*归档时间: 2026-07-15 (基于 V1.2-cloud-milestone 发布后的 release/ 目录规范化)*
