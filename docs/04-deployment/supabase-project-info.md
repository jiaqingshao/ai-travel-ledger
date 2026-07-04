# Supabase 项目配置信息

**创建日期**：2026-07-04  
**关联部署指南**：[supabase-deploy-guide.md](supabase-deploy-guide.md)

---

## 📋 项目基本信息

| 字段 | 值 |
|---|---|
| **项目名** | `ai-travel-ledger` |
| **Project URL** | `https://zvqnawllsdmisntkxdwp.supabase.co` |
| **Project ID** | `zvqnawllsdmisntkxdwp` |
| **Region** | `Singapore`（推断） |
| **Plan** | Free |

---

## 🔑 API Keys

### anon public key（可给客户端）

⚠️ **未在此文件中明文保存**。请从 Supabase Dashboard 获取：

1. https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp/settings/api
2. 找到 **Project API keys** → **anon / public**
3. 点 📋 复制（以 `eyJ...` 开头）

### service_role key（仅服务端）

⚠️ **永远不要暴露给客户端**。此文件不记录。

---

## 🗄 数据库密码

⚠️ **不在文件中明文保存**。

如果忘记，可重置：
1. Settings → Database → Connection string → Reset database password

---

## 🚀 启动命令模板

复制以下命令，把 `<ANON_KEY>` 替换成你从 Dashboard 复制的 anon key：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://zvqnawllsdmisntkxdwp.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

⚠️ **绝对不要**把完整命令（含 key）提交到 git 或明文聊天。

---

## 🔄 更新流程

如果未来更换项目：
1. 更新本文件的 Project URL
2. 重新获取 anon key
3. 删除旧的 dart-define 命令

---

*最后更新：2026-07-04*