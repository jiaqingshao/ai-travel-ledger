# ADR-003: 选择 Trae 作为主 IDE（Cursor 免费版备用）

**状态**: 已采纳
**日期**: 2026-06-14
**决策者**: 创始人

---

## 背景

创始人要开始 AI 辅助编程，需要选择一款 AI IDE。约束条件：
- 编程基础薄弱（C、Python）
- 想用 AI 加速开发
- 想要免费方案
- 有本地 Qwen3.6 35B 模型可对接
- 有云端 MiniMax M3 coding plan 可用

## 候选方案

### 方案 1: Trae (字节跳动) ✅
- 完全免费（当前）
- 中文原生
- 字节系
- AI Builder 模式
- 支持本地模型 + 云端 API 接入

### 方案 2: Cursor (Anysphere)
- 生态成熟、用户量大
- 免费版功能有限
- Pro $20/月
- 英文为主

### 方案 3: VS Code + Continue
- 完全免费
- 插件化
- 配置稍复杂
- 中文支持一般

### 方案 4: Windsurf
- 免费层够用
- Cascade Agent 强
- 中文支持一般

## 决策

**主用 Trae + 备用 Cursor 免费版**
**模型策略：云端 MiniMax M3 为主，本地 Qwen3.6 为辅**

## 理由

### 为什么主选 Trae
| 维度 | 评估 |
|---|---|
| 价格 | ✅ 完全免费 |
| 中文 | ✅ 原生中文体验 |
| AI Builder | ✅ 零基础友好，端到端生成 |
| 本地模型 | ✅ 直接对接 http://192.168.1.60:8033/v1 |
| 云端 API | ✅ 支持自定义 OpenAI 兼容接口 |
| 隐私 | ✅ 隐私模式，代码可不上传 |

### 为什么备 Cursor 免费版
| 维度 | 评估 |
|---|---|
| 生态 | ✅ 兼容 VS Code 全插件 |
| Composer Agent | ✅ 复杂任务更强 |
| 模型新 | ✅ Claude 3.7 等接入更快 |

### 模型策略：M3 为主，Qwen3.6 为辅

#### 主力：云端 MiniMax M3 (用户已有 coding plan)
| 维度 | 评估 |
|---|---|
| 性能 | ✅ 1M 上下文、text+image+video 多模态 |
| 速度 | ✅ 云端 GPU 加速 |
| 编程能力 | ✅ 主流 AI 编程模型 |
| 费用 | ✅ 包含在 coding plan 里（已付费） |

#### 备力：本地 Qwen3.6 35B
| 维度 | 评估 |
|---|---|
| 隐私 | ✅ 数据不出本机（敏感代码） |
| 费用 | ✅ 0 token 费 |
| 速度 | ⚠️ 受本机 GPU 限制 |
| 能力 | ⚠️ 比 M3 略弱 |

#### 使用场景分配
| 任务类型 | 模型 | 理由 |
|---|---|---|
| 复杂 Agent 任务 | M3 | 能力强、上下文长 |
| 多文件重构 | M3 | 理解力强 |
| 日常代码补全 | Qwen3.6 | 免费、快 |
| 文档撰写 | Qwen3.6 | 中文友好、免费 |
| 简单问答 | Qwen3.6 | 免费、快 |
| 敏感代码 | Qwen3.6 | 数据不出本机 |

### 为什么不用 Cursor Pro
- M3 已在云端 + Trae 0 费 = 成本已经最优
- 等 AI 任务变多或 Trae 不够用再升级

## 后果

### 正面
- 主力 M3 coding plan 已付费，能力最强
- 日常任务用 Qwen3.6 完全免费
- 隐私敏感代码用本地模型
- 中英文混合体验都很好

### 负面 / 风险
- **Trae 是字节产品**，未来可能收费或下架
- 字节战略变化风险（参考飞书历史）
- 中文模型工具更新可能慢
- **依赖云端 M3 服务可用性**

### 缓解措施
- 同步用 Cursor 免费版，等于买保险
- 关键学习成果不依赖工具
- 重要的工程实践（Git、CI、测试）独立于 IDE
- M3 不可用时自动 fallback 到 Qwen3.6

## 配置方案

### Trae 主配置
```
# 配置 1：M3 (主力)
Provider: Custom (OpenAI 兼容)
Base URL: https://api.MiniMax.com/v1
API Key: <用户的 M3 API Key>
Model: MiniMax-M3

# 配置 2：Qwen3.6 (备力)
Provider: Custom (OpenAI 兼容)
Base URL: http://192.168.1.60:8033/v1
API Key: 任意字符串
Model: qwen3.6-35b-a3b-apex-balanced
```

### Cursor 备用
- 启动时使用免费层
- 2000 次补全 / 50 次慢速 Premium
- 复杂 Agent 任务用免费层额度
- API 接入 M3 + Qwen3.6 同上

## 备注

- 定期（季度）评估工具是否需要更换
- 关注字节 Trae 商业化动向
- 关注 Cursor Pro 是否值得升级
- M3 服务变更时及时更新配置
