# 📦 发布归档（Release Archive）

> **目的**：release/ 目录下的 APK 都是构建产物，`.gitignore` 排除了 `release/v*/`，所以**不进 git**。
> 这里归档每个版本的 CHANGELOG、SHA1、回滚说明，方便开发者挑选版本。

---

## 📂 版本索引

| 版本 | 日期 | APK | CHANGELOG | 状态 |
|---|---|---|---|---|
| **v0.2.0+2** | 2026-07-10 | `release/v0.2.0+2/ai-travel-ledger-v0.2.0.apk` | ⏳ 待补 (V1.3) | 旧版本 |
| **v1.0.0-local** | 2026-07-11 | `release/v1.0.0-local/ai-travel-ledger-v1.0.0-local.apk` | ⏳ 待补 (V1.3) | V1.0 本地 GA |
| **v1.2-step2-local** | 2026-07-12 22:30 | `release/v1.2-step2-local/ai-travel-ledger-v1.2-step2.apk` | [`v1.2-step2-local/CHANGELOG.md`](v1.2-step2-local/CHANGELOG.md) | ✅ 中间产物 |
| **v1.2-step3-local** | 2026-07-12 22:40 | `release/v1.2-step3-local/ai-travel-ledger-v1.2-step3.apk` | [`v1.2-step3-local/CHANGELOG.md`](v1.2-step3-local/CHANGELOG.md) | ✅ 中间产物 |
| **v1.2-step4-local** | 2026-07-13 00:06 | `release/v1.2-step4-local/ai-travel-ledger-v1.2-step4.apk` | [`v1.2-step4-local/CHANGELOG.md`](v1.2-step4-local/CHANGELOG.md) | ✅ 中间产物 |
| **v1.2.0+0-cloud** | 2026-07-14 21:15 | `release/v1.2.0+0-cloud/ai-travel-ledger-v1.2.0+0-cloud.apk` | `release/RELEASE-NOTES-v1.2-cloud.md` (待补) | ✅ **V1.2 云端 GA** |
| **v1.2.0+0-cloud-milestone** | 2026-07-14 22:03 | `release/v1.2.0+0-cloud-milestone/ai-travel-ledger-v1.2.0+0-cloud-milestone.apk` | [`release/RELEASE-NOTES-v1.2-cloud-milestone.md`](../../release/RELEASE-NOTES-v1.2-cloud-milestone.md) | 🏆 **V1.2 云端里程碑** |

---

## 🎯 选版本指引

### 推荐：v1.2.0+0-cloud-milestone ⭐

最新 + 最完整，含全部 V1.0 + V1.1 + V1.2 功能 + 云端同步 + 附件拍照上传。

> GitHub Release: https://github.com/jiaqingshao/ai-travel-ledger/releases/tag/milestone-v1.2-cloud

### V1.2 中间产物（仅用于演示 / 回归）

如果想看 V1.2 附件功能**单步**的实现效果：
- `v1.2-step2-local`: UI 集成（拍照/选图/上传/预览，但无徽章）
- `v1.2-step3-local`: + 列表徽章
- `v1.2-step4-local`: + 行程汇总页附件总数

### 旧版（不推荐）

- `v0.2.0+2`: 测试期版本，已被 v1.0.0 取代
- `v1.0.0-local`: V1.0 第一个本地 GA，无云同步

---

## 🔄 版本演进时间线

```text
2026-07-04  v1.0.0   ─── 首次 GA（本地模式，无云同步）
2026-07-10  v0.2.0+2 ─── V1.1 beta（修复分摊规则可编辑）
2026-07-11  v1.0.0-local ─── 本地 GA（应用名本地化 + Supabase 可选化）
2026-07-12  v1.2-step1 ─── (数据模型 + Storage, 无独立 APK)
2026-07-12  v1.2-step2-local ─── UI 集成
2026-07-12  v1.2-step3-local ─── + 列表徽章
2026-07-13  v1.2-step4-local ─── + 行程汇总附件总数
2026-07-14  v1.2.0+0-cloud ─── V1.2 云端 GA
2026-07-14  v1.2.0+0-cloud-milestone ─── 🏆 云端里程碑（首个 GA + GitHub Release）
```

---

## 📋 验证

每个 release 都通过：

- ✅ `flutter analyze` 0 errors
- ✅ `flutter test` 全绿（不同版本数字不同，CHANGELOG 已标）
- ✅ 真机回归测试（v0.2.0+2 / v1.0.0-local / V1.2 系列）
- ✅ SHA1 校验（写在 CHANGELOG 头部）

---

## 🔙 回滚指引

如果当前版本有问题，按下表回滚：

| 当前 | 回滚到 | 命令 |
|---|---|---|
| `v1.2.0+0-cloud-milestone` | `v1.2.0+0-cloud` | 装 `v1.2.0+0-cloud.apk` 覆盖安装（签名相同） |
| `v1.2.0+0-cloud` | `v1.0.0-local` | 先卸载（签名不同）再装 `v1.0.0-local.apk` |
| `v1.0.0-local` | `v0.2.0+2` | 先卸载再装 `v0.2.0.apk` |

> ⚠️ 跨版本回滚需要先卸载再装（签名可能不同）。同一版本内的次级构建可以覆盖安装。

---

## 🚧 待补内容（V1.3 候选）

- ⏳ `v0.2.0+2` CHANGELOG
- ⏳ `v1.0.0-local` CHANGELOG（功能级别，不含版本步骤）
- ⏳ `v1.2.0+0-cloud` CHANGELOG（合并 step 1-4 + GA）
- ⏳ 把 `release/RELEASE-NOTES-v1.2-cloud-milestone.md` 移到本目录

---

*最后更新: 2026-07-15（PR-5a 完成）*
