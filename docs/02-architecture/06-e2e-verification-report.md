# Supabase 集成端到端验证报告

**日期**：2026-07-04  
**版本**：v1.0  
**关联**：[05-supabase-schema.md](05-supabase-schema.md)

---

## 🎯 验证目标

不需要真实部署 Supabase 项目，验证同步引擎的核心逻辑正确性：
1. 离线优先写入流程
2. 网络失败重试
3. 未登录跳过
4. 未初始化跳过
5. last-write-wins 冲突解决
6. 并发同步防护

## ✅ 测试结果

| # | 测试场景 | 结果 | 验证点 |
|---|---|---|---|
| E2E 1 | 完整同步流程：创建→pending→同步→synced | ✅ Pass | Trip/Member/Expense 上传云端、状态变 synced |
| E2E 2 | 网络失败重试 | ✅ Pass | expense.syncStatus 变 failed |
| E2E 3 | 未登录跳过 | ✅ Pass | result.skipped=true, reason="not signed in" |
| E2E 4 | Supabase 未初始化跳过 | ✅ Pass | 不抛异常,静默跳过 |
| E2E 5 | last-write-wins 冲突解决 | ✅ Pass | 云端新数据覆盖本地旧数据 |
| E2E 6 | 并发同步防护 | ✅ Pass | 第二次调用被 _syncing 锁跳过 |

**总计：6/6 全部通过**

## 📊 测试覆盖

```
sync_engine.dart
├── syncOnce()                  [E2E 1, 2, 3, 4, 5, 6]
│   ├── _pushPending()          [E2E 1]
│   │   ├── _pushTrip()         [E2E 1, 5]
│   │   ├── _pushMember()       [E2E 1]
│   │   ├── _pushGroup()        [covered]
│   │   ├── _pushExpense()      [E2E 1, 2]
│   │   └── _pushTransfer()     [covered]
│   └── _pullChanges()          [E2E 1, 5]
│       └── _mergeTrip()        [E2E 5]
│
└── SyncResult/SyncState        [sync_engine_test.dart]
```

## 🧪 Mock 实现说明

为避免依赖真实 Supabase，编写了 `MockSupabaseService` + `_ProxyClient` + `_ProxyTable` + `_SelectChain`：

- **实现 SupabaseService 接口**：签名匹配
- **`client` 返回 dynamic**：绕过 SupabaseClient 类型限制
- **`_SelectChain` 实现 Future 接口**：让 `await chain` 工作
- **记录所有 upsert 调用**：`upsertedTrips/Members/Groups/Expenses/Transfers`
- **模拟云端已有数据**：`remoteTrips` 列表
- **网络错误模拟**：`simulateNetworkError = true`

## ⚠️ 已知限制

| 限制 | 说明 |
|---|---|
| 只 mock 了 trips 拉取 | 其他表（members/groups/expenses）的拉取逻辑未在 mock 中实现 |
| 不验证 RLS 策略 | RLS 必须在真实 Supabase 项目中测试 |
| 不验证 Realtime 订阅 | 需要真实 WebSocket 连接 |
| 不验证 Storage bucket | 票据上传未测试 |

## 🚀 下一步

1. **用户手动部署**：
   - 创建 Supabase 项目
   - 在 SQL Editor 执行 `00001_initial_schema.sql` + `00002_rls_policies.sql`
   - 复制 URL + anon key

2. **Dart 端配置**：
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```

3. **真实环境验证**（手工）：
   - 注册账号
   - 创建 trip + expense
   - 断网测试：写入本地 → 状态 pending
   - 重连测试：自动同步 → 状态 synced
   - 多端测试：手机 A 创建 → 手机 B 拉取

## 📈 总测试统计

| 文件 | 测试数 |
|---|---|
| test/data/sync_engine_test.dart | 5 |
| test/data/sync_e2e_test.dart | 6 |
| 其他（W1-W4 阶段） | 205 |
| **总计** | **216 个测试全绿** |

---

*生成时间：2026-07-04 01:35*