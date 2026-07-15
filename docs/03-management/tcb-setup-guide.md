# 🇹🇼 腾讯云开发 CloudBase (TCB) 申请流程

> ⚠️ **⏸️ 此文档已 DEPRECATED** (2026-07-15 13:50)
>
> **原因**: 创始人复查发现 TCB 个人版 = ¥19.9/月 (不是免费), 不符合约束
>
> **新决策**: [ADR-008](../02-architecture/04-adr/ADR-008-phase1-local-only-cloud-deferred.md) **Phase 1 纯本地模式**, 云功能 V2.0 启用
>
> **本文档保留原因**: 作为决策历史 + V2.0 启用云时可参考
>
> ---
>
> **目标**: 用最少时间、最低费用开通 TCB 服务，为 V1.3 国内 Android 上架做准备。
> **阅读时间**: 10 分钟 ｜ **操作时间**: 30-60 分钟（含实名认证等待）
> **最后更新**: 2026-07-15 (deprecated 2026-07-15 13:50)

---

## 📋 完整流程时间预估

| 阶段 | 你做的事 | 耗时 |
|---|---|---|
| **Step 1** 注册腾讯云账号 | 微信扫码 + 手机号 | 5 分钟 |
| **Step 2** 个人实名认证 | 身份证照片 + 人脸识别 | 10 分钟 + 等 5-10 分钟 |
| **Step 3** 开通 CloudBase | 创建环境 + 选 PG + 开通 | 10 分钟 |
| **Step 4** 获取 API 密钥 | 复制 SecretId/SecretKey | 5 分钟 |
| **Step 5** 创建数据库 + Storage | 在控制台建表 + bucket | 15 分钟（自动 SQL） |
| **Step 6** 配置域名 ICP 备案 | （V1.3 上架前再办） | 7-10 天 |
| **总计** | 立即能做的部分 | **45-60 分钟** |

---

## Step 1: 注册腾讯云账号

### 1.1 入口

打开 https://cloud.tencent.com/

### 1.2 注册

1. 右上角 **"注册"**
2. 选择 **"微信扫码注册"**（最快）或 **"邮箱注册"**
3. 微信扫码 → 自动填充手机号 → 输入验证码
4. 设置登录密码

### 1.3 必填信息

| 字段 | 你的填写 |
|---|---|
| 账号 ID | （系统自动生成） |
| 昵称 | AI 旅行账本 |
| 实名信息（Step 2） | — |

---

## Step 2: 个人实名认证

### ⚠️ 必须你自己做（涉及身份证 / 人脸）

### 2.1 入口

账号登录后，访问 https://console.cloud.tencent.com/developer

### 2.2 路径

**控制台 → 右上角头像 → 账号信息 → 实名认证**

### 2.3 选择认证方式

| 方式 | 时长 | 通过率 |
|---|---|---|
| **个人认证（推荐）** | 10 分钟 + 等 5-10 分钟 | 🟢 100% |
| 企业认证 | 需营业执照 | 不需要 |

### 2.4 个人认证流程

```
1. 上传身份证正面（清晰）
2. 上传身份证反面（清晰）
3. 人脸识别（微信小程序"腾讯云助手"扫码完成）
4. 等待 5-10 分钟（极少数情况需 24 小时）
5. 状态变"已认证" ✓
```

### 2.5 实名信息用途

- 腾讯云合法运营要求
- ICP 备案会用到（V1.3 上架前再做）
- 后续**无法更换主体**（身份证绑定 = 账号绑定）

---

## Step 3: 开通 CloudBase

### 3.1 入口

打开 https://console.cloud.tencent.com/tcb

> URL 也可走：控制台首页 → 搜索 "CloudBase" → 进入

### 3.2 创建环境

1. 点击 **"新建环境"**
2. 填写：

| 字段 | 推荐值 |
|---|---|
| 环境名称 | `ai-travel-ledger-prod`（生产）<br>`ai-travel-ledger-dev`（开发） |
| 计费模式 | **包年包月**（不选按量付费，否则可能产生费用） |
| 环境套餐 | **基础版**（个人开发者免费层）|
| 地域 | **上海** 或 **广州**（推荐上海，离你近） |

3. 点击 **"立即开通"**
4. 等 1-3 分钟（环境初始化）

### 3.3 创建第二个环境（开发用）

重复上述，命名 `ai-travel-ledger-dev`，地域同上。

> ⚠️ 两个环境**独立计费资源**，但都在免费层内

---

## Step 4: 获取 API 密钥

### 4.1 入口

打开 https://console.cloud.tencent.com/cam/capi

### 4.2 创建密钥

1. **"新建密钥"** → 系统自动生成
2. 复制两个值：

```
SecretId: AKIDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SecretKey: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> ⚠️ **SecretKey 仅显示一次**——保存到密码管理器（1Password / Bitwarden）

### 4.3 必要的权限

密钥默认权限已足够 CloudBase 使用。如果后续报错，再补：

- `QcloudTCBFullAccess` （CloudBase 全访问）
- `QcloudCOSFullAccess` （对象存储访问）

---

## Step 5: 在 CloudBase 控制台创建数据库

### 5.1 进入数据库

CloudBase 控制台 → 选择 `ai-travel-ledger-dev` 环境 → **数据库** → **创建集合**

### 5.2 创建 7 张表（与 Supabase schema 对齐）

> ⚠️ **创建后给主 Agent（我）做 schema 翻译**——你不需要手动写

#### 表 1: profiles

| 配置项 | 值 |
|---|---|
| 集合名称 | `profiles` |
| 权限设置 | **仅创建者可读写** |
| 字段 | `_id, _openid, email, nickname, avatar_url, created_at, updated_at` |

#### 表 2: trips

| 配置项 | 值 |
|---|---|
| 集合名称 | `trips` |
| 权限设置 | **仅创建者及协作者可读写** |
| 字段 | `id, owner_id, name, destination, start_date, end_date, base_currency, created_by, archived, created_at, updated_at` |

#### 表 3: members

| 配置项 | 值 |
|---|---|
| 集合名称 | `members` |
| 权限设置 | **仅创建者及所属 trip 协作者可读写** |
| 字段 | `id, trip_id, nickname, role, avatar_color, archived, created_at, updated_at` |

#### 表 4: groups

| 配置项 | 值 |
|---|---|
| 集合名称 | `groups` |
| 权限设置 | **同 trip 的协作者可读写** |
| 字段 | `id, trip_id, name, type, color, member_ids, created_at, updated_at` |

#### 表 5: expenses

| 配置项 | 值 |
|---|---|
| 集合名称 | `expenses` |
| 权限设置 | **同 trip 的协作者可读写** |
| 字段 | `id, trip_id, payer_id, category, amount, currency, expense_date, note, split_type, split_rule_json, attachments, attachment_metadata, sync_status, created_at, updated_at, deleted_at` |

#### 表 6: transfers

| 配置项 | 值 |
|---|---|
| 集合名称 | `transfers` |
| 权限设置 | **同 trip 的协作者可读写** |
| 字段 | `id, trip_id, from_member_id, to_member_id, amount, currency, created_at, settled` |

#### 表 7: trip_collaborators

| 配置项 | 值 |
|---|---|
| 集合名称 | `trip_collaborators` |
| 权限设置 | **trips owner 可读写** |
| 字段 | `id, trip_id, user_id, role, invited_by, created_at` |

### 5.3 创建云存储 bucket

CloudBase 控制台 → **存储** → **创建存储桶**

| 配置项 | 值 |
|---|---|
| 名称 | `expense-attachments` |
| 权限 | **公有读私有写**（附件访问用） |
| 地域 | 上海 / 广州 |

---

## Step 6: 给我（主 Agent）的输入

完成 Step 1-5 后，把下列信息给我：

```yaml
# TCB credentials (你给我时, 建议用 1Password 分享链接)
TCB_SECRET_ID: "AKID..."
TCB_SECRET_KEY: "..."
TCB_ENV_ID: "ai-travel-ledger-dev-xxxxx"  (在控制台环境详情页)
TCB_STORAGE_BUCKET: "expense-attachments"
```

我会立刻开始：
1. 配置 `lib/core/tcb/` 集成代码（用 cloudbase_sdk）
2. 写 7 张表的数据层代码
3. 迁移 auth 流程（邮箱 + 密码 → TCB 自定义登录）
4. 迁移 storage（拍照/选图 → TCB 云存储）
5. 写测试用例
6. 让你真机回归测试

---

## ⚠️ ICP 备案（Step 6 - V1.3 上架前再做）

### 为什么需要

- 国内所有提供 HTTP 服务的 App **必须有 ICP 备案**
- App 后端域名 `https://your-app.tcloudbaseapp.com` 需要备案
- 不备案：警告 → 下架 → 罚款

### 申请入口

- 备案系统：https://console.cloud.tencent.com/beian
- 文档：https://cloud.tencent.com/product/ba

### 时长

- **个人备案**：7-10 工作日
- **企业备案**：10-15 工作日

### 需要的资料

- 身份证
- 联系方式
- App 包名 / 域名 / 服务类型
- **前置：必须先有 R011 软著**（国内主流商店都要求）

### 顺序

```
1. 申请 R011 软件著作权（1-2 月，¥300-800）
2. 软著下来 → 申请 ICP 备案（7-10 工作日）
3. ICP 下来 → V1.3 上架提交
```

---

## 🛑 不要做的事

| ❌ 错误 | 后果 |
|---|---|
| 在私人环境用付费设置 | 产生费用 |
| 把 SecretKey 发给非信任方 | 盗刷风险 |
| 实名后换身份证 | 实名后绑定 |
| 跳过 ICP 备案直接上架 | 被举报下架 + 罚款 |
| 同一身份证注册多个腾讯云账号 | 实名信息冲突 |

---

## 📞 出错时

| 问题 | 解决方案 |
|---|---|
| 实名认证失败 | 检查身份证是否清晰；用微信小程序"腾讯云助手"重新人脸 |
| SecretKey 丢失 | 在 https://console.cloud.tencent.com/cam/capi 重新生成 |
| 配额超限 | 查看免费层额度（2 GB DB / 5 GB 存储） |
| CloudBase API 报错 | 看 https://docs.cloudbase.net/ 文档 |

---

## ✅ 完成 checklist

```
□ Step 1: 注册腾讯云账号（5 min）
□ Step 2: 个人实名认证（10 min + 等待）
□ Step 3: 创建 2 个 CloudBase 环境（dev + prod）（10 min）
□ Step 4: 获取 API 密钥（5 min）
□ Step 5: 创建 7 张 MongoDB 集合 + 1 个存储桶（让主 Agent 代做更省事）
□ Step 6: 把密钥给主 Agent（我）
□ V1.3 上架前: 申请 R011 软著（1-2 月）
□ V1.3 上架前: ICP 备案（7-10 工作日）
```

---

*完成后告诉我 SecretId + SecretKey + EnvId 三件套，我立刻开始 R012 迁移代码工作。*
*预计你 V1.3 准备 + 我代码迁移 = 共 5-7 周内 V1.3 国内可上架。*

---

**详细文档**: [ADR-007](../02-architecture/04-adr/ADR-007-r012-tcb-migration.md)
**风险登记**: [R012 risk-register.md](risk-register.md)
