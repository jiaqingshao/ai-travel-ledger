# 项目评估 Checklist (主清单)

**本表是所有问题的单一真源** —— 任何其他文档(02/03/04/05)都引用本表里的 ID。

**评估轮次**:5 轮
**问题总数**:81(27 严重 + 35 中等 + 16 轻微 + 3 战略待决)
**生成时间**:2026-07-12

---

## 索引

| 严重度 | 数量 | ID 范围 | 跳转 |
|---|---|---|---|
| 🔴 S(严重) | 27 | S-1 ~ S-27 | [查看](#-s-严重-27-条) |
| 🟡 M(中等) | 35 | M-1 ~ M-35 | [查看](#-m-中等-35-条) |
| 🟢 L(轻微) | 16 | L-1 ~ L-16 | [查看](#-l-轻微-16-条) |
| 🔵 N(战略待决) | 3 | N-1 ~ N-3 | [查看](#-n-战略待决-3-条) |

---

## 🔴 S(严重,27 条)

> **修复原则**:发布前必须全修。每条都导致功能坏掉 / 数据丢失 / 隐私泄露。

---

### S-1: `00003_expense_attachments_storage.sql` 引用不存在的 `public.collaborators` 表

| 字段 | 内容 |
|---|---|
| **文件** | `supabase/migrations/00003_expense_attachments_storage.sql` |
| **行** | 65, 76, 91 |
| **严重度** | 🔴 S(部署必失败) |
| **现状** | 第 65/76/91 行 RLS 策略使用 `public.collaborators` 表;但 00001 第 178 行建的是 `public.trip_collaborators` |
| **影响** | 生产部署这条 SQL 直接报"relation 'public.collaborators' does not exist";所有附件上传/删除/查看 RLS 失效 |
| **修复** | 全文 `public.collaborators` → `public.trip_collaborators`(3 处) |
| **验证** | 部署后 `select * from storage.objects where bucket_id='expense-attachments' limit 1` 应有结果;非协作成员应被 RLS 阻挡 |
| **关联** | S-2(同文件触发器错) |

### S-2: `00003` 触发器把 JSON 对象 stringify 进 text[] 字段

| 字段 | 内容 |
|---|---|
| **文件** | `supabase/migrations/00003_expense_attachments_storage.sql` |
| **行** | 113-123(触发器 `sync_expense_attachments`) |
| **严重度** | 🔴 S(数据污染) |
| **现状** | `jsonb_array_elements_text(attachment_metadata->'items')` 把每个 JSON 对象 `[{url, fileName, ...}]` 转成 `[object Object]` 字符串塞进 `expenses.attachments` text[] 字段 |
| **影响** | 所有 expense 的 attachments 字段被垃圾数据污染,前端读取显示怪字符串 |
| **修复** | 改成提取 url 字段:`ARRAY(SELECT (item->>'url') FROM jsonb_array_elements(NEW.attachment_metadata->'items') AS item)` |
| **验证** | `update expenses set attachment_metadata='{"items":[{"url":"https://x.com/a.jpg","fileName":"a","sizeBytes":1,"mimeType":"image/jpeg","uploadedAt":"2026-01-01"}]}'::jsonb where id='x'; select attachments from expenses where id='x';` 应有 `https://x.com/a.jpg` |

### S-3: `litiboy@163.com` 真实邮箱在 3 个 Dart 文件硬编码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/auth_screen.dart` 第 113 行;`lib/presentation/screens/supabase_settings_screen.dart` 第 415 行;`lib/presentation/screens/about_screen.dart` 第 14 行(常量) |
| **严重度** | 🔴 S(隐私泄露) |
| **现状** | 真实邮箱直接写在代码里,任何用户反编译 APK 都能拿到 |
| **影响** | (1)邮箱被机器人爬取 (2)Git 公开后永远可查 (3)收到垃圾邮件 |
| **修复** | 移到运行时设置/隐私政策 URL/企业微信群号;常量 `_authorEmail` 删掉 |
| **验证** | `grep -r 'litiboy' lib/` 应 0 命中 |
| **关联** | S-4(Supabase URL 硬编码) |

### S-4: 真实 Supabase project URL `zvqnawllsdmisntkxdwp` 硬编码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/supabase_settings_screen.dart` 第 190 行(`_pasteExample()`) |
| **严重度** | 🔴 S(服务入口泄露) |
| **现状** | 真实 project ID 写死在 paste example 里 |
| **影响** | Git 公开后攻击者知道你的 Supabase 实例入口,扫 anon key 撞 storage / 公开表 |
| **修复** | `_pasteExample()` 改为 `https://YOUR-PROJECT.supabase.co`,或者改成读环境变量 / 用占位 |
| **验证** | `grep -r 'zvqnawllsdmisntkxdwp' lib/` 应 0 命中 |
| **关联** | S-3 |

### S-5: `syncEngineProvider.startAutoSync()` 全工程 0 处调用 —— 同步引擎是死代码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 43-47 行(定义);`lib/main.dart`(无调用);`lib/presentation/providers/sync_providers.dart` 第 11-14 行(provider 存在但没人 watch) |
| **严重度** | 🔴 S(承诺功能完全未运行) |
| **现状** | `grep -rn "startAutoSync" lib/` 全工程只 1 处(定义),无任何调用方 |
| **影响** | (1)即使有 Supabase 配置,数据**永远不会自动同步** (2)`expense.syncStatus = synced` 写死,UI 显示"已同步"但实际**根本没传** (3)新用户看到 30s 自动同步的描述,实际啥都没动 |
| **修复** | `main.dart` `runApp` 之前加 `final engine = ref.read(syncEngineProvider); engine.startAutoSync();` |
| **验证** | 跑应用,新建一个 trip,看 HiveBox.watch() 是否触发云端 insert;断网重连后,看 syncStatus 是否从 pending 变 synced |
| **关联** | S-6(默认 synced)、S-8(local-user)、M-18(失败的 pull) |

### S-6: `ExpenseRepository.create()` 默认 `syncStatus: SyncStatus.synced`

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` 第 186 行 |
| **严重度** | 🔴 S(同步 UX 谎言) |
| **现状** | 新建 expense 时直接写 `syncStatus: SyncStatus.synced`,**不是** `pending` |
| **影响** | 即使 S-5 修复后,sync engine 不知道哪些 expense **还没**传过(因为都标 synced) |
| **修复** | 第 186 行改为 `syncStatus: SyncStatus.pending,` |
| **修复后** | sync engine 看到 pending 才推云端;成功后改 synced(已有逻辑) |
| **关联** | S-5 |

### S-7: `_SettlementView` 第 476 行 `members.first.tripId` 在空成员列表会崩

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/settlement_screen.dart` 第 476 行 |
| **严重度** | 🔴 S(白屏崩溃,ISSUE-020 复发) |
| **现状** | `tripId: members.first.tripId` 没有 `if (members.isNotEmpty)` 守卫 |
| **影响** | 一个新 trip 创建后,只有 0 成员时进结算页 → `members.first` 抛 StateError → 白屏 |
| **修复** | 改为 `tripId: members.isNotEmpty ? members.first.tripId : widget.tripId` |
| **验证** | 新建空 trip(0 成员),进结算页不崩;新建 1 成员 trip 不崩 |
| **关联** | M-1(同款 bug 在 group_settlement_screen) |

### S-8: `kCurrentUserId = 'local-user'` 写死 + sync 用 Supabase user UUID

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/trip_provider.dart` 第 17 行(常量);`lib/data/sync/sync_engine.dart` 第 130 行(用 Supabase user id) |
| **严重度** | 🔴 S(数据归属错乱) |
| **现状** | 本地 `Trip.createdBy` 永远是 `'local-user'`;sync 到云端用 `auth.currentUser.id`(接 Supabase 后) |
| **影响** | 接 Supabase Auth 后,所有老 trip 在云端会"由当前登录用户创建"(因为是 upsert by id,本地 push 覆盖归属);多人共享 trip 时归属全乱 |
| **修复** | `kCurrentUserId` 改为 `String? get kCurrentUserId => SupabaseService.instance.isSignedIn ? SupabaseService.instance.currentUserId : null;`;TripRepository.create 接 nullable,本地模式时 fallback 到 `kLocalUserId` |
| **验证** | 登录前/后创建 trip,云端 trip.created_by 是当前 user uuid;登出后创建 trip 仍然在本地 |
| **关联** | S-5(同步没启) |

### S-9: `main.dart` 完全没启动 sync engine

| 字段 | 内容 |
|---|---|
| **文件** | `lib/main.dart` 第 80-98 行(`runApp` 之前) |
| **严重度** | 🔴 S(同步死代码) |
| **现状** | `runApp` 之前没调 `startAutoSync()` |
| **修复** | 在 `runApp` 之前加 `final engine = SyncEngine(boxes: boxes); engine.startAutoSync();`(或注入 syncEngineProvider 后调) |
| **关联** | S-5 |

### S-10: `AuthNotifier._init()` 的 `authStateChanges.listen()` StreamSubscription 永远不取消

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/sync_providers.dart` 第 56-68 行 |
| **严重度** | 🔴 S(内存泄漏 + 异常) |
| **现状** | 构造函数里调 `_init()`,`_init()` 里 `SupabaseService.instance.authStateChanges.listen((authState) { state = AuthState(...); })`,**subscription 没保存,StateNotifier dispose 时也不取消** |
| **影响** | (1)Riverpod dispose 后 stream 还在 listen,每次 auth 变化都调已 dispose notifier 的 setState → 异常/崩溃 (2)内存泄漏,App 生命周期内积累 listener |
| **修复** | 字段加 `StreamSubscription? _authSub`;`initState` 同步,在 `dispose` 加 `@override void dispose() { _authSub?.cancel(); super.dispose(); }` |
| **验证** | 反复登录/登出 10 次,看 logcat 是否有 "setState() called after dispose()" 异常 |
| **关联** | S-9(sync engine 启动时也会触发) |

### S-11: `expense_create_screen.dart` 第 86-87 行 build 里 mutate state(没 setState)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` 第 86-87 行(`_initDefaultPayer(members)`) |
| **严重度** | 🔴 S(隐性 UX bug) |
| **现状** | `if (_payer == null) { _initDefaultPayer(members); }` 在 build 的 `data` 分支,改 `_payer` 但**没** `setState` |
| **影响** | 首次进入,选中的 payer **要到下一次 build 才显示**;快速点击 payer 卡 200ms 内 UI 不响应;hot reload 后会闪 |
| **修复** | 改用 `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && _payer == null) setState(() => _initDefaultPayer(members)); })` |
| **验证** | 清数据,开 app,点 "记一笔" → 第一次 build 立即显示默认 payer |
| **关联** | S-12(同款问题在 expense_detail) |

### S-12: `expense_detail_screen.dart` 第 84-85 行 build 里 mutate state(没 setState)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 第 83-85 行 |
| **严重度** | 🔴 S(隐性 UX bug) |
| **现状** | `if (!_editing) { _initFromExpense(expense); }` 在 build 里 mutate 4 个 TextEditingController + 4 个 state |
| **影响** | 跟 S-11 同,但详情页更严重(改了 amount / desc 后再 build 会"恢复"原值) |
| **修复** | 同 S-11,用 `addPostFrameCallback` 包起来 |
| **验证** | 详情页改金额 → 退出 → 重进 → 显示新值(不是上一次 build 的旧值) |
| **关联** | S-11 |

### S-13: `_addAttachment` URL 不校验,允许任意字符串

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 第 414-444 行 |
| **严重度** | 🔴 S(安全 + 数量校验) |
| **现状** | 只检查 `url != null && url.isNotEmpty`,不校验 `https://` 开头、不校验 `Uri.tryParse`、不校验 ≤3 个附件(PRD AC-13 写的) |
| **影响** | (1)可输入 `javascript:alert(1)`,未来加 WebView 就 XSS (2)超过 3 个附件不报错(PRD 明确限制) |
| **修复** | `final uri = Uri.tryParse(url); if (uri == null \|\| !uri.isAbsolute \|\| (uri.scheme != 'http' && uri.scheme != 'https'))` 校验;`_editingAttachments.length >= 3` 拒绝新加 |
| **验证** | 输入 `xxx` 应被拒;输入 `https://valid.com/a.jpg` 应通过;4 次添加后第 4 个应被拒 |
| **关联** | M-10 |

### S-14: 重新生成 release keystore 后旧 APK 无法升级

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/07-release-build-guide.md` + daily-report/2026-07-10.md |
| **严重度** | 🔴 S(已发布则致命,未发布则警告) |
| **现状** | daily-report 第 57 行 "**重新生成 keystore**",但 7-4 release-build-guide.md 警告 "丢了 = APP 永远无法更新" |
| **影响** | (1)用户在用旧版,新版要"先卸载"才能装(数据清空) (2)如果旧 APK 已上架 Google Play,会**所有用户无法升级** |
| **修复** | (1)确认 0.1.0 APK 没真上架(只是本地/微信)→ 继续; (2)后续:**keystore 备份到 2+ 位置**(云端 + 物理 U 盘),密码用强密码而非 `aitravel2026` |
| **验证** | 卸载 0.1.0 → 装 0.2.0 是否提示"签名冲突" |
| **关联** | daily-report 7-10 已发出警告 |

### S-15: PRD v0.3 三大 P0 功能(语音/重复/统计)**承诺但完全没实现**

| 字段 | 内容 |
|---|---|
| **文件** | `docs/01-requirements/02-prd.md` 第 103-145 行 |
| **严重度** | 🔴 S(产品诚信 + 履约) |
| **现状** | PRD v0.3 把 E-008 语音记账 / E-009 重复费用 / E-010 旅程统计图表 升级到 P0 MVP。**代码里 0 实现**:无 STT、无 recurring_expenses 表、无 statistics_screen(fl_chart 在 pubspec 但没人 import) |
| **影响** | (1)给投资/上架看 PRD 会暴露虚假宣传 (2)roadmap 自己说"未开始" + PRD 说 P0,**文档自相矛盾** (3)用户故事 16/017 吹的功能不存在 |
| **修复** | **必须在修代码前决策**(`04-strategic-decisions.md` N-1):(1) 砍掉 E-008/009/010,降级 V1.1 (2) 加快实现 (3) 改 PRD/roadmap 让承诺和实现匹配 |
| **关联** | N-1,M-30,P0 #7 战略问题 |

### S-16: 项目文件目录结构一览表严重失修

| 字段 | 内容 |
|---|---|
| **文件** | `docs/03-management/项目文件目录结构一览表.md` |
| **严重度** | 🔴 S(文档入口失真) |
| **现状** | 一览表写"60 个 markdown",实际搜到 50 个;写了"5 个 model / 5 个 repo",实际多了 attachment / app_settings / split_rule_edit_page;supabase 列 2 个 migration 实际 3 个;verification/、troubleshooting/、99-archive/test-misc/ 一览表里没列 |
| **影响** | (1)新成员按一览表找不到附件 / app_settings / split_rule_edit_page (2)风险登记册 / 系统设计文档被列但不存在 (3)文档失修反映项目治理失控 |
| **修复** | 跑 `find . -name "*.md" \| wc -l` + `find . -name "*.dart"` 重写一览表;添加已存在的 `attachment_*`、`app_settings_*`、`split_rule_edit_page*`、`00003` migration、`verification/`、`troubleshooting/` 章节;删除不存在的 `risk-register.md` / `02-system-design.md` / `01-brainstorm.md` |
| **验证** | 一览表 vs `ls` 输出,误差 = 0 |
| **关联** | M-22 |

### S-17: `data-model.md` 描述的表结构跟真实 Supabase 不一致

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/03-data-model.md` |
| **严重度** | 🔴 S(数据模型文档失真) |
| **现状** | 文档说 `expense_splits` 表独立存分摊明细,实际 Supabase 用 `expenses.split_rule_json` JSONB 字段;`settlements` 表文档说存在,实际 Supabase 没建;用 `DECIMAL(12,2)`,实际 `BIGINT amount_cents` |
| **影响** | 新成员按 data-model.md 写代码会写错表 / 写错类型;客户端 JSON 解析后用 `double`,服务端 `int cents`,产生精度漂移 |
| **修复** | 用 00001 SQL 重写 data-model.md;**用真 schema 反推文档**(不要反着来) |
| **关联** | S-16(同一类失修) |

### S-18: `tech-stack.md` 写 `app_links 6.4.1 与 Flutter 3.x 不兼容` 但 pubspec 用 `dependency_overrides: 6.3.1` —— 没文档化

| 字段 | 内容 |
|---|---|
| **文件** | `pubspec.yaml` 第 82-87 行 |
| **严重度** | 🔴 S(隐式 bug) |
| **现状** | `dependency_overrides.app_links: 6.3.1` 是为了绕过 app_links 6.4.1 的不兼容,但 tech-stack.md / ADR 都没提这个 override 的原因 |
| **影响** | 下次升级 Flutter 到 3.27+ 时,这个 override 可能不再需要(也可能造成新冲突),没人知道为什么 6.3.1 |
| **修复** | tech-stack.md 加 "Known issue: app_links 6.4.1 vs Flutter 3.x → use 6.3.1, see ISSUE-2026-07-09-01" |
| **验证** | 文档里有明确的 override 原因 |

### S-19: `push_expenses` 把 expense 整个 push(包括 syncStatus、deletedAt)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 175-199 行(`_pushExpense`) |
| **严重度** | 🔴 S(数据一致) |
| **现状** | `client.from('expenses').upsert({...all fields including syncStatus, deletedAt...})` |
| **影响** | 把"本地临时状态"也 push 到云端,云端会看到 `sync_status = 'synced'` 等本地枚举字符串,**和 schema enum 对不上**;`deleted_at` 是本地软删除标记,不应该同步 |
| **修复** | 把 `syncStatus`、`deletedAt` 从 upsert 字段移除;用 SQL 视图或客户端过滤 |
| **验证** | 云端 expenses 表不应有 sync_status 字段值 |

### S-20: `lib/core/ai_config.dart` 把 M3 API key 占位 + baseUrl 硬编码(包含 Qwen3.6 局域网 IP)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/core/ai_config.dart` 第 45-46 行(M3 baseUrl + REPLA...EY placeholder);第 60 行(`qwen3.6-35b-a3b-apex-balanced` modelName);多处 |
| **严重度** | 🔴 S(隐私 + 维护) |
| **现状** | `cloudM3` / `cloudDeepSeek` / `cloudGlm4` / `cloudQianwen` 都有 `'REPLA...EY'` 占位,本地 `localQwen36` 写死 `http://192.168.1.60:8033/v1` |
| **影响** | (1)即使在 AI 配置页改了 key,`updateApiKey` 只改 state,但 `_post()` 用的是 `_config.apiKey` ← state 的;这是 OK 的 (2)但 `localQwen36.baseUrl` 硬编码 `192.168.1.60`,换网络就废;**没有 fallback 到动态 IP** (3) `qwen3.6-35b-a3b-apex-balanced` model name **跟实际端点返回的 model id 不匹配**(真名是 `Qwen3.6-35B-A3B-APEX-MTP-Balanced.gguf` 带 -MTP) |
| **修复** | (1) `localQwen36.baseUrl` 从设置读 (2) `modelName` 在设置页让用户填,或拉 `/v1/models` 自动取 |
| **验证** | 网络换到 .90 段后,本地 Qwen 仍能连 |

### S-21: `expense_create_screen.dart` `_submitAndContinue` 失败不弹 Snackbar

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` 第 207-226 行 |
| **严重度** | 🔴 S(UX) |
| **现状** | `if (!ok || !mounted) return;` 失败时静默退出 |
| **影响** | 用户以为按了保存,实际失败,无任何提示 |
| **修复** | `if (!ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败,请重试'))); return; }` |
| **验证** | 模拟网络断开 → 失败 → 应看到 Snackbar |

### S-22: `expense_create_screen.dart` 自定义数字键盘限 2 位小数后,**UI 不告诉用户已锁**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` 第 180-189 行 |
| **严重度** | 🟡 M(实为 S 级,UX) |
| **现状** | `if (_amountInput.length - dotIdx > 2) return;` 用户输 `1.55` 后继续按 `6` 不会进,无任何反馈 |
| **影响** | 用户以为键盘坏了 |
| **修复** | 拒绝时震动或 Snackbar:"已到 2 位小数" |
| **关联** | S-21(失败反馈缺失同类) |

### S-23: `expense_detail_screen.dart` 用系统键盘 + 不限小数位

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 第 230-238 行 |
| **严重度** | 🔴 S(数据精度) |
| **现状** | `TextField keyboardType: TextInputType.numberWithOptions(decimal: true)`,没限制小数位,后端 schema `BIGINT amount_cents` |
| **影响** | 用户输 `1.999999`,`round() = 200` 入 200 cents 但显示仍是 1.999999,后续累加会漂移 |
| **修复** | (1)用 `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))]` 限 2 位 (2)前端 parse 用 `num.parse` 不用 `double.tryParse`(精度警告) |
| **关联** | S-15 关联精度问题 |

### S-24: 4 层 `AsyncValue.when` 嵌套,任一 loading 整页转圈

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/settlement_screen.dart` 第 43-66 行;`lib/presentation/screens/group_settlement_screen.dart` 第 32-50 行;`lib/presentation/providers/settlement_provider.dart` 第 65-129 行 |
| **严重度** | 🔴 S(UX + 可维护性) |
| **现状** | expenses → members → groups → records 4 层 `when`,任一 loading,UI 一直转圈不显示部分数据 |
| **影响** | (1)网络抖动时整页转圈(其实可以展示旧数据) (2)4 层嵌套读起来累,改一个 if 容易漏 (3)ISSUE-020 早期就是这里崩的 |
| **修复** | 用 `riverpod`'s `AsyncValue.guard` + `combine` pattern;或者 `expensesAsync.maybeWhen` 默认展示缓存 |
| **关联** | ISSUE-020 复发点 |

### S-25: 重新生成 release keystore 但密码仍是 `aitravel2026`(占位)

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/07-release-build-guide.md` 第 41-42 行 |
| **严重度** | 🔴 S(如果上架) |
| **现状** | daily-report 7-10 提到重新生成 keystore,密码还是 `aitravel2026` |
| **影响** | 如果上架,任何攻击者拿到 keystore + 知道弱密码,可以签恶意 APK 伪装你的 app |
| **修复** | 重新生成 + 强密码(20+ 字符,大小写+数字+符号);keystore 文件存密码管理器 |
| **验证** | 密码长度 ≥ 20,无字典词 |
| **关联** | S-14 |

### S-26: `_cloudVersion` 注释里写存在但代码里不存在

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 20-21 行(注释) |
| **严重度** | 🔴 S(死代码 + 误导) |
| **现状** | 注释: "Trip/Member/Group 当前没这个字段,所以用 `_cloudVersion` map 单独追踪",但代码里**没这个 map** |
| **影响** | Trip/Member/Group/Transfer 4 个实体的 sync 状态**完全没追踪**;新建 trip 后 sync 失败,UI 不知道;重启 app,sync engine 不知道哪些没推过 |
| **修复** | (1) 删注释 (2) 给这 4 个实体加 `cloudVersion: int` 字段(用 `build_value` 或手写) (3) sync 时比较 local vs cloud,只推 local > cloud |
| **关联** | S-5, S-6 |

### S-27: `expense_repository.dart` `update()` 改 amount 不校验已结清的 transferRecord 是否受影响

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` 第 195-229 行 |
| **严重度** | 🔴 S(数据一致性) |
| **现状** | 改 expense 字段后 settlement provider 自动重算,但所有"已结清"的 transfer 金额**不会撤销** |
| **影响** | 用户改一笔 expense ¥100→¥200,旧 transfer 标"已结清"(¥30),但新结算应该 ¥60,**数据永久错位** |
| **修复** | 在 `update()` 检测 amount/currency 变化,如果有任何该 expense 关联的 settled transfer 记录,弹"修改会撤销已结清记录"确认;或者强制 unmark |
| **验证** | 制造一个 expense + transferRecord,改 expense amount,看 transferRecord 是否被警告 |

---

## 🟡 M(中等,35 条)

> **修复原则**:1-2 周内修,影响 UX / 数据漂移 / 文档准确性,不影响主流程。

---

### M-1: `group_settlement_screen.dart` 第 36-49 行同款 3 层 when 嵌套

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/group_settlement_screen.dart` 第 32-50 行 |
| **严重度** | 🟡 M |
| **问题** | settlement → members → groups 3 层 when,任一 loading 整页转圈 |
| **修复** | 同 S-24,改用 `combine` pattern |
| **关联** | S-24 |

### M-2: `_parseColor` 在 4 个文件重复实现

| 字段 | 内容 |
|---|---|
| **文件** | `trip_detail_screen.dart:222-227`、`group_manage_screen.dart:185-190`、`group_settlement_screen.dart:320-324`、`member_manage_screen.dart:223-228` |
| **严重度** | 🟡 M |
| **问题** | 4 份完全一样的 `Color? _parseColor(String? hex)` 函数,只接受 6 位 hex |
| **修复** | 提到 `core/utils/color_utils.dart`;同时支持 3 位简写 `#FFF` 和 8 位带 alpha `#FFFFFFFF` |
| **关联** | M-3 |

### M-3: `_parseColor` 不支持 3 位 hex 简写 / 8 位 alpha

| 字段 | 内容 |
|---|---|
| **文件** | 同 M-2 |
| **严重度** | 🟡 M |
| **问题** | `if (v.length != 6) return null;` 直接拒 `#FFF` 和 `#FFFFFFAA` |
| **修复** | `final v = hex.replaceFirst('#', ''); if (v.length == 3) { v = v.split('').map((c) => '$c$c').join(); } else if (v.length == 8) { v = v.substring(0, 6); }` |
| **关联** | M-2 |

### M-4: `tripByIdProvider` / `expenseByIdProvider` 重复 watch + 实际不响应 box 变化

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/trip_provider.dart` 第 40-45 行;`lib/presentation/providers/expense_provider.dart` 第 24-29 行 |
| **严重度** | 🟡 M |
| **问题** | `ref.watch(tripRepositoryProvider); ref.watch(tripRepositoryProvider);` watch 两次(第二次注释说"为了订阅 box 变更",但 Riverpod 多次 watch 同一 provider 不会重新触发);`Provider.family` 一次性取值,box 改了不重算 |
| **影响** | 详情页编辑 trip 后,**老数据还显示**直到用户退出重进 |
| **修复** | 改成 `StreamProvider.family` 或 `StreamProvider.autoDispose.family` |
| **验证** | trip_detail_screen 编辑 trip name → 列表显示新名字 |

### M-5: `auth_screen.dart` `email not confirmed` 字符串匹配

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/auth_screen.dart` 第 76 行 |
| **严重度** | 🟡 M |
| **问题** | `if (!_isLogin && err.toLowerCase().contains('email not confirmed'))` 依赖英文错误字符串 |
| **影响** | Supabase 改 i18n 提示后,这判断静默失效 |
| **修复** | `if (e is AuthException && e.code == 'email_not_confirmed')` |
| **关联** | M-6 |

### M-6: `AuthNotifier.signIn` / `signUp` 把内部异常 message 直接返回给 UI

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/sync_providers.dart` 第 81-83 行、第 100-103 行 |
| **严重度** | 🟡 M |
| **问题** | `} catch (e) { return e.toString(); }` |
| **影响** | 内部英文异常(可能是 stack trace 片段)直接显示给中国用户 |
| **修复** | catch 里 `if (e is AuthException) return _mapAuthError(e); else return '登录失败,请稍后重试';` 加一张 i18n 映射表 |
| **关联** | M-5 |

### M-7: `sync_engine._pullChanges` 只 pull trips,缺 member/group/expense/transfer

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 232-249 行 |
| **严重度** | 🟡 M |
| **问题** | `final tripsResponse = await client.from('trips').select(...).or('created_by.eq.$userId');` 只查自己创建的 trip,漏掉被分享的 |
| **影响** | B 加入 A 分享的 trip → B sync 时**拉不到这条 trip**(即使 RLS 允许) |
| **修复** | 改成 `client.from('trips').select(...)` 不带 `or`,靠 RLS 过滤;然后为每个 trip 拉 member / group / expense / transfer |
| **验证** | 登录 B,被 A 分享的 trip 应在列表里 |
| **关联** | S-5, S-8 |

### M-8: `_pushExpense` 失败 catch 里改 `expense.syncStatus = failed`,但 `expense.save()` 失败时**状态丢失**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 195-198 行 |
| **严重度** | 🟡 M |
| **问题** | `expense.syncStatus = SyncStatus.failed; await expense.save();` 第二次 save 也可能失败(Hive box 关闭/冲突),此时状态彻底丢失 |
| **影响** | 偶尔 sync 失败后,expense 永远卡在 synced 状态(没真的传) |
| **修复** | 把 save 包在 try 里,失败 log + 静默;下一个 sync cycle 重新尝试 |
| **关联** | S-6, S-5 |

### M-9: `Trip.baseCurrency` 改了之后,所有旧 expense.currency 不联动

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/trip_repository.dart` 第 95-120 行;`lib/presentation/screens/trip_edit_screen.dart` |
| **严重度** | 🟡 M |
| **问题** | 改 trip.baseCurrency 后,老 expense 的 currency 字段不动,导致 trip 改了 ¥ → €,expense 还是 ¥,结算时币种不一致 |
| **影响** | 已结清的 trip 改币种 → 数据永久错位 |
| **修复** | (1)改 baseCurrency 时弹"需要同步改所有 expense 吗"确认 (2)或者只允许新 expense 改币种,老的固定 |
| **关联** | S-27(同类的数据一致问题) |

### M-10: PRD 明确说"附件最多 3 个",代码没强制

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 第 358-412 行 |
| **严重度** | 🟡 M |
| **问题** | `_buildAttachmentsSection` 添加按钮永远可点 |
| **影响** | 跟 S-13 一样,可无限加附件 |
| **修复** | 已在 S-13 修了 `>=3` 校验 |

### M-11: 4 个 `_addMemberSheet` / `_GroupEditorSheet` / 等 sheets 有 8 个固定颜色,不让用户自定义

| 字段 | 内容 |
|---|---|
| **文件** | `member_manage_screen.dart:279-288`、`group_manage_screen.dart:243-252` |
| **严重度** | 🟡 M |
| **问题** | 8 色硬编码 |
| **影响** | 用户要"稻穗金"色没法 |
| **修复** | 改成"8 预设 + 自定义拾色器"(用 `flutter_colorpicker` 包) |
| **优先级** | P2 |

### M-12: `expense_create_screen.dart` 默认货币 `CNY` 不可改

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart`(整个文件) |
| **严重度** | 🟡 M |
| **问题** | FSD 1.2.1 写 `baseCurrency string(3)` 用户可选,但 expense 创建页**根本没让用户选 currency 字段** |
| **影响** | trip 选了 EUR,expense 默认还是 CNY,币种不一致 |
| **修复** | 加 currency 下拉,默认 inherit from trip |
| **关联** | M-9 |

### M-13: `expense_create_screen.dart` 自定义数字键盘 0 开头允许输入 0.0x

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` 第 184-189 行 |
| **严重度** | 🟡 M |
| **问题** | `if (_amountInput == '0') { _amountInput = k; }` 但输入 `0.0` 后再输 5 不会变 `5`,还是 `0.05`?实际行为:`_amountInput.contains('.')` → 检查 2 位小数 → `'0.05'` 长度 4,小数点后 2 位 → 通过;但 `'0.0' + '5' = '0.05'` 实际是这样吗?逻辑混乱 |
| **修复** | 写明测试用例,重写更直观的逻辑 |

### M-14: `split_calculator_test.dart` 期望值用精确 double 比较

| 字段 | 内容 |
|---|---|
| **文件** | `test/domain/split_calculator_test.dart` 第 187-196 行 |
| **严重度** | 🟡 M |
| **问题** | `expect(r.firstWhere(...).amount, 33.33);` 用 `==` 比较浮点 |
| **修复** | 改为 `closeTo(33.33, 0.005)`(其他行已经用了 closeTo) |

### M-15: `Attachment` 模型注册了 Adapter 但**整个附件功能未实现**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/main.dart:45`、`lib/data/models/attachment.dart:19-20`(typeId 15) |
| **严重度** | 🟡 M |
| **问题** | `AttachmentAdapter` 已注册、Hive box `attachments` 已开,但 `attachment_repository.dart` 几乎没人调用 |
| **影响** | 现在没崩是因为 `Attachment` box 始终空;一旦实现附件上传并写 box,会触发一堆未测路径 |
| **修复** | 要么删附件相关代码,要么实现 PRD E-005 图片压缩(AC-32~36) |
| **关联** | S-15(三大 P0) |

### M-16: `ExpenseRepository._fireRemote` 用 `catchError((_) {})` 静默吞错

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` 第 329-334 行(以及同款在 trip/member/group/transfer 5 个 repo) |
| **严重度** | 🟡 M |
| **问题** | `sync(expense, op).catchError((_) {});` 失败完全无感,没 log 没上报 |
| **影响** | 网络挂了,sync 失败 100 次用户都不知道 |
| **修复** | `catchError((e, st) { debugPrint('sync failed for ${expense.id}: $e'); })` |

### M-17: `GroupSettlement.transfers` 永远为空数组(命名 misleading)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/domain/services/settlement_engine.dart` 第 376, 393 行 |
| **严重度** | 🟡 M |
| **问题** | `byGroup()` 返回的 `GroupSettlement.transfers` 永远是 `const []`,但字段名暗示它装组内互转 |
| **影响** | 开发者看了代码以为这里有数据,实际要看 `transfersBetweenGroups()` |
| **修复** | 字段名改为 `externalTransfers`,或加 `// 永远空,看 settlement.transfers` 注释 |
| **关联** | PRD AC-29 "组内展开可见个人明细" 的实现依赖 settlement.transfers,容易踩 |

### M-18: `expense_repository.dart` `_pushExpense` 没单独 try/catch

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart` 第 119-136 行(`_pushTrip` 同款) |
| **严重度** | 🟡 M |
| **问题** | push 方法 `return false` 在 catch 里,但**不更新本地 syncStatus**(只有 expense 有这字段) |
| **影响** | Trip 同步失败没标记,重启 app 后再 sync,不知道推没推过 |
| **修复** | 见 S-26 |

### M-19: `app_settings_screen.dart` 错误信息硬编码中文,失败 debug 信息泄漏

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/supabase_settings_screen.dart` 第 107-108 行 |
| **严重度** | 🟡 M |
| **问题** | 失败时 `_error = '❌ 连接失败, 已回退本地模式\n\n\${result.error ?? "未知错误"}\n\n请检查:\n• URL 是否正确\n• anon key 是否完整\n• 网络是否可达';` |
| **影响** | `result.error` 可能包含 stack trace 片段(因为 `_init` 把 catch 转 string) |
| **修复** | 只显示友好提示,详细 error 写到 debug log |

### M-20: `archive` 按钮没二次校验

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/trip_detail_screen.dart` 第 201-220 行(`_confirmDelete`);同款 `_confirmArchive` 是普通弹窗 |
| **严重度** | 🟡 M |
| **问题** | 删除旅程弹窗只是"取消/删除",**没要求输名字确认**;误点直接删全部 member + expense |
| **修复** | Material 3 高危操作建议:必须输 trip 名字才能按"删除" |

### M-21: `pubspec.yaml` 缺 lint 自定义

| 字段 | 内容 |
|---|---|
| **文件** | `analysis_options.yaml` 整个文件 |
| **严重度** | 🟡 M |
| **问题** | 只用 `flutter_lints` 默认,没启用 `unawaited_futures` / `always_declare_return_types` / `prefer_const_constructors` 等便宜规则 |
| **影响** | `sync_engine.dart:46` 就有 `unawaited(syncOnce())` 应该是 warning 而不是 silently 通过 |
| **修复** | 在 `analyzer.rules` 下加 `unawaited_futures: true; always_declare_return_types: true; prefer_const_constructors: true; avoid_print: false;` 等 |

### M-22: `roadmap.md` Epic 状态全部"未开始" 但 E-001/002/003/004 实际已完成

| 字段 | 内容 |
|---|---|
| **文件** | `roadmap/roadmap.md` 第 18-23 行 + `roadmap/epic-001/002/003/004/epic.md` |
| **严重度** | 🟡 M |
| **问题** | roadmap 表标"未开始",但 epic-001/002/003/004 已全实现(225 测试通过);roadmap 失去意义 |
| **修复** | 把这 4 个标"已完成",E-005/006/007 标"V1.1 Backlog" |
| **关联** | S-15 |

### M-23: `roadmap.md` 把"原 E-008/009/010"编号搞反

| 字段 | 内容 |
|---|---|
| **文件** | `roadmap/roadmap.md` 第 27-29 行 |
| **严重度** | 🟡 M |
| **问题** | "E-011=文件导入(原 E-008)" 但 E-008=语音记账,不是文件导入 |
| **修复** | 删掉"原 E-XXX"那段重写 |

### M-24: `daily-reports/` 和 `meeting-notes/daily-*.md` 职责不清

| 字段 | 内容 |
|---|---|
| **文件** | `docs/03-management/daily-reports/` + `docs/03-management/meeting-notes/daily-*.md` |
| **严重度** | 🟡 M |
| **问题** | 两套并行:日报(10 天 daily-reports/2026-06-29.md 之类)+ 工作日志(meeting-notes/daily-2026-06-20.md 之类) |
| **修复** | 合并成 `daily-logs/`,统一格式 |

### M-25: 5 个 `repository` 都有 `deleteAllByTrip` 但没人调

| 字段 | 内容 |
|---|---|
| **文件** | `trip_repository.dart:130`、`member_repository.dart:130`、`group_repository.dart:91`、`expense_repository.dart:291`、`transfer_record_repository.dart:108` |
| **严重度** | 🟡 M |
| **问题** | 5 个 repo 都有 `deleteAllByTrip(tripId)`,但 `TripRepository.delete()` 没级联调这些 |
| **影响** | `TripRepository.delete(id)` 只删 trip 本体,**member / group / expense / transfer 全部孤儿**残留 Hive |
| **修复** | TripRepository.delete 内调其他 4 个 repo 的 deleteAllByTrip;或 Hive 配 cascade |

### M-26: `expense_detail_screen.dart` 第 188-200 行 `已删除(YYYY-MM-DD HH:mm)` 显示不显示是谁删的

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 第 182-196 行 |
| **严重度** | 🟡 M |
| **问题** | 只显示时间,不显示删除者(成员 ID) |
| **修复** | schema 加 `deleted_by` 字段;UI 显示 "小明 删除于..." |

### M-27: `expense.amount` 字段全部 `double` 而 schema 用 `BIGINT amount_cents`

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/models/expense.dart:175`;`lib/data/sync/sync_engine.dart:182` |
| **严重度** | 🟡 M |
| **问题** | Dart 端用 double,服务端用 int cents;`amount * 100` round 后丢精度 |
| **修复** | Expense.amount 改为 `int amountCents`,UI 用 `int/100` 渲染 |

### M-28: `SettlementEngine.compute` 总金额用 `expenses.fold<double>` 累加 double

| 字段 | 内容 |
|---|---|
| **文件** | `lib/domain/services/settlement_engine.dart` 第 457-460 行 |
| **严重度** | 🟡 M |
| **问题** | `expenses.fold<double>(0, (a, e) => a + e.amount)` 累加 50 笔 double 会有尾差 |
| **修复** | 在 `expense.amount` 改 int 后,这里用 int 加,UI 再除 100 |

### M-29: `Trip.fromDb` 'active' 分支对 endDate==null 边界没测试

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/models/trip.dart:139-150` |
| **严重度** | 🟡 M |
| **问题** | active 兼容分支有 3 种 case 但测试没覆盖,迁移数据时推断逻辑可能错 |
| **修复** | 加 3 个单元测试:endDate null + startDate 过去 / endDate null + startDate 未来 / endDate != null + 过去 |
| **关联** | M-22 |

### M-30: PRD v0.3 三个 P0 功能(语音/重复/统计) **`lib/` 中 0 个相关文件**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/` 全目录 |
| **严重度** | 🟡 M(技术) + S-15(战略) |
| **问题** | 无 `voice_recording.dart` / 无 `recurring_expense.dart` / 无 `statistics_screen.dart` |
| **修复** | 见 S-15,N-1 决策 |
| **关联** | S-15 |

### M-31: `split_calculator.dart` `equalAll` + `equalSelected` 是**完全相同的实现**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/domain/services/split_calculator.dart` 第 148-167 行 |
| **严重度** | 🟡 M |
| **问题** | `equalSelected` 调 `_equalCore(... remainderReceiverIndex: 0)`,跟 `equalAll` 一样,只是名字不同 |
| **影响** | 维护成本,新人困惑 |
| **修复** | 删除 `equalSelected`,把 `SplitType.equalSelected` 合并到 `equal` |

### M-32: `Trip.baseCurrency` 字段长度 3 写死 string(3),但 UI 7 个币种选项都不校验长度

| 字段 | 内容 |
|---|---|
| **文件** | `trip_create_screen.dart:24`、`trip_edit_screen.dart:27` |
| **严重度** | 🟡 M |
| **问题** | `static const _currencies = ['CNY', 'USD', 'EUR', 'JPY', 'HKD', 'GBP', 'THB'];` 都是 3 字符 ISO 4217 |
| **修复** | OK, 但 Trip model 应该在 baseCurrency 字段加 assert(长度 3) |

### M-33: `ExpenseRepository` 5 个 `create/update/delete/restore` 都没校验 amount > 0

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` 全文 |
| **严重度** | 🟡 M |
| **问题** | 详情页编辑可以改 amount=0(UI 没禁),数据库 CHECK 约束兜底抛 exception |
| **修复** | 入口处 `assert(amount > 0)` 或返回 ArgumentError |

### M-34: `app_settings.dart` `fromJson` 强转 + `?? 'local'` 不可靠

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/models/app_settings.dart:74-83` |
| **严重度** | 🟡 M |
| **问题** | `json['mode'] as String?` 强转,如果是 int 直接抛 TypeError |
| **修复** | `try { (json['mode'] as String?) ?? 'local' } catch (_) { 'local' }` |
| **关联** | M-2,S-3 |

### M-35: `group_repository.dart` `create` 的 `groupId` 可选参数,没在 widget 暴露

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/group_repository.dart:46-48` |
| **严重度** | 🟡 M |
| **问题** | 接受外部 groupId 但 UI 永远生成新 UUID |
| **修复** | 删除 `groupId` 参数,或加注释说明是测试用 |

---

## 🟢 L(轻微,16 条)

> **修复原则**:月度清理,代码风格 / 一致性 / 优化点。

### L-1: `_parseColor` 4 份重复(已在 M-2/M-3)

**注**:M-2 已包含此条。L-1 取消。

### L-2: `TransferRecord` Dart 端缺 `currency` 字段

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/models/transfer_record.dart` |
| **严重度** | 🟢 L |
| **问题** | schema 有 `currency` 字段,Dart 端 model 漏 |
| **修复** | 加 `final String currency;`,sync 时 push |

### L-3: `Member.copyWith` 用 sentinel object 风格只有这一个类用,其它 copyWith 不一致

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/models/member.dart:79-99` |
| **严重度** | 🟢 L |
| **问题** | `Object? groupId = _sentinel`,其它 model copyWith 都用 `??` 模式 |
| **修复** | 统一用一个项目级的 `sentinel.dart` |

### L-4: `split_type_selector.dart` `value.clamp(0, math.max(maxVal, 1.0))` 在 maxVal 极小时可能 NaN

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/widgets/split_type_selector.dart:390` |
| **严重度** | 🟢 L |
| **问题** | `_ratios` 全部 0 时 maxVal = 1(初始),但 ratios 状态计算可能 NaN |
| **修复** | clamp 前 sanity check |

### L-5: `_DatePickerTile` 在 trip_create / trip_edit 复制粘贴

| 字段 | 内容 |
|---|---|
| **文件** | `trip_create_screen.dart:180-223`、`trip_edit_screen.dart:197-242` |
| **严重度** | 🟢 L |
| **问题** | 两个 `_DatePickerTile` widget 类完全一样 |
| **修复** | 提到 `lib/presentation/widgets/date_picker_tile.dart` |

### L-6: `hardcoded` 颜色 `Color(0xFF2E7D32)` 等在 4 个文件用

| 字段 | 内容 |
|---|---|
| **文件** | `member_manage_screen.dart:244`、`group_manage_screen.dart:319`、`ai_settings_screen.dart:47,168,192`、`about_screen.dart:1`(via constants) |
| **严重度** | 🟢 L |
| **问题** | 主题色硬编码,暗色模式失效 |
| **修复** | 集中到 `lib/core/theme/colors.dart`(其实没建这个目录,目前主题色全在 main.dart) |

### L-7: `TextFormField` validator 缺长度校验(destination 100 char 限制等)

| 字段 | 内容 |
|---|---|
| **文件** | `trip_create_screen.dart`、`trip_edit_screen.dart` |
| **严重度** | 🟢 L |
| **问题** | 文档说 destination ≤ 100 字,UI 没限制 |
| **修复** | `validator: (v) => v != null && v.length > 100 ? '最长 100 字' : null` |

### L-8: `test/` 缺很多 unit / integration 测试

| 字段 | 内容 |
|---|---|
| **文件** | `test/` 全部 |
| **严重度** | 🟢 L |
| **问题** | `expense_provider_test.dart` 有但 `trip_provider_test` 不全;`group_repository_test` 缺(其实有,但不全);`seed_data_test` 缺 |
| **修复** | 月度补充 |

### L-9: `ExpenseRepository.update` 第 224-225 行用 `current.syncStatus` 但 update 完成后**没改 updatedAt 在 create 里**

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` |
| **严重度** | 🟢 L |
| **问题** | `create` 时 `createdAt: now, updatedAt: now` 正确;`update` 时 `updatedAt: _clock()` 正确 |
| **影响** | 实际正确,仅记录 |

### L-10: `Riverpod 2.x` 用 `StateNotifierProvider` 是 deprecated,推荐 `NotifierProvider`

| 字段 | 内容 |
|---|---|
| **文件** | 所有 `*_provider.dart` |
| **严重度** | 🟢 L |
| **问题** | 用了老的 `StateNotifierProvider` 而非 `NotifierProvider` |
| **修复** | 重构(工作量中等) |

### L-11: `TODO` 注释 `ai_config.dart:46` "TODO: 填入你的 M3 API Key" 但**这个 TODO 永远不需要做**(用户在设置页改)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/core/ai_config.dart:46` |
| **严重度** | 🟢 L |
| **修复** | 删 TODO |

### L-12: `auth_screen.dart` `Text('您可以继续本地使用本软件', style: ...)` 硬编码中文

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/auth_screen.dart:120` |
| **严重度** | 🟢 L |
| **问题** | 项目 V1.1 准备做繁体/英文,需要 i18n |
| **修复** | 抽到 `l10n/` |

### L-13: `expense_list_screen.dart` 类别筛选 chip 横滑体验没指示

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_list_screen.dart:184-213` |
| **严重度** | 🟢 L |
| **问题** | 横向 ListView 没阴影提示"可滑动" |
| **修复** | 右侧加渐变 fadeOut 阴影 |

### L-14: `seed_data.dart` 硬编码 demo trip `member-demo-001` 的 createdBy 在没有 demo user 上下文时显示 ghost

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/seed_data.dart:21, 137, 174` |
| **严重度** | 🟢 L |
| **修复** | 改 createdBy = kCurrentUserId |

### L-15: `AuthScreen` 的 `Navigator.pop(context, true)` 成功时返回 true,但 `_openAuth` 检查 `loggedIn == true` 之后 pop SnackBar 弹 "即将同步" 但 sync 还没启动

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/trip_list_screen.dart:218-222` |
| **严重度** | 🟢 L |
| **问题** | "数据即将同步" 是空话(sync engine 没启) |
| **修复** | 修 S-5/S-9 |

### L-16: `analysis_options.yaml` 注释 "Uncomment to enable" 但 README 没说

| 字段 | 内容 |
|---|---|
| **文件** | `analysis_options.yaml:24-25` |
| **严重度** | 🟢 L |
| **修复** | 删注释 |

---

## 🔵 N(战略待决,3 条)

> **不是 bug,但需要你做决策**。不决策会一直影响交付。

### N-1: PRD v0.3 三个 P0 功能(语音/重复/统计)做不做?

| 字段 | 内容 |
|---|---|
| **文件** | `docs/01-requirements/02-prd.md` 第 103-145 行;`docs/03-management/项目文件目录结构一览表.md` |
| **严重度** | 🔵 N(战略) |
| **状态** | PRD/FSD/用户故事/roadmap 都承诺 P0,代码 0 实现 |
| **决策** | **必须 3 选 1**:(1) 砍掉 v0.3 这 3 个 P0,降级 V1.1,改文档 (2) 加快实现(预计 1-2 周) (3) 继续"在路上" — 不推荐,产品诚信风险 |
| **建议** | 选 (1)。3 个 P0 都是 nice-to-have,真正高频用是 6 种分摊 + 4 宫格结算 + 离线。统计可以 V1.1 用更成熟的 BIRT / metabase 工具 |
| **关联** | S-15, M-22, M-23, M-30 |

### N-2: 领先 origin/main 20 commit 何时推?推到哪?

| 字段 | 内容 |
|---|---|
| **文件** | issue-tracker 多次提到;`pc-migration-guide.md:64-66` 提到 GitHub push 失败(国内连接超时) |
| **严重度** | 🔵 N(战略) |
| **状态** | dev 分支 4 commit + main merge commit,**但 origin 还没收到**;GitHub 国内超时 |
| **决策** | (1) 推 GitHub → 用 SSH / 走代理 (2) 推 Gitee(国内快) (3) 暂存本地不推,直接发布新版本 |
| **建议** | 推 Gitee(国内快)+ GitHub(用代理);设 main 为只读、dev 为开发;PR review 流程 |
| **关联** | issue-tracker / 一览表 |

### N-3: Android 模拟器问题暂时不处理(按用户指示跳过本目录相关讨论)

| 字段 | 内容 |
|---|---|
| **文件** | (n/a,跳过) |
| **严重度** | 🔵 N(已决策) |
| **状态** | 用户明确要求:本评估不收录模拟器问题;相关 ISSUE-014 / emulator-boot-report 不在本文档范围 |
| **决策** | 已决策(跳过),后续如需评估请告知 |

---

## 总结表

| 类别 | 数量 | 修复窗口 |
|---|---|---|
| 🔴 S 严重 | 27 | 发布前 |
| 🟡 M 中等 | 35 | 1-2 周 |
| 🟢 L 轻微 | 16 | 月度 |
| 🔵 N 战略 | 3 | 决策窗口 |
| **总计** | **81** | |

**完整修复优先级和行动方案**见 [03-fix-priorities.md](03-fix-priorities.md)

**横向分类汇总**见 [02-by-category.md](02-by-category.md)

**1 页执行摘要**见 [05-evaluation-summary.md](05-evaluation-summary.md)
