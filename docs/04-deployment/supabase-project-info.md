# Supabase 项目配置信息

**创建日期**：2026-07-04
**最近更新**：2026-07-14（用户明示"无需担心安全"，dev key 入仓以便 CI/同事直接复用）
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

### anon public key（客户端 key）

✅ **已入仓**（用户 2026-07-14 明示"无需担心安全"，是 anon public key 本身设计就是客户端可见）：

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2cW5hd2xsc2RtaXNudGt4ZHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNjMzMDgsImV4cCI6MjA5ODczOTMwOH0.ks76ZCejHu-xd9NCt9muHoboX5wzY7_zBowGVSTULpI
```

**解码后的 JWT payload**：
```json
{
  "iss": "supabase",
  "ref": "zvqnawllsdmisntkxdwp",
  "role": "anon",
  "iat": 1783163308,    // 2026-07-04 颁发
  "exp": 2098739308     // 2036-07-04 过期
}
```

> **设计说明**：anon key 是 JWT，本身就是为了嵌入客户端而设计的。实际数据库/存储权限由 RLS 策略保护，拿到 anon key ≠ 拿到数据访问权。
> **风险评估**：泄露 anon key 的影响 = 任何知道项目 URL 的人可以发请求，但**所有写操作受 RLS 限制**，所以"增加费用/改成员"等都仍需要登录。
> **保护策略**：service_role key 仍不入仓（能 bypass RLS，绝不外传）。

**对照位置**（dev 三选一，推荐 file）：
- `\.secrets\cloud-key.txt`（gitignore，推荐本地）
- `env:SUPABASE_ANON_KEY`（CI 首选）
- 直接 `-Key` 参数（临时）

### service_role key（仅服务端）

⚠️ **永远不要暴露给客户端**。此文件不记录。

---

## 🗄 数据库密码

⚠️ **不在文件中明文保存**。

如果忘记，可重置：
1. Settings → Database → Connection string → Reset database password

---

## 🚀 启动命令模板

**运行时注入**（适用 dev 调试）：
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://zvqnawllsdmisntkxdwp.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2cW5hd2xsc2RtaXNudGt4ZHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNjMzMDgsImV4cCI6MjA5ODczOTMwOH0.ks76ZCejHu-xd9NCt9muHoboX5wzY7_zBowGVSTULpI
```

**便捷脚本**（V1.2+ 推荐）：
```powershell
# 一次性写入文件后随时可用（gitignore 隔离）
mkdir .secrets
echo eyJhbGciOiJIUzI1NiIs... > .secrets\cloud-key.txt

# 一行命令构建云端 APK
pwsh scripts\build-cloud.ps1

# 输出：release\v1.2.0+0-cloud\ai-travel-ledger-v1.2.0+0-cloud.apk
```

> anon key 本身设计就是公开的（anon public），泄露影响有限（RLS 兜底）。
> 但建议仍用 `.secrets/` 隔离以免误传到非 key 文件。
> **绝对不要**提交 service_role key（那个能 bypass RLS）。

---

## 🔄 更新流程

如果未来更换项目：
1. 更新本文件的 Project URL
2. 重新获取 anon key
3. 把新 key 写到 `.secrets\cloud-key.txt`
4. 同步更新 `scripts\build-cloud.ps1` 内的 URL 常量（如有变动）

---

## 📦 构建脚本清单 (V1.2+ 2026-07-14 新增)

| 脚本 | 用途 | 输出 |
|------|------|------|
| `scripts\build-apk.ps1` | 通用构建（自动检测模式）| `release\vX.Y.Z+NN-{local\|cloud}.apk` |
| `scripts\build-local.ps1` | 强制本地模式 | `release\vX.Y.Z+NN-local.apk` |
| `scripts\build-with-supabase.ps1` | 强制 Supabase 模式（需手动 env） | `release\vX.Y.Z+NN-cloud.apk` |
| 🆕 `scripts\build-cloud.ps1` | **便捷云端**（URL 写死，自动找 key） | `release\vX.Y.Z+NN-cloud.apk` |

> 本项目 npm 层推荐用 `build-cloud.ps1` (找 key 自动化)，仅在 URL 变更时手动用 `build-with-supabase.ps1`。

---

*最后更新：2026-07-14*
