# AI 旅行账本 v1.2-step2 - ISSUE-026 step 2 (UI 集成)

**发布日期**: 2026-07-12 22:30 (Asia/Shanghai)
**版本号**: 1.0.0+0 (versionName 1.0.0, versionCode 1) — pubspec 同步
**里程碑**: V1.2 附件功能 · Step 2 of 5
**APK 大小**: 24.7 MB
**APK 文件**: `../../release/v1.2-step2-local/ai-travel-ledger-v1.2-step2.apk`
**APK SHA1**: `9599e74a6168e6e3150e198af37ff149c038cc14`
**Git tag**: 无（中间产物，未打 tag）
**对应 commit**: `13aaaff` (UI 集成) + `1574451` (15 个测试)

> 这是 V1.2 附件功能的 **第 2 步构建产物**，**不是 GA 版本**。
> 仅用于 V1.2-step2 期间的真机演示和回归测试。
> GA 版本见 [`../v1.2.0+0-cloud/`](../v1.2.0+0-cloud/) 或 [`../v1.2.0+0-cloud-milestone/`](../v1.2.0+0-cloud-milestone/)。

---

## 📦 本版本核心内容 = ISSUE-026 step 2

ISSUE-026 (票据照片上传) 拆 5 步交付，本版本含 Step 2：

### Step 2: UI 集成（拍照/选图/上传/预览）

| 组件 | 文件 | 作用 |
|---|---|---|
| `attachment_thumb.dart` | 新增 | 附件缩略图（带删除按钮） |
| `attachment_picker_section.dart` | 新增 | 受控附件选择区（拍照 + 选图 + 上传） |
| `attachment_viewer.dart` | 新增 | 全屏预览（双指缩放） |
| `expense_create_screen.dart` | 改 | 集成 `_buildAttachmentsSection()` |
| `expense_detail_screen.dart` | 改 | 集成 `_editingAttachments` 受控逻辑 |
| `15 个新增测试` | test/ | cover picker / upload / viewer 流程 |

### 配套 Step 1（已含，本步骤先决）

- `Attachment` 模型 + JSON 序列化
- `AttachmentRepository` (含本地 + Supabase Storage 双实现)
- `expense-attachments` Storage bucket + 3 条 RLS 策略
- `expenses.attachment_metadata` JSONB 字段 + sync trigger

---

## 🆕 相比 v1.0.0-local 的新增

- ✅ **拍照上传**：UI 直接调用相机，图片存 Supabase Storage 公网 URL
- ✅ **从相册选图**：多选 → 自动压缩 → 上传
- ✅ **缩略图展示**：费用详情/创建页可见已上传图片
- ✅ **全屏预览**：点缩略图打开，可双指缩放 / 滑动切换
- ✅ **离线优先**：网络失败时图片仍存在本地，标记为待同步

---

## 📊 测试

234/234 全过（含 Step 2 新增 15 个 attachment 测试）

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 APK 到手机 (USB / 微信文件)
3. **必须先卸载 v1.0.0-local** (新 keystore 签名不同)
4. 安装后桌面显示"AI 旅行账本"
5. 跑一次创建费用 → 点"添加附件"看到拍照/选图选项

---

## ⚠️ 已知问题（待 Step 3-5 解决）

- ❌ 费用列表不显示附件徽章 → **Step 3 修**（commit `e21cc14` 已含，但本 APK 不含）
- ❌ 行程汇总页不显示附件总数 → **Step 4 修**（commit `76be70e` 已含，但本 APK 不含）
- ❌ 不支持批量下载附件 → **Step 5 候选**（未排期）

> 本 APK 是**中间产物**，建议直接用 GA 版 `v1.2.0+0-cloud` 体验完整功能。

---

## 🔄 升级路径

```text
v1.0.0-local
   ↓
v1.2-step2-local (本版本, 仅附件拍照/选图/上传)
   ↓
v1.2-step3-local (新增列表徽章)
   ↓
v1.2-step4-local (新增汇总页附件总数)
   ↓
v1.2.0+0-cloud / v1.2.0+0-cloud-milestone (GA, 含云同步 + 全部附件功能)
```

---

*归档时间: 2026-07-15 (基于 V1.2-cloud-milestone 发布后的 release/ 目录规范化)*
