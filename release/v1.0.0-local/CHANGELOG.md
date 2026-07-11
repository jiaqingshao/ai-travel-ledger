# AI 旅行账本 v1.0.0 - 本地模式

**发布日期**: 2026-07-11
**版本号**: 1.0.0+0 (versionName 1.0.0, versionCode 1)
**模式**: 本地 (local-only)
**APK 大小**: 24.1 MB
**SHA1**: `e0496c34755f02bfff03bbc66d0fd764e0371f1c`

---

## 📱 本地模式 (无云同步)

- 右上角 ☁️ 图标保持**灰色** (未连接 Supabase)
- 数据存储在本地 Hive
- 卸载 APP = 数据清空
- 不依赖网络, 完全离线可用
- 适合: 不想注册 / 试用 / 一次性短途旅行

---

## ✨ 包含 V1.1 编辑能力

- **SplitRuleEditPage**: 分摊规则全屏编辑器 (5 种分摊模式)
- **费用详情编辑**: 金额/类别/备注/付款人/时间/分摊规则/附件 全部可改
- **保存并继续按钮**: 费用录入流优化 (ISSUE-023-RECONFIRM 修复)
- **键盘遮挡修复**: TextField 加 scrollPadding=200 (ISSUE-022)
- **登录友好提示**: 邮箱未验证有专门提示 (ISSUE-021)
- **结算空状态**: 0 成员旅程有 EmptyView (ISSUE-020)

---

## 🆕 相比旧 v0.2.0+2 的新增

- **应用名本地化**: 中文手机显示"AI 旅行账本"，英文手机显示"AI Travel Ledger"
  - 旧版显示 `ai_travel_ledger` (Flutter 默认 ID)
- **Supabase 配置可选化**: 不需要任何配置就能跑
  - 旧版 APK 不含 Supabase 配置但脚本强制要求，本版完全自包含
- **Pubspec 版本对齐**: 1.0.0+0 与 CHANGELOG 一致

---

## 📊 测试

228/228 全过

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 APK 到手机 (微信文件传输 / USB / 邮件)
3. **必须先卸载旧版** (新 keystore 签名不同)
4. 点击安装 → 看到"AI 旅行账本"出现在桌面
5. 直接使用，无需注册

---

## ⚠️ 升级重要提示

- **必须先卸载旧版** (签名不同, 否则装不上)
- 卸载前如需保留数据：先用旧版导出或截图（当前版本暂无导入导出功能）
- 本地模式没有云备份, **重装 = 数据清空**

---

## 🔄 升级到云同步版本

如果想用云同步 (多设备同步 + 数据备份):

```powershell
# 1. 注册 Supabase 账号 (https://supabase.com)
# 2. 获取 URL 和 anon key
# 3. 设置环境变量 + 重新构建
$env:SUPABASE_URL = "https://xxx.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJ..."
pwsh scripts/build-with-supabase.ps1
# 输出: release\ai-travel-ledger-v1.0.0-cloud.apk
```

云版本可以混合装：旧版本地数据 → 卸载 → 装云版本 → 注册账号 → 手动重新录入（或后续做导入功能）