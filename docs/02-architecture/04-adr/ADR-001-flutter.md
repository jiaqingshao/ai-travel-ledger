# ADR-001: 选择 Flutter 作为移动端框架

**状态**: 已采纳
**日期**: 2026-06-14
**决策者**: 创始人

---

## 背景

我们需要一个移动端框架来构建 AI 旅行账本的 Android 和 iOS 应用。创始人有 C 和 Python 编程基础，无 Java/Kotlin/Swift 经验。

## 候选方案

### 方案 1: Flutter (Dart) ✅
- 跨平台，一套代码
- 强类型，对 C 程序员友好
- AI 工具支持度高

### 方案 2: React Native (JavaScript/TypeScript)
- JS 生态大
- 但 JS 弱类型，不利于长期维护
- 调试坑多

### 方案 3: Android Native (Kotlin)
- 性能最优
- 但需学 Kotlin + Java OOP
- iOS 还得学 Swift

### 方案 4: iOS Native (Swift)
- iOS 体验最佳
- 但 Android 还得学

### 方案 5: Tauri (Web)
- 包体积小
- 移动生态弱，不成熟

## 决策

**选择 Flutter 3.x (Dart)**

## 理由

| 维度 | 评估 |
|---|---|
| 跨平台 | ✅ 一套代码 = Android + iOS |
| 学习成本 | ✅ Dart 强类型，对 C 程序员友好 |
| AI 代码生成 | ✅ Cursor / Trae / Claude 都对 Flutter 友好 |
| 中文社区 | ✅ 大量中文教程 |
| 性能 | ✅ 60fps 流畅度 |
| 生态 | ✅ 官方 Package 多（特别是 Supabase SDK）|
| UI 设计 | ✅ Material Design 3 现代化 |

## 后果

### 正面
- 一个团队即可覆盖 Android + iOS
- 创始人可以零基础上手
- AI 编程效率最大化

### 负面 / 风险
- 包体积比原生大（~15MB，可接受）
- 需要学习 Dart 语法（预估 1-2 周）
- 部分原生功能需要写 Platform Channel（少数情况）

### 缓解措施
- 充分用 Supabase / Firebase 等成熟 BaaS，避免原生需求
- 必要时雇 Flutter 兼职

## 备注

- 状态管理选 **Riverpod**（类型安全 + 测试友好）
- 路由选 **go_router**（官方推荐）
- 本地存储选 **Hive + SQLite**（Hive 缓存，SQLite 复杂查询）
