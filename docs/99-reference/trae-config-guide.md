# Trae IDE 配置指南

> 本文详细说明如何把 Trae 配置成"主力 IDE + M3 主力模型 + Qwen3.6 备力模型"的最佳状态。
> 配置时间：约 5-10 分钟。

---

## 一、Trae 简介

Trae（字节跳动出品）是基于 VS Code 的 AI IDE，**完全免费**、**中文原生**、**AI Builder 模式**对零基础友好。

它有两种版本：
- **Trae International**（国际版）
- **Trae CN**（国内版，你装的是这个）

配置位置和方式两种版本类似。

---

## 二、配置 1：MiniMax M3（主力模型）

### 步骤

1. **打开 Trae 设置**
   - 快捷键：`Ctrl + ,`（Win/Linux） / `Cmd + ,`（Mac）
   - 或：菜单 → 文件 → 首选项 → 设置

2. **找到 AI / Models 设置**
   - 在搜索框输入：`Models` 或 `AI`
   - 找到类似「Models」「AI Provider」「Custom Provider」的选项

3. **添加自定义 Provider**
   - 点击「+ Add Custom Provider」或「添加自定义模型」
   - 填写以下信息：

   | 字段 | 填什么 |
   |---|---|
   | **Provider Name** | `MiniMax-M3`（或你喜欢的名字）|
   | **Provider Type** | `OpenAI Compatible` |
   | **Base URL** | `https://api.MiniMax.com/v1` |
   | **API Key** | 你的 M3 Coding Plan API Key |
   | **Model** | `MiniMax-M3` |
   | **Max Tokens** | `8192`（按需调整）|
   | **Temperature** | `0.7`（默认值）|

4. **保存**
   - 点「Save」或「OK」
   - 等待验证（可能会弹窗问"是否启用"）

5. **设为默认**
   - 在模型列表中，把 M3 拖到第一位 / 点击「Set as Default」

---

## 三、配置 2：Qwen3.6 35B（备力模型，本地）

### 步骤

1. **确认 Qwen3.6 已在 LM Studio 启动**
   - 打开 LM Studio
   - 加载模型 `qwen3.6-35b-a3b-apex-balanced`
   - 启动 Local Server
   - 确认地址：`http://192.168.1.60:8033/v1`

2. **测试连通性**（在 PowerShell 里）
   ```powershell
   curl http://192.168.1.60:8033/v1/models
   ```
   应返回 JSON 包含模型列表。

3. **在 Trae 添加第二个 Provider**
   - 同样路径：Settings → Models → Add Custom Provider
   - 填写：

   | 字段 | 填什么 |
   |---|---|
   | **Provider Name** | `Qwen3.6-Local` |
   | **Provider Type** | `OpenAI Compatible` |
   | **Base URL** | `http://192.168.1.60:8033/v1` |
   | **API Key** | `lm-studio`（任意字符串，LM Studio 不校验）|
   | **Model** | `qwen3.6-35b-a3b-apex-balanced` |
   | **Max Tokens** | `4096` |
   | **Temperature** | `0.7` |

4. **保存**

---

## 四、配置 3：项目级 AI 指令加载

我们项目根目录已有 `.trae/instructions.md`，Trae **自动**会在你打开项目时加载它。

### 验证方法

1. 用 Trae 打开项目文件夹：
   - 菜单 → 文件 → 打开文件夹
   - 选择：`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger`
   - 信任该工作区

2. 打开 AI 对话面板：
   - 快捷键：`Ctrl + L`（左侧）或 `Ctrl + I`（右侧）
   - 或：菜单 → 查看 → AI 对话

3. 输入测试问题：
   ```
   你好，请告诉我这个项目是做什么的？
   ```

4. 观察 AI 回复：
   - ✅ 如果它说"AI 旅行账本，自驾游记账工具..." → 配置成功
   - ❌ 如果它说"我不知道这是什么" → 检查 `.trae/instructions.md` 是否被加载

### 强制加载（如果没自动加载）

- 在 AI 对话框输入 `@/instructions.md` 强制引用项目指令
- 或把 `.trae/instructions.md` 的内容复制到对话里

---

## 五、使用建议

### 5.1 何时用 M3（云端）
- 复杂 Agent 任务（多文件重构）
- 复杂 Bug 排查
- 长上下文（> 8K tokens）

### 5.2 何时用 Qwen3.6（本地）
- 日常代码补全
- 简单问答
- 文档撰写
- 敏感代码（数据不出本机）
- 网络不稳定时

### 5.3 切换方法
- AI 对话框顶部有模型选择器
- 或在 Settings → Models 里临时切换

---

## 六、常见问题

### Q1: M3 配置后报错 "401 Unauthorized"
**原因**：API Key 错或过期
**解决**：重新核对 MiniMax M3 Coding Plan 的 API Key

### Q2: Qwen3.6 配置后报错 "Connection refused"
**原因**：LM Studio 未启动或端口错
**解决**：
1. 打开 LM Studio → Developer → Server
2. 确认 Server is running
3. 确认端口 8033
4. 测试：`curl http://192.168.1.60:8033/v1/models`

### Q3: 切换模型后没生效
**解决**：
1. 重启 Trae
2. 或关闭 AI 面板重新打开

### Q4: AI 回复很慢
- M3 慢：检查网络（云端依赖）
- Qwen3.6 慢：本机 GPU 弱，考虑换小模型

### Q5: 找不到了 `instructions.md` 的内容
- Trae 自动加载 `.trae/instructions.md`
- 也可以手动在对话里 @ 它

---

## 七、Trae 高级功能（建议用起来）

| 功能 | 快捷键 | 用途 |
|---|---|---|
| AI 对话 | `Ctrl + L` | 多轮对话 |
| 行内编辑 | `Ctrl + I` | 选中代码 → AI 改写 |
| AI Builder | 左侧 AI 图标 | 从 0 到 1 生成 |
| Composer | `Ctrl + Shift + I` | 多文件编辑 |
| @ 文件 | `@filename` | 把文件加到上下文 |
| @ 目录 | `@folder/` | 把目录加到上下文 |

---

## 八、配置后请测试

跑完上面的配置，请用以下问题测试 AI 是否能正常理解项目：

**问题 1**（基础）:
```
请告诉我这个项目的产品定位和 MVP 范围
```

**问题 2**（细节）:
```
M3（MiniMax-M3）的 coding plan 已经付费，请根据 docs/02-architecture/04-adr/ADR-003-ide-choice.md 验证配置是否正确
```

**问题 3**（任务）:
```
请根据 docs/01-requirements/02-prd.md 中 E-001 的验收标准，
在 lib/screens/trips/ 目录下生成 trip_list_screen.dart 的代码框架
```

> **如果 3 个问题都答得不错** → 配置完美，可以开始干活了。
> **如果答得不对** → 检查 .trae/instructions.md 是否被加载，或把项目目录重新打开一次。

---

*配置时间：~10 分钟 | 难度：⭐☆☆☆☆*
