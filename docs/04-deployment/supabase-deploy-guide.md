# ☁️ Supabase 部署完整指南

**目标**：让 AI 旅行账本支持云端同步（多设备 + 多人协作）

**预计耗时**：10-15 分钟（首次）

---

## 🎯 前置条件

- [ ] GitHub / Google / 邮箱账号（注册 Supabase 用）
- [ ] 能访问 supabase.com（国内可能需要科学上网）
- [ ] 浏览器 + 已安装的 Flutter 工具链
- [ ] 本项目代码已 clone 到本地

---

## 步骤 1️⃣：注册 Supabase（3 分钟）

### 1.1 打开官网

👉 https://supabase.com

### 1.2 Sign in

推荐用 **GitHub** 账号（最快，开发者都有）。

### 1.3 创建组织（首次访问）

如果提示创建 Organization：
- **Name**: `personal` 或你的名字
- **Plan**: Free
- 点 **Create organization**

---

## 步骤 2️⃣：创建项目（2 分钟）

### 2.1 New Project

点 **+ New Project** 按钮

### 2.2 填表

| 字段 | 推荐值 | 说明 |
|---|---|---|
| **Name** | `ai-travel-ledger` | 项目名（用于 URL，可改） |
| **Database Password** | `随机强密码` | **⚠️ 必须记下来！** 以后改不了 |
| **Region** | `Singapore` 或 `Tokyo` | 离中国最近 |
| **Plan** | `Free` | 够 MVP 用 |

### 2.3 创建

点 **Create new project**

⏳ **等待 1-2 分钟**（Provision + Initialize database）

完成后会跳转到项目 Dashboard。

---

## 步骤 3️⃣：执行 SQL 迁移（3 分钟）

### 3.1 打开 SQL Editor

左侧菜单 → **SQL Editor**（图标：📝）

### 3.2 创建第一个查询

点 **+ New query**

### 3.3 复制 schema SQL

打开本地文件：
```
C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\supabase\migrations\00001_initial_schema.sql
```

**全选复制**（Ctrl+A → Ctrl+C）

粘贴到 SQL Editor 的编辑区。

### 3.4 Run

按 **Ctrl+Enter** 或点右下角 **Run** 按钮

✅ **成功标志**：底部显示 `Success. No rows returned`（因为是 CREATE TABLE 没有 SELECT）

⏱ 耗时：约 2-5 秒

### 3.5 创建第二个查询（RLS 策略）

再点 **+ New query**

打开本地文件：
```
C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\supabase\migrations\00002_rls_policies.sql
```

全选复制 → 粘贴 → **Ctrl+Enter** Run

✅ 成功标志同上

### 3.6 验证表已创建

左侧 → **Table Editor**

应该看到 7 张表：
- profiles
- trips
- trip_members
- trip_groups
- expenses
- transfer_records
- trip_collaborators

每张表都带 RLS 锁图标 🔒

---

## 步骤 4️⃣：获取 API 配置（1 分钟）

### 4.1 打开 API 设置

左侧 → **Settings**（齿轮图标） → **API**

### 4.2 复制 Project URL

在 **Project URL** 区域，复制完整 URL：
```
https://xxxxxxxxxxxxx.supabase.co
```

📋 **记下来！** 步骤 5 要用

### 4.3 复制 anon key

在 **Project API keys** 区域，找到 **anon / public** 这一行：

点 **Copy** 按钮（眼睛图标显示）

会复制一个很长的 JWT 字符串：
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
```

📋 **记下来！** 步骤 5 要用

⚠️ **注意**：还有一行 `service_role` key，**绝对不要**给 APP 用，那是管理员权限！

---

## 步骤 5️⃣：启动 APP 并连接（2 分钟）

### 5.1 打开 PowerShell

进入项目目录：
```bash
cd C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger
```

### 5.2 启动命令

把下面的命令中的 `<URL>` 和 `<KEY>` 替换成步骤 4 复制的值：

```bash
flutter run --dart-define=SUPABASE_URL=<URL> --dart-define=SUPABASE_ANON_KEY=<KEY>
```

**示例**（不要直接复制）：
```bash
flutter run --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGc...sCN0M
```

⏱ 首次启动会编译 Dart 代码（约 30 秒）

### 5.3 APP 启动后

你应该看到：
- ✅ 右上角 ☁️ 云朵图标（灰色 = 未登录）
- ✅ 点开是登录/注册页面（不再显示"云端同步未启用"）

---

## 步骤 6️⃣：注册账号并验证（3 分钟）

### 6.1 注册

1. 点右上角 ☁️ 图标
2. 切到 **注册** 标签
3. 填：
   - **邮箱**: `你的真实邮箱`（用于接收验证邮件）
   - **密码**: ≥6 位
   - **昵称**: 任意（可选）
4. 点 **注册**

### 6.2 验证邮箱（重要！）

默认 Supabase 要求邮箱验证：
- 查收你的邮箱
- 找到来自 Supabase 的邮件
- 点 **Confirm your email** 链接

如果不验证，可能登录失败或功能受限。

### 6.3 回到 APP 登录

返回 APP，输入邮箱 + 密码，点 **登录**

✅ 成功标志：
- 自动回到首页
- ☁️ 图标变绿色 ✓
- 顶部弹出 SnackBar "✅ 登录成功"

---

## 步骤 7️⃣：测试同步（2 分钟）

### 7.1 创建测试数据

1. 在 APP 内创建一个简单旅程（如 "测试"）
2. 添加 1 个成员
3. 添加 1 笔费用

### 7.2 查看云端

回到 Supabase Dashboard：

左侧 → **Table Editor** → **trips**

✅ 你应该看到刚才创建的旅程！

### 7.3 多端同步测试

1. 关掉 APP
2. 再启动 APP
3. ✅ 数据应该还在（从云端拉取）

---

## 🎉 完成！

如果全部通过，恭喜你的 APP 已支持云端同步！

---

## ⚠️ 常见问题

### Q1: 注册后登录失败

**原因**：邮箱没验证

**解决**：查收邮箱，点确认链接

### Q2: 启动 APP 后 ☁️ 图标还是灰色

**原因**：dart-define 没传对

**检查**：
```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
URL 必须以 `https://` 开头，以 `.supabase.co` 结尾

### Q3: SQL 执行失败

**可能原因**：表已存在（之前执行过）

**解决**：到 SQL Editor，先删除已存在的表再重跑：
```sql
DROP TABLE IF EXISTS public.transfer_records CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.trip_groups CASCADE;
DROP TABLE IF EXISTS public.trip_members CASCADE;
DROP TABLE IF EXISTS public.trip_collaborators CASCADE;
DROP TABLE IF EXISTS public.trips CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TYPE IF EXISTS public.trip_status CASCADE;
DROP TYPE IF EXISTS public.member_role CASCADE;
DROP TYPE IF EXISTS public.group_type CASCADE;
DROP TYPE IF EXISTS public.expense_category CASCADE;
DROP TYPE IF EXISTS public.collaborator_role CASCADE;
```
然后重新执行迁移文件。

### Q4: 国内访问 Supabase 很慢

**原因**：服务器在新加坡/东京

**缓解**：
- 临时方案：科学上网
- 长期方案：迁移到国内服务（如 CloudBase、LeanCloud）

### Q5: 想删除整个项目

Supabase Dashboard → Settings → General → **Delete project**

⚠️ 不可恢复！

---

## 📊 容量监控

Dashboard 左侧 → **Settings** → **Usage**

免费层限制：
- 数据库: 500 MB
- 存储: 1 GB
- 流量: 2 GB/月
- 月活: 50,000

按 AI 旅行账本估算：
- 1 万 trips ~ 50 MB
- 10 万 expenses ~ 200 MB
- **完全够用 MVP 阶段**

---

## 🔐 安全提示

- ✅ Supabase 已自动启用 RLS（我们写的策略）
- ✅ 即使前端被绕过，数据库层也保安全
- ⚠️ anon key 可以给客户端，但 service_role key 绝对不要
- ⚠️ 上线前建议开启 Email Confirm（默认开启）

---

## 🚦 下一步

部署完成后，建议：
1. **邀请 1-2 个朋友试用**（邀请他们注册）
2. **用 1 周真实数据**测试稳定性
3. **检查 Supabase Logs** 看有没有报错

如果有问题，看 `docs/02-architecture/05-supabase-schema.md` 和 `06-e2e-verification-report.md`。

---

*生成时间：2026-07-04*