# 开发日报目录

> 本目录按日期存放 PM Agent 生成的开发日报，由 cron `07970c65` 自动每日 00:00 触发。

## 📅 命名规范

- 文件名格式：`YYYY-MM-DD.md`
- 例如：`2026-06-29.md`、`2026-06-30.md`

## ⚠️ 可能的延迟

如果日报生成时间撞上 **pre-compaction memory flush 窗口**：

- 会话 `write` 工具被锁定，只能写 `memory/` 目录
- 日报全文会先存进 `memory/YYYY-MM-DD.md` §"今日开发日报全文"章节
- 用户 `/compact` 后 `write` 解锁，PM 自动补录到本目录
- **最大延迟：≤ 15 分钟**

详见 `docs/03-management/issue-tracker.md` ISSUE-012。

## 📊 日报内容板块

每份日报包含 5 大板块（即使空也要写，便于历史回溯）：

| 板块 | 必填 | 说明 |
|---|---|---|
| 📊 进度概览 | ✅ | Phase / 里程碑 / 问题统计 / Git 提交数 / 测试覆盖 |
| ✅ 今日完成 | ✅ | 💻代码 / 📋需求 / 📐规范 / 🏗️架构 / 👥团队 |
| 🔍 关键里程碑 | ✅ | 当日重大事件时间线 |
| 📊 Git 提交记录 | ✅ | 今日 git log 前 20 条 |
| 🔍 问题与解决 | ✅ | 当日踩到的坑 + 解决过程 |
| 📋 Open TODOs | ✅ | 高/中/低三优先级清单 |
| 📈 统计 | ✅ | commit/文档/问题/覆盖/代码行数 |
| 🎯 明日计划 | ✅ | 4 项内，可执行 |
| 📎 附录 | △ | 重大 commit 详情 |

## 🔗 相关文档

- `docs/03-management/issue-tracker.md` — 问题管理表
- `docs/03-management/event-log.md` — 故障事件日志
- `docs/03-management/weekly-reports/` — 周报（按周聚合日报）
- `agents/pm/SOUL.md` — PM 职业规则

---

*最后更新：2026-06-29 22:20*
