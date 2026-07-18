# Hermes / MiniMax-M3 设置 512,000 tokens 上下文指南

> **目的**:把 Hermes Agent 当前会话使用的 `minimax/MiniMax-M3` 模型上下文设置成 512,000 tokens(≈ 512K)
> **起草时间**:2026-07-15
> **状态**:指南(未经实测 — Hermes 配置文件路径未确认)
> **风险等级**:🟡 中(可能影响成本 + 生成速度,不一定能开到 512K)

---

## ⚠️ 重要前提(必须先确认)

### 1. Hermes 配置文件位置未确认

**我之前记忆里写的 `C:\Users\jiaqi\.hermes\hermes.json` 已验证不存在**(2026-07-15 实际核查)。Hermes 桌面应用**可能有不同的配置位置**,例如:
- `C:\Users\jiaqi\AppData\Roaming\hermes\`
- `C:\Users\jiaqi\AppData\Local\hermes\`
- `C:\Program Files\Hermes\config\`
- Hermes 应用内 Settings 页面(UI 形式存储)
- **完全由你**告诉我具体位置

**如果你不知道,先做"寻找配置文件"步骤(本文档第 2 节)。**

### 2. MiniMax-M3 模型是否原生支持 512K?

**不能保证**。每个 LLM 模型有原生 context window 上限,典型值:

| 模型 | 原生 ctx | 可手动开到 512K? |
|---|---|---|
| `minimax/MiniMax-M3` (当前) | 8K ~ 200K(可能) | ❓ **未知**,需查 minimax 官方文档或客服 |
| `minimax/MiniMax-M2.7`(旧) | 8K | ❌ 不能 |
| `Qwen3.6-35B-A3B-APEX-MTP-Balanced` (本地) | **262144** | ❌ 不能(需换 GGUF) |
| Claude Sonnet 4 | 200K | ❌ 不能 |
| GPT-4o | 128K | ❌ 不能 |
| Gemini 2.5 Pro | 1M-2M | ✅ 可以(且超过) |

**建议先做 "查 MiniMax-M3 context 上限" 步骤,确认能不能开 512K。**

### 3. 即使能开,成本和速度影响

- **成本**: 上下文变大 → API 收费按 token 计,输入费用可能涨 2-3 倍(M3 是按 token 计费的)
- **速度**: 长上下文 attention 计算变慢,响应延迟增加
- **质量**: 部分模型在长上下文下会"遗忘"中间内容(M3 是否有此问题未知)

---

## 📋 设置步骤(假设配置文件已找到)

### Step 1: 寻找 Hermes 配置文件

打开 **管理员 PowerShell**,运行:

```powershell
# 搜所有 hermes 相关文件
Get-ChildItem -Path 'C:\Users\jiaqi','C:\ProgramData','C:\Program Files\Hermes*' -Recurse -Include '*hermes*','*Hermes*' -ErrorAction SilentlyContinue | 
    Where-Object { -not $_.PSIsContainer } |
    Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
```

**预期输出候选**:
- `C:\Users\jiaqi\AppData\Roaming\Hermes\config.json`
- `C:\Users\jiaqi\AppData\Local\Hermes Desktop\settings.json`
- `C:\Program Files\Hermes\hermes.json`
- ...(看具体输出)

### Step 2: 备份配置文件

```powershell
# 把找到的文件路径赋值给 $f
$f = "<你找到的 hermes 配置文件路径>"
Copy-Item -LiteralPath $f -Destination "$f.bak-512k-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "已备份"
```

### Step 3: 查 MiniMax-M3 context 上限

**3a. 看官方文档**: `https://platform.minimaxi.com/document/Model_Specs`(可能路径,实际要查)

**3b. 看 Hermes 默认 config 里 M3 的 max_tokens 字段**(以这个为基准):

```powershell
# 读取配置文件,搜 "MiniMax-M3" 或 "max_tokens" 字段
Select-String -Path $f -Pattern 'M3|max_tokens|context' -Context 3,3
```

**3c. 决定**:如果 M3 默认已经是 200K(支持的最大值),**不能直接改 512K**,只能:
- 升级到支持 512K 的模型(如某些 minimax 旗舰版)
- 或保持 200K,接受现状

### Step 4: 修改配置文件(必须先备份!)

打开配置文件(用记事本 / VS Code),找类似这样的结构:

```json
{
  "providers": {
    "minimax": {
      "models": {
        "MiniMax-M3": {
          "context_window": 200000,    // ← 这就是 ctx 大小
          "max_tokens": 8000          // ← 这是单次输出上限,跟 ctx 不同
        }
      }
    }
  }
}
```

**改法**:

```json
{
  "providers": {
    "minimax": {
      "models": {
        "MiniMax-M3": {
          "context_window": 512000,    // ← 改成 512000
          "max_tokens": 8000          // ← 通常不必改,除非想延长输出
        }
      }
    }
  }
}
```

**保存并关闭**。

### Step 5: 重启 Hermes

1. 完全退出 Hermes(系统托盘右键 → Quit)
2. 重新打开 Hermes
3. 验证:发起新对话,问模型"你能记住多少 token 的上下文?",理论上现在可以回答 512K

---

## 🔍 验证 512K 是否真的生效

### 方法 1: 在 Hermes 里问模型

```
用户: "你的上下文窗口是多大?"
理想回答: "我的上下文窗口是 512,000 tokens" 或 "我的最大上下文是 512K tokens"
```

### 方法 2: 测试长上下文(用大文档)

1. 找一份 30 万字的中文文档
2. 粘贴到对话框,让模型"总结这份文档"
3. 如果能正确回忆文中某段细节 → 512K 生效
4. 如果"中间内容"开始失忆 → 实际 ctx 仍然较小

### 方法 3: 看 Hermes 日志 / 配置确认

```powershell
# 重启后看 Hermes 日志(可能在 AppData)
Get-Content "$env:APPDATA\Hermes\logs\*.log" -Tail 100 | Select-String -Pattern 'context|max_tokens|M3'
```

---

## ⚠️ 失败回滚

如果 512K 设置后 Hermes 报错或行为异常:

```powershell
# 1. 退出 Hermes
# 2. 还原备份
$f = "<你改过的 hermes 配置文件>"
$bak = Get-ChildItem "$f.bak-512k-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item -LiteralPath $bak.FullName -Destination $f -Force
# 3. 重启 Hermes
```

---

## 💡 如果 M3 不能开 512K,替代方案

| 替代 | 配置 | 优点 | 缺点 |
|---|---|---|---|
| **换 minimax 旗舰模型**(如 M3-Max-512K) | 平台支持的话 | 真正 512K | 费用高 |
| **保留 200K,长任务分块** | 手动分段给模型 | 通用 | 手动工作 |
| **用 Qwen3.6 35B 本地** | baseUrl http://192.168.1.60:8033/v1 | 离线免费 | ctx 262K(也不够 512K) |
| **RAG(检索增强)** | 外挂向量数据库 | 实际可"记住"无限 | 架构复杂 |

---

## 📞 我能帮你什么(红线内)

我能帮你**写**关于这个的代码或文档到项目目录,但**不能直接动 Hermes 配置文件**(因为不在白名单 `workspace/projects/` 下)。

**如果你执行了 Step 1-5 把配置文件改坏了**,我可以帮你:
- 写还原脚本到 `scripts/rollback-512k.ps1`
- 写"寻找 Hermes 配置文件"的 .ps1 到 `scripts/find-hermes-config.ps1`
- 写"M3 ctx 限制查询指南" 到 `docs/99-red-lines/M3-CTX-LIMITS.md`

**告诉我你需要哪个就行。**

---

## 🎯 立即可做(白名单内)的几个补充文档

我可以接着写:

1. `scripts/find-hermes-config.ps1` — 自动找 Hermes 配置的 PowerShell 脚本
2. `scripts/rollback-512k.ps1` — 改坏了一键还原
3. `docs/99-red-lines/M3-CTX-LIMITS.md` — 查 M3 模型 ctx 上限的方法
4. `docs/99-red-lines/HERMES-CONFIG-LOCATIONS.md` — Hermes 桌面应用常见配置文件位置 + 验证命令

需要哪个?全要?都不要?

---

*归档位置:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\docs\99-red-lines\SET-512K-CONTEXT.md`*
*白名单内 ✅,符合红线规则*