# 技术选型 (Tech Stack)

**版本**: v0.1
**日期**: 2026-06-14

---

## 一、移动端

### 选型: Flutter 3.x (Dart) ✅

**理由**:
- 🟢 **跨平台**: 一套代码 = Android + iOS，零成本扩 iOS
- 🟢 **AI 代码生成质量最高**: Cursor / Trae / Claude 都对 Flutter 友好
- 🟢 **Dart 语法对 C 程序员友好**: 强类型
- 🟢 **中文社区活跃**: 大量中文教程、文档
- 🟢 **官方提供 Material Design 3**: 现代化 UI

**替代方案对比**:

| 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| **Flutter** | 跨平台、AI 友好 | 包体积稍大（~15MB） | ✅ **选** |
| React Native | JS 生态 | 调试坑多、性能差 | ❌ |
| Android Native (Kotlin) | 性能最优 | 需学 Kotlin + Java OOP | ❌ |
| iOS Native (Swift) | iOS 体验最佳 | 需学 Swift、V1.1 还得改 | ❌ |
| Tauri (Web) | 包体积小 | 移动生态弱、不成熟 | ❌ |

**关键依赖**:
```yaml
dependencies:
  flutter: sdk
  flutter_riverpod: ^2.4.0      # 状态管理
  go_router: ^13.0.0            # 路由
  supabase_flutter: ^2.0.0      # BaaS 客户端
  hive: ^2.2.3                  # 本地 NoSQL
  sqflite: ^2.3.0               # 本地 SQL
  intl: ^0.19.0                 # 国际化
  uuid: ^4.0.0                  # UUID 生成
  image_picker: ^1.0.0          # 拍照
  share_plus: ^9.0.0            # 系统分享
  fl_chart: ^0.65.0             # 图表
```

---

## 二、后端 (BaaS)

### 选型: Supabase ✅

**理由**:
- 🟢 **一体化**: Postgres + Auth + Storage + Realtime
- 🟢 **免费层够用 MVP**: 500MB DB / 2GB 流量 / 1GB 存储
- 🟢 **官方提供 Flutter SDK**
- 🟢 **开源**: 数据量大时可自托管
- 🟢 **Postgres 强类型**: 复杂关系查询得心应手

**替代方案**:

| 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| **Supabase** | 一体化、Flutter SDK | 数据库在境外 | ✅ **选** |
| Firebase | 谷歌系、生态大 | 收费、NoSQL 不擅长复杂关系 | ❌ |
| 自建 Node.js | 灵活 | 运维成本高 | ❌ MVP 不选 |
| LeanCloud | 国内、便宜 | 文档差、生态弱 | ⬜ 备选 |
| 阿里云函数计算 | 国内 | 复杂、运维成本 | ❌ |

**Supabase 免费层限制**:
- 500 MB 数据库
- 2 GB 出口流量
- 1 GB 存储
- 50,000 月活用户

> 对 MVP 来说，500 用户以下完全够用。

---

## 三、AI 编程工具

### 主选: Trae IDE ✅

**理由**:
- 🟢 **中文友好**（字节出品）
- 🟢 **完全免费**
- 🟢 **对接本地模型方便**
- 🟢 **AI Builder 模式**对零基础友好
- 🟢 **隐私模式**（代码可不上传）

### 备选: Cursor 免费版

**理由**:
- 生态成熟、模型新
- Composer Agent 强
- VS Code 衍生，兼容性好

### 决策

**主用 Trae + 备 Cursor 免费版**（参考 ADR-003）

---

## 四、AI 模型

### 主: 本地 Qwen3.6 35B (LM Studio)

| 项 | 值 |
|---|---|
| 地址 | http://192.168.1.60:8033/v1 |
| 协议 | OpenAI 兼容 |
| 费用 | 0 token 费 |
| 用途 | 日常代码生成、文档撰写、问题解答 |

### 备: 云端 API

| 服务 | 价格 | 用途 |
|---|---|---|
| DeepSeek | ¥1/百万 token | 复杂任务 |
| 智谱 GLM-4 | ¥1/百万 token | 中文场景 |
| 通义千问 | ¥4-20/百万 token | 通用 |

> 关键决策：本地为主，云端为辅。**预估每月 API 费用 < ¥10**

---

## 五、设计工具

| 工具 | 用途 | 费用 |
|---|---|---|
| **Figma** | 界面设计 | 免费层 |
| **Galileo AI** | 设计稿转代码 | 免费层 |
| **IconKitchen** | 图标生成 | 完全免费 |
| **Excalidraw** | 流程图 | 完全免费 |

---

## 六、代码托管与 CI/CD

| 工具 | 用途 | 费用 |
|---|---|---|
| **GitHub** | 代码托管 | 私有仓库无限 |
| **GitHub Actions** | CI/CD | 2000 分钟/月 |
| **Codemagic** | Flutter 专用 CI | 免费层 500 分钟/月 |

---

## 七、监控与分析

| 工具 | 用途 | 费用 |
|---|---|---|
| **Sentry** | 崩溃监控 | 5K 事件/月 |
| **Firebase Analytics** | 用户行为 | 完全免费 |
| **Supabase Logs** | 后端日志 | 免费层 |

---

## 八、开发环境

| 工具 | 用途 |
|---|---|
| **Trae / Cursor** | 主 IDE |
| **Android Studio** | 模拟器、APK 编译 |
| **Flutter SDK** | 跨平台框架 |
| **JDK 17** | Java 运行时 |
| **Android SDK** | Android 工具 |
| **Git** | 版本控制 |
| **Postman / Insomnia** | API 调试 |

---

## 九、决策总览

| 维度 | 选型 | 决策日期 |
|---|---|---|
| 移动端 | Flutter | 2026-06-14 |
| 后端 | Supabase | 2026-06-14 |
| IDE | Trae 主 + Cursor 备 | 2026-06-14 |
| AI 模型 | 本地 Qwen3.6 + 云端 API | 2026-06-14 |
| 状态管理 | Riverpod | 2026-06-14 |
| 路由 | go_router | 2026-06-14 |
| 本地存储 | Hive + SQLite | 2026-06-14 |

> 详见 `docs/02-architecture/04-adr/` 下的 ADR 文档，每个选型有详细理由。
