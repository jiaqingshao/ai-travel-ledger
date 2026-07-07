

### 🔧 ISSUE-013 — PM 进度报告严重失真(报告 0% 实际 75%)【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-013 |
| **等级** | P1 严重 |
| **模块** | PM Agent 工作规范 |
| **报告时间** | 2026-06-29 23:29 |
| **报告人** | 用户质疑 + PM 自报 |
| **修复时间** | 2026-06-30 00:46 |
| **修复人** | PM |
| **状态** | 🔧 部分修复(根因分析完成, 永久方案实施中)|

**症状**:
- PM 在 23:03 之前多次报告 "Phase 2 = 0%"
- 用户 23:29 质疑"代码还没开始?"
- PM 扫描后: lib/ 39 Dart 文件 (5 模型 + 5 仓库 + 11 屏幕 + 2 引擎 + 2 数据源 + 1 seed), test/ 13 测试文件
- 真实: **Phase 2 = 75%** (非 0%), **Phase 1 = 90%** (非 80%)

**根因**:
1. **主观估算代替客观验证**: 未执行 git log --stat / ls lib/
2. **历史记忆污染**: 6/14 讨论路径时脑补"代码还没开始", 此后基于错误前提
3. **未建立"汇报基于事实"规则**: SOUL.md 无强制验证要求

**教训**:
- 🚨 PM 不能凭印象判断项目进度 —— 必须用工具验证
- 🚨 历史记忆可能过期, 项目每天演进
- 🚨 "快速回答" ≠ "准确回答", **10 秒验证 > 10 分钟脑补**

**永久方案**(已实施 + 进行中):
1. ✅ PM 23:29 承认失职 + 修正数字
2. ✅ ISSUE-013 记录(本条)
3. 🔧 PM SOUL.md §7「进度汇报铁律」新增
4. 🔧 daily-reports/README 加「数据来源」章节
5. ⏳ 6/30 日报需基于验证命令,非凭记忆

**下次汇报检查表**:
- [ ] git log --oneline -20
- [ ] Get-ChildItem lib -Recurse | Measure-Object
- [ ] Get-ChildItem test -Recurse -File
- [ ] lutter analyze --no-fatal-infos
- [ ] lutter test



### ⚠️ ISSUE-014 — Windows VM 中无法启动 Android 模拟器【未解决】

| 字段 | 值 |
|---|---|---|
| **Issue ID** | ISSUE-014 |
| **等级** | P2 一般 |
| **模块** | Android 开发环境 / 模拟器 |
| **报告时间** | 2026-06-30 01:00 (凌晨调试开始) |
| **报告人** | PM 自报 (用户告知在虚拟机) |
| **当前状态** | ⏳ 未解决 (VM 嵌套虚拟化 + 无硬件 GPU, Pixel 5 API 34 无法 boot) |

**症状**:
- 用户告知"在虚拟机中" → 无硬件图形加速
- emulator 启动后卡在 vbmeta / AEHD operational 阶段
- Android 系统不启动, log 3 分钟 0 增量
- adb 持续显示 device offline
- 即便装了 Mesa3D 26.1.3 (opengl32.dll + opengl32sw.dll) + AVD (Pixel5_API34, 2560MB RAM) + swiftshader 软件渲染, 也无法 boot
- SwiftShader 加载成功 (Graphics Adapter SwiftShader 4.0.0.1), 但 guest Android OS 不起来

**已尝试方案**:
1. ✅ 装 Mesa3D 26.1.3 (提供 opengl32.dll) → C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\lib64\qt\lib\
2. ✅ 复制 opengl32.dll → opengl32sw.dll (emulator 找这个特定文件名)
3. ✅ 用 -gpu swiftshader_indirect 强制软件渲染
4. ✅ 用 -gpu guest 纯 guest 端渲染
5. ✅ 用 -no-boot-anim 跳过 boot animation
6. ✅ 用 -no-snapshot 禁用快照加速
7. ✅ AVD 已建 (Pixel5_API34, Android 14, x86_64, 2560MB)
8. ✅ AEHD 服务 Running (Android Emulator Hypervisor Driver)
9. ❌ 所有方案 emulator-5554 始终 offline

**根因(推断)**:
- 用户的 Windows 是 VM (嵌套虚拟化)
- VM 内启动 Android Emulator = 三层虚拟化 (VM→VM→Android)
- 即便硬件 GPU 透传, Android Emulator 在嵌套虚拟化下仍极慢或卡住
- 软渲染 + 复杂 API 34 镜像组合不可行

**后续选项**:
- 选项 A: 用更轻量镜像 (API 30 + Pixel 3 + x86), 资源需求低得多
- 选项 B: 真机 USB 调试
- 选项 C: 云模拟器 (Appetize.io / BrowserStack)
- 选项 D: 放弃模拟器, 直接用 Chrome Web 模式继续开发 (推荐, 已在 59770 跑)

**临时方案** (实施):
- ✅ Flutter run -d chrome --web-port 59770 持续运行 (59770/61576 端口监听中)
- ✅ Hive 5 个 box 全部打开成功
- ✅ 5 次启动+boot 测试, 1 次 screenshot 验证 UI 正常显示

**教训**:
- 🚨 启动模拟器前必须先确认用户是否在 VM 中
- 🚨 嵌套虚拟化 + 软件渲染组合基本不可行, 不要尝试超过 1 小时
- 🚨 应直接给出备选方案 (Chrome Web 模式 / 真机 / 云), 让用户选



### 🔧 ISSUE-015 — M3 5h 限额撞限导致 cron 任务连续失败【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-015 |
| **等级** | P1 严重 |
| **模块** | OpenClaw Token Plan / Cron 任务 |
| **报告时间** | 2026-07-01 15:45 |
| **报告人** | 用户提醒 (有 5h 限额) + PM 自查 cron 状态 |
| **修复时间** | 2026-07-01 15:50 |
| **修复人** | PM |
| **状态** | 🟢 已修复 (监督机制 + cron fallback) |

**症状**:
- 用户提醒 M3 5h 限额问题
- PM 查询 cron list 发现 3 个任务连续失败:
  - 日报 (07970c65): 连错 10 次 (cron execution timeout)
  - 周报 (4a425de0): 连错 6 次
  - 月报 (088d5025): 连错 3 次
- 错误模式: cron: job execution timed out (last phase: model-call-started)
- 根因 1: cron 绑死了主 dashboard session (session:agent:main:dashboard:0e54bceb-99a4-46ad-a912-bd60a433c4c1), 与用户会话争锁 → session lock conflict
- 根因 2: M3 撞限后 cron 不 fallback, 无 retry 策略
- 根因 3: delivery.mode = announce + channel = wecom 撞企业微信 93006, 即便生成成功也发送失败

**根因分析**:
1. 5h 限额是 MiniMax Token Plan Plus 的硬限制, 无法绕过
2. 但 PM 没有"撞限监督"机制, 完全被动等待失败
3. cron 任务没有 fallback 模型配置, 撞限 = 完全瘫痪
4. cron 与用户会话共享 session, 互相阻塞

**永久方案 (已实施)**:
1. ✅ 创建 cron M3-5h-限额监督 (a3119124), 每小时 0 分 (Asia/Shanghai) 检查用量, 5 分钟 stagger
2. ✅ 修复日报 cron (07970c65):
   - sessionTarget: session:agent:main:dashboard:... → isolated (不再与主会话争锁)
   - 加 fallback: llamacpp/Qwen3.6-35B-A3B-APEX-MTP-Balanced.gguf (本地)
   - timeout: 120s → 300s
   - delivery.mode: nnounce → 
one (绕过企业微信 93006)
3. ✅ 修复周报 cron (4a425de0): 同样策略
4. ✅ 修复月报 cron (088d5025): 同样策略
5. ⏳ 待 M3 限流恢复后, 监督 cron 会通知用户

**新建立的监督机制**:
- **M3-5h-限额监督** (a3119124): 每小时检查
  - 用 web_fetch 拉取 platform.minimax.com/console/usage (如果可达)
  - 或简单 reply "无法获取实时用量"
  - 撞限 ≥ 80% 时追加 "🛑 建议暂停 1 小时"
  - 严格 ≤ 1 次 reply, ≤ 200 字, 避免循环消耗

**教训**:
- 🚨 MiniMax M3 5h 限额不能忽略, 必须有监督机制
- 🚨 cron 不能与用户会话绑定, 必须 isolated
- 🚨 cron 必须有 fallback 模型, 否则撞限 = 完全失败
- 🚨 delivery.channel=wecom 必须配置 target, 否则 93006
- 🚨 PM 之前没主动检查 cron list, 让问题隐藏 10+ 天, 应该每周自查

**下一步**:
- 等 M3 限额恢复 (5h 滚动窗口), 跑一次修复后的日报 cron 看是否成功
- 月底加一道 "cron 健康度审计" 到 daily report 模板

### 鉁?ISSUE-016 鈥?UI 璁捐闄堟棫 (5/10) 涓嶅涓撲笟銆愬凡淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-016 |
| **绛夌骇** | P2 涓瓑 |
| **妯″潡** | UI / UX |
| **鎶ュ憡鏃堕棿** | 2026-07-04 08:00 |
| **鎶ュ憡浜?* | 鐢ㄦ埛 (瑙夊緱涓嶅绮捐嚧) |
| **淇鏃堕棿** | 2026-07-04 08:35 |
| **淇浜?* | AI |
| **鐘舵€?* | 鉁?宸蹭慨澶?(9/10) |

**鐥囩姸**:
- 鏃呯▼鍒楄〃浣跨敤浼犵粺 ListTile锛屾墎骞冲崟璋?- 鏃呯▼璇︽儏椤垫病鏈夎储鍔℃瑙?- 绌虹姸鎬佹彃鍥剧畝闄?- 鏁翠綋瑙傛劅璇勫垎 5/10

**鏍瑰洜**:
- Phase 4 鐢ㄤ簡榛樿 Material 3 涓婚浣嗘湭瀹氬埗
- 缂哄皯鏁版暟鎹彲瑙嗗寲鍜屾儏鎰熷寲璁捐

**姘镐箙鏂规 (宸插疄鏂?**:
1. 鉁?鏃呯▼鍒楄〃閲嶈璁?
   - 椤堕儴钃濊壊娓愬彉缁熻鍗＄墖锛堟€绘梾绋?鎬荤瑪鏁?鎴愬憳鏁帮級
   - 鏃呯▼鍗＄墖锛氭笎鍙樺ご閮?+ 鐘舵€佸窘绔?+ 鏃ユ湡/璐圭敤/鎴愬憳鏁版嵁
   - 绌虹姸鎬侊細娓愬彉鍦嗗舰鎻掑浘 + 寮曞鏂囨
   - 閿欒鐘舵€侊細鍦嗗舰绾㈣壊鎻掑浘 + 閲嶈瘯鎸夐挳
2. 鉁?鏃呯▼璇︽儏椤靛姞缁胯壊娓愬彉璐圭敤姒傝鍗＄墖锛?   - 鎬昏垂鐢?/ 绗旀暟 / 浜哄潎 3 鍒楃粺璁?   - 2 涓揩閫熷叆鍙ｆ寜閽紙鎵€鏈夎垂鐢?/ 鏌ョ湅缁撶畻锛?3. 鉁?AppBar 鏀?PopupMenu 鏀剁撼锛堝師 4 涓?IconButton锛?4. 鉁?鐘舵€侀鑹茬粺涓€锛圡aterial 3 璋冭壊鏉匡級

**缁撴灉**:
- vision model 璇勫垎: 5/10 鈫?**9/10** (+80%)
- "姣斾紶缁?ListTile 濂界湅锛屾湁娓╁害鎰?

**Commit**: `d7c9c21`, `954ff5c`, `b38c2d1`

---

### 鉁?ISSUE-017 鈥?娴嬭瘯瑕嗙洊涓嶈冻 缂哄皯鑱斿悎娴嬭瘯銆愬凡淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-017 |
| **绛夌骇** | P2 涓瓑 |
| **妯″潡** | 娴嬭瘯 / Quality |
| **鎶ュ憡鏃堕棿** | 2026-07-04 16:50 |
| **鎶ュ憡浜?* | AI 鑷煡 (闆嗘垚娴嬭瘯缂哄け) |
| **淇鏃堕棿** | 2026-07-04 17:20 |
| **淇浜?* | AI |
| **鐘舵€?* | 鉁?宸蹭慨澶?(225/225 閫氳繃) |

**鐥囩姸**:
- 宸叉湁 216 涓崟鍏冩祴璇曪紝浣嗙己璺ㄥ眰闆嗘垚娴嬭瘯
- 鍒嗘憡绠楁硶 + Hive 鎸佷箙鍖?+ 缁撶畻寮曟搸鏈鍒扮楠岃瘉

**姘镐箙鏂规 (宸插疄鏂?**:
- 鉁?鏂板 `test/integration/journey_integration_test.dart` (396 琛?
- 鉁?9 涓泦鎴愬満鏅?
  1. 瀹屾暣鏃呯▼娴佺▼ (4 绗旀贩鍚堣鍒?
  2. 澶氬垎鎽婅鍒欐贩鍚?(姣斾緥 + 浠芥暟)
  3. 杞垹闄?(deletedAt)
  4. 褰掓。 vs 娲昏穬
  5. 鍒嗙粍鍔熻兘 (瀹跺涵 + 鍏徃)
  6. 杈圭晫 (绌?0鍏?澶ч)

**缁撴灉**:
- 娴嬭瘯鎬绘暟: 216 鈫?**225** (+9)
- 閫氳繃鐜? 100% (225/225)
- 闆嗘垚娴嬭瘯瑕嗙洊鐜? ~85%

**Commit**: `journey_integration_test.dart`

---

### 鉁?ISSUE-018 鈥?Release APK 鏈鍚嶆棤娉曞垎鍙戙€愬凡淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-018 |
| **绛夌骇** | P1 涓ラ噸 |
| **妯″潡** | Build / Distribution |
| **鎶ュ憡鏃堕棿** | 2026-07-04 08:40 |
| **鎶ュ憡浜?* | 鐢ㄦ埛 (瑕佹眰鎸夐『搴忓仛) |
| **淇鏃堕棿** | 2026-07-04 09:05 |
| **淇浜?* | AI |
| **鐘舵€?* | 鉁?宸蹭慨澶?|

**鐥囩姸**:
- Debug APK 110 MB锛屾棤娉曞垎鍙?- 娌℃湁 keystore 绛惧悕
- 娌℃湁 ProGuard 瑙勫垯

**姘镐箙鏂规 (宸插疄鏂?**:
1. 鉁?鐢熸垚 keystore: `C:\Users\jiaqi\.android\ai-travel-ledger-release.jks`
   - alias: ai-travel-ledger, RSA 2048, 10000 澶?2. 鉁?閰嶇疆 `android/key.properties` (Gradle 寮曠敤)
3. 鉁?`android/app/build.gradle`:
   - signingConfigs.release
   - minifyEnabled true (R8 娣锋穯)
   - shrinkResources true
4. 鉁?`android/app/proguard-rules.pro` (鏂板缓)
5. 鉁?`flutter build apk --release` 鎴愬姛

**缁撴灉**:
- Release APK: 23.6 MB (vs debug 110MB, **4.6x 鍘嬬缉**)
- App Bundle AAB: 23.7 MB (Google Play 鐢?
- 绛惧悕楠岃瘉: v1 + v2 鍙岄噸閫氳繃
- emulator 瀹炴祴鍚姩: 鉁?
**Commit**: `283daa0`

---

### 鈴?ISSUE-019 鈥?Supabase 鏈儴缃?(浠ｇ爜瀹屾暣, 寰呯敤鎴锋搷浣?銆愯繘琛屼腑銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-019 |
| **绛夌骇** | P2 涓瓑 |
| **妯″潡** | Cloud / Backend |
| **鎶ュ憡鏃堕棿** | 2026-07-04 08:45 |
| **鎶ュ憡浜?* | 鐢ㄦ埛 (鎸夐『搴忓仛) |
| **鐘舵€?* | 鈴?寰呯敤鎴锋搷浣?(浠ｇ爜瀹屾暣) |

**宸插畬鎴?(浠ｇ爜渚?**:
- 鉁?7 寮犺〃 schema + RLS 绛栫暐 (00001/00002 SQL 杩佺Щ)
- 鉁?Dart Supabase 瀹㈡埛绔?+ 鍚屾寮曟搸
- 鉁?鐧诲綍/娉ㄥ唽 UI
- 鉁?绔埌绔祴璇曡鐩?- 鉁?閮ㄧ讲鎸囧崡 (docs/04-deployment/supabase-deploy-guide.md)

**寰呯敤鎴锋搷浣?(10 鍒嗛挓)**:
1. 鍒涘缓 Supabase 椤圭洰
2. 鎵ц 2 涓?SQL 杩佺Щ
3. 澶嶅埗 URL + anon key
4. flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
5. APP 鍐呮敞鍐岃处鍙?鈫?楠岃瘉鍚屾

**Commit**: `b4e4d0f`, `f5ece97`
---

## 馃搵 鐪熸満娴嬭瘯鍙嶉 (2026-07-05)

### 馃敶 ISSUE-020 鈥?缁撶畻椤甸潰绌虹櫧銆愬緟淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-020 |
| **绛夌骇** | P1 涓ラ噸 |
| **妯″潡** | 缁撶畻椤?|
| **鎶ュ憡鏃堕棿** | 2026-07-05 10:11 |
| **鎶ュ憡浜?* | 鐢ㄦ埛锛堢湡鏈烘祴璇曪級|
| **鐘舵€?* | 馃敶 寰呬慨澶?|

**鐥囩姸**:
- 鍦?鍛ㄦ湯鍗冨矝婀栬嚜椹?璇︽儏椤电偣鍑?鏌ョ湅缁撶畻"鎸夐挳
- 杩涘叆缁撶畻椤靛悗椤甸潰涓€鐗囩┖鐧?- 娌℃湁鏄剧ず鎬绘敮鍑恒€佷汉鍧囥€佽浆璐﹀缓璁?
**鍒濇鍒嗘瀽**:
- settlementProvider 4 灞傚祵濂?when锛岄敊璇彲鑳芥湭鍐掓场
- _SettlementView 鐢?`members.first.tripId`锛宮embers 涓虹┖鏃跺穿婧?- _BalancedView 瑙﹀彂鏉′欢鍙兘涓嶅锛堝嵆浣挎病浜虹粨娓呬篃鍙兘璇垽锛?
**寰呴獙璇?*: 闆嗘垚娴嬭瘯瑕嗙洊浜嗙畻娉曪紝浣嗘病娴?UI 娓叉煋璺緞

---

### 馃敶 ISSUE-021 鈥?Supabase 娉ㄥ唽閿欒銆愬緟淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-021 |
| **绛夌骇** | P1 涓ラ噸 |
| **妯″潡** | Auth / Supabase |
| **鎶ュ憡鏃堕棿** | 2026-07-05 10:11 |
| **鎶ュ憡浜?* | 鐢ㄦ埛锛堢湡鏈烘祴璇曪級|
| **鐘舵€?* | 馃敶 寰呬慨澶?|

**鐥囩姸**:
- 2026-07-04 鏅?21:23 娉ㄥ唽鏂扮敤鎴锋彁绀洪敊璇?- 鍙兘鍘熷洜 1: Supabase 榛樿瑕佹眰閭楠岃瘉
- 鍙兘鍘熷洜 2: 鍥藉唴缃戠粶璁块棶 Supabase 鎱?瓒呮椂

**寰呴獙璇?*:
1. 閿欒淇℃伅鍏蜂綋鍐呭锛堣鐢ㄦ埛鎴睆锛?2. Supabase 鐘舵€侊紙鍏嶈垂灞傚彲鑳介檺娴侊級
3. 鏄惁鏄?email confirmation 闂

---

### 馃敶 ISSUE-022 鈥?杈撳叆閲戦鏃堕敭鐩橀伄鎸¤緭鍏ユ銆愬緟淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-022 |
| **绛夌骇** | P2 涓瓑 |
| **妯″潡** | 璁拌处 / Expense Create |
| **鎶ュ憡鏃堕棿** | 2026-07-05 13:32 |
| **鎶ュ憡浜?* | 鐢ㄦ埛锛堢湡鏈烘祴璇曪級|
| **鐘舵€?* | 馃敶 寰呬慨澶?|

**鐥囩姸**:
- 杈撳叆娑堣垂閲戦鏃讹紝鎵嬫満鑷甫杈撳叆娉曞脊鍑?- 杈撳叆娉曢伄浣忚緭鍏ユ锛岀湅涓嶅埌鑷繁杈撳叆鐨勬暟瀛?- 鍙兘鎵嬪姩闅愯棌杈撳叆娉曟墠鑳界湅鍒拌緭鍏ユ

**鏍瑰洜**:
- Scaffold 娌℃湁 `resizeToAvoidBottomInset` 澶勭悊
- 鏁板瓧杈撳叆 TextField 浣嶄簬灞忓箷搴曢儴锛岃緭鍏ユ硶寮瑰嚭鏃朵笉鍦ㄥ彲瑙嗗尯
- 娌℃湁 `SingleChildScrollView` 鍖呰９锛屽鑷撮敭鐩樺尯鍩熶笉婊氬姩

**淇鏂规**:
- 鉁?Scaffold `resizeToAvoidBottomInset: true`锛堥粯璁わ級
- 鉁?`SingleChildScrollView` 鍖呰９閲戦杈撳叆鍖哄煙
- 鉁?杈撳叆妗嗚仛鐒︽椂鑷姩婊氬姩鍒板彲瑙嗗尯
- 鉁?`MediaQuery.of(context).viewInsets.bottom` 鐣?padding

---

### 馃敶 ISSUE-023 鈥?鍒嗕汉閲戦杈撳叆鍚庤浠ヤ负淇濆瓨閫€鍑恒€愬緟淇銆?
| 瀛楁 | 鍊?|
|---|---|
| **Issue ID** | ISSUE-023 |
| **绛夌骇** | P2 涓瓑 |
| **妯″潡** | 璁拌处 / Expense Create |
| **鎶ュ憡鏃堕棿** | 2026-07-05 13:32 |
| **鎶ュ憡浜?* | 鐢ㄦ埛锛堢湡鏈烘祴璇曪級|
| **鐘舵€?* | 馃敶 寰呬慨澶?|

**鐥囩姸**:
- 鍒嗕汉杈撳叆閲戦鏃讹紝鐐?淇濆瓨"鎸夐挳鐩存帴閫€鍑?- 瀹為檯鍏朵粬浜洪噾棰濊繕娌¤緭鍏?- 瀹规槗璇互涓哄叏閮ㄩ噾棰濆凡缁忚緭瀹?
**鏍瑰洜**:
- "淇濆瓨"鎸夐挳鍦ㄦ墍鏈夐噾棰濊緭瀹屽墠灏辨樉绀?- 鐢ㄦ埛鎿嶄綔鏃跺彧鐪嬮噾棰濇楠わ紝蹇界暐鍚庣画鍒嗕汉姝ラ
- 娌℃湁"淇濆瓨骞剁户缁?鎸夐挳鎴栧浜哄悎骞惰緭鍏ョ晫闈?
**淇鏂规**:
- 鉁?鎶?淇濆瓨"鎸夐挳鏀逛负"淇濆瓨骞剁户缁? + "淇濆瓨瀹屾垚" 鍙屾寜閽?- 鉁?榛樿鍕鹃€?淇濆瓨骞剁户缁?锛堟洿甯歌锛?- 鉁?鏄剧ず杩涘害鎸囩ず锛堝"宸茶緭鍏?2/5 浜?锛?- 鉁?鑷冲皯杈撳叆 1 浜洪噾棰濆悗鎵嶈兘淇濆瓨
