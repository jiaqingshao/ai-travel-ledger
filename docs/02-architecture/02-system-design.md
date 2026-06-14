# 系统架构设计 (System Design)

**版本**: v0.1
**日期**: 2026-06-14

---

## 一、整体架构

```
┌──────────────────────────────────────────────────────────────┐
│                  Flutter App (Android/iOS)                   │
│                                                              │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
│  │   UI Layer   │   │  Business    │   │  Data Layer  │    │
│  │   (Widget)   │ → │   Logic      │ → │ (Repository) │    │
│  │   Riverpod   │   │  (Use Cases) │   │              │    │
│  └──────────────┘   └──────────────┘   └──────┬───────┘    │
│                                                 │             │
│                                   ┌─────────────┴─────────┐  │
│                                   │   本地存储             │  │
│                                   │   (Hive + SQLite)     │  │
│                                   │   加密 (SQLCipher)     │  │
│                                   └─────────────┬─────────┘  │
│                                                 │ 同步        │
└─────────────────────────────────────────────────┼────────────┘
                                                  │
                                            HTTPS│
                                                  │
                                       ┌──────────┴──────────┐
                                       │     Supabase        │
                                       │     Backend         │
                                       └──────────┬──────────┘
                                                  │
            ┌─────────────┬────────────────────────┼────────────────┐
            │             │                        │                │
      ┌─────┴─────┐ ┌─────┴─────┐         ┌──────┴─────┐  ┌──────┴──────┐
      │Postgres DB│ │   Auth    │         │  Storage   │  │  Realtime  │
      │  (数据)   │ │  (认证)   │         │  (文件)    │  │  (实时同步) │
      └───────────┘ └───────────┘         └────────────┘  └─────────────┘
```

---

## 二、客户端架构 (Flutter)

### 2.1 分层架构

```
lib/
├── main.dart                     # 入口
├── app.dart                      # 根 Widget
│
├── core/                         # 核心工具
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── extensions/
│
├── data/                         # 数据层
│   ├── models/                   # 数据模型
│   │   ├── trip.dart
│   │   ├── member.dart
│   │   ├── expense.dart
│   │   └── settlement.dart
│   ├── datasources/              # 数据源
│   │   ├── local/                # 本地数据源
│   │   │   ├── hive_datasource.dart
│   │   │   └── sqlite_datasource.dart
│   │   └── remote/               # 远程数据源
│   │       └── supabase_datasource.dart
│   ├── repositories/             # 仓库
│   │   ├── trip_repository.dart
│   │   ├── expense_repository.dart
│   │   └── settlement_repository.dart
│   └── sync/                     # 同步逻辑
│       ├── sync_manager.dart
│       └── conflict_resolver.dart
│
├── domain/                       # 业务逻辑层
│   ├── usecases/
│   │   ├── create_trip.dart
│   │   ├── add_expense.dart
│   │   └── calculate_settlement.dart
│   └── services/
│       ├── settlement_engine.dart
│       └── split_calculator.dart
│
├── presentation/                 # UI 层
│   ├── providers/                # Riverpod providers
│   ├── screens/
│   │   ├── trips/
│   │   ├── expenses/
│   │   ├── settlement/
│   │   └── members/
│   ├── widgets/                  # 通用组件
│   └── theme/                    # 主题
│
└── routes/                       # 路由
    └── app_router.dart
```

### 2.2 状态管理: Riverpod

**为什么选 Riverpod**:
- 类型安全（编译期检查）
- 无 BuildContext 依赖
- 测试友好
- 异步处理强大
- Provider 组合灵活

**Provider 层级**:
```
App Providers
├── AuthProvider (登录状态)
├── DatabaseProvider (数据库初始化)
└── SettingsProvider (用户设置)
    └── Feature Providers
        ├── TripListProvider
        ├── TripDetailProvider
        ├── ExpenseListProvider
        └── SettlementProvider
```

---

## 三、关键流程

### 3.1 记一笔账

```
[用户操作]
  ↓
[UI Widget] 校验输入
  ↓
[Provider] 触发 AddExpenseUseCase
  ↓
[Use Case] 调用 ExpenseRepository
  ↓
[Repository]
  ├─ 1. 写入本地 (Hive + SQLite)
  ├─ 2. 标记 sync_status = pending
  └─ 3. 返回成功
  ↓
[UI 立即更新] 乐观更新
  ↓
[后台] SyncManager
  ├─ 调用 Supabase API
  ├─ 成功 → sync_status = synced
  └─ 失败 → 进入重试队列
```

### 3.2 多端实时同步

```
[用户 A 记一笔账] →
  [Supabase 写入] →
    [触发 Realtime 事件] →
      [用户 B 收到事件] →
        [本地数据更新] →
          [UI 自动刷新]
```

### 3.3 离线场景

```
[离线时记一笔账] →
  [仅写本地] →
  [标记 pending] →
    [网络恢复] →
      [SyncManager 启动] →
        [拉取服务端最新] →
          [合并本地 pending] →
            [批量上传] →
              [标记 synced]
```

### 3.4 冲突解决

**策略**: 客户端时间戳 + 服务端时间戳，新者胜

```
if local.updated_at > remote.updated_at:
    use local
else:
    use remote
```

---

## 四、性能设计

### 4.1 启动优化
- 启动时仅加载必要数据
- 列表用分页加载
- 图片懒加载

### 4.2 渲染优化
- Widget 拆分，避免不必要 rebuild
- const 构造函数
- ListView.builder

### 4.3 网络优化
- 请求合并
- 增量同步
- 缓存策略

---

## 五、安全设计

### 5.1 传输安全
- 强制 HTTPS
- Supabase JWT Token 鉴权

### 5.2 存储安全
- 本地数据库加密 (SQLCipher)
- Key 保存在 Keychain (iOS) / Keystore (Android)
- 不在日志中打印敏感信息

### 5.3 隐私合规
- 符合《个人信息保护法》
- 隐私政策透明
- 用户数据可导出、可删除
- 不收集非必要信息

---

## 六、可扩展性设计

### 6.1 架构扩展点
- Repository 模式：可换数据源（如换 LeanCloud）
- Provider 模式：可加新业务模块
- Plugin 模式：可加新费用类别、新分摊规则

### 6.2 业务扩展点
- 多币种（已在数据模型预留 currency 字段）
- 企业版（数据模型加 org_id 字段）
- AI 智能识别（OCR 引擎插件化）

---

## 七、监控与运维

### 7.1 客户端监控
- Sentry：崩溃、ANR 监控
- Firebase Analytics：用户行为
- 自研埋点：业务关键路径

### 7.2 服务端监控
- Supabase Dashboard：API 调用、数据库性能
- 异常告警：Sentry 邮件/SMS

---

## 八、部署架构

### 8.1 开发环境
```
Trae IDE → 本地 Flutter → Android 模拟器
         → Git push → GitHub
```

### 8.2 生产环境
```
GitHub main branch
    ↓
Codemagic CI
    ↓
自动构建 APK
    ↓
Google Play Console
    ↓
内测/正式发布
```

---

*此文档由 Tech Lead 维护，重大架构变更需走 ADR 流程。*
