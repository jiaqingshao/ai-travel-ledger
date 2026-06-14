# ADR-002: 选择 Supabase 作为后端 BaaS

**状态**: 已采纳
**日期**: 2026-06-14
**决策者**: 创始人

---

## 背景

我们需要一个后端服务来支撑 AI 旅行账本，包括：
- 用户认证
- 数据存储（多用户、多设备同步）
- 文件存储（账目照片）
- 实时同步（多人协作）

创始人无后端运维经验，需要尽量减少运维负担。

## 候选方案

### 方案 1: Supabase ✅
- 开源 Firebase 替代
- Postgres + Auth + Storage + Realtime
- 免费层够用 MVP

### 方案 2: Firebase
- 谷歌系，生态大
- 但 NoSQL 不擅长复杂关系查询
- 收费按用量，免费层很抠

### 方案 3: 自建 Node.js + Postgres
- 灵活
- 但运维成本高

### 方案 4: LeanCloud
- 国内服务
- 但文档差、生态弱

### 方案 5: 阿里云
- 国内合规
- 但运维复杂

## 决策

**选择 Supabase**

## 理由

| 维度 | 评估 |
|---|---|
| 一体化 | ✅ Postgres + Auth + Storage + Realtime 全包 |
| 免费层 | ✅ 500MB DB / 2GB 流量 / 1GB 存储（MVP 够用）|
| Postgres | ✅ 强类型，复杂关系查询得心应手 |
| Flutter SDK | ✅ 官方支持 |
| 开源 | ✅ 数据量大时可自托管，避免锁定 |
| 实时 | ✅ 多端同步天然支持 |

## 后果

### 正面
- 零运维，专注产品
- 复杂业务逻辑用 Postgres 存储过程
- 多端实时同步开箱即用

### 负面 / 风险
- **数据在境外**（AWS Singapore），国内访问可能慢
- 免费层有上限（500MB DB / 50K 月活）
- Supabase 倒闭风险（虽然开源，可自托管）

### 缓解措施
- 国内体验问题：V1.0 验证后考虑迁移到国内 Supabase 替代（如 CloudBase）
- 容量问题：用户超 500 后考虑 Pro 计划（$25/月）
- 倒闭风险：Postgres 通用，可迁移到自建

## 关键配置

```dart
// lib/core/config.dart
class SupabaseConfig {
  static const url = 'https://xxx.supabase.co';
  static const anonKey = 'eyJ...';
  
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
```

## 备注

- 使用 **RLS (Row Level Security)** 做权限控制
- 数据库迁移使用 `supabase migration` 命令
- 监控用 Supabase Dashboard
