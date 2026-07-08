# tool/ai/smoke

GSY GitHub App 真机冒烟脚本。用于满足 [AGENTS.md 运行时冒烟验证章节](../../../AGENTS.md#运行时冒烟验证强制)
中"UI 渲染 / 文案 / 事件行"级别改动的最低证据要求（至少 1 张真机截图 + 无 crash 日志）。

## 为什么存在

adb tap 是坐标驱动，一旦重启 app、键盘弹起、布局变化就要重猜坐标。
以往每个 author 都在**独立摸索**同一段路径，浪费时间还产生"我做过了但下次得重来"
的一次性劳动。这些脚本把已经跑通的坐标序列沉淀成可复用步骤，出问题第一时间看截图定位。

## 前置条件

1. Android 设备通过 adb 连接（`adb devices` 能看到）。
2. GSY app 已经装到该设备（debug/release 均可）。
3. 设备物理分辨率 **1080x2400**（脚本用绝对坐标，不同分辨率要重新校准
   —— 校准方法见每个脚本顶部注释）。
4. 首次使用建议开着 `flutter run` 让 DTD 在线，可选补 `get_runtime_errors` 交叉验证。

## 脚本清单

| 脚本 | 作用 | 产物 |
|---|---|---|
| [`open_pr_timeline.sh`](./open_pr_timeline.sh) | 从首页导航到指定仓库 issue/PR 列表，打开第 N 条并滚 timeline | `/tmp/gsy_smoke_*.png` 序列 |
| [`relaunch_app.sh`](./relaunch_app.sh) | 强制回到 GSY 首页（清 back stack） | `/tmp/gsy_smoke_home.png` |
| [`open_home_dynamic.sh`](./open_home_dynamic.sh) | 首页动态 tab 冷启 → 下拉刷新 → 上滑分页 → 中段慢滚 → load more → 抓 logcat 分类计数（bash / macOS / Linux / WSL） | `/tmp/gsy_home_*.png` + logcat 计数摘要 |
| [`open_home_dynamic.ps1`](./open_home_dynamic.ps1) | 同 `open_home_dynamic.sh`，PowerShell 7 版本（Windows 首选） | `evidence/<yyyymmdd_hhmm>/*.png` + `logcat_full.txt` |

### Windows 优先用 `.ps1`

- Windows 上请直接 `pwsh -NoProfile -File tool\ai\smoke\open_home_dynamic.ps1 -Device <id>`，
  不要试图在 Git Bash / WSL 之外硬跑 `.sh`。
- 关键坑（写在这里免得下次再踩）：
  - PowerShell 5/7 的 `>` 重定向对二进制流会做 UTF-16 padding，
    直接 `adb logcat -d > file` 只能拿到几十字节。脚本改用
    `System.Diagnostics.Process` + `[IO.File]::WriteAllBytes` 拿 raw stdout。
  - `Set-Content -Encoding Byte` 在 PS7 已废弃，请勿改回。
  - 自定义函数不要用 `param([Parameter(...)] $Args)`，`$args` 是自动变量；
    也不要让函数不小心进 advanced 模式（会抢 `-p` / `-o` 等 CmdletBinding 前缀）。
- `.sh` 版仍留着给 macOS / Linux / WSL 用；两者步骤严格一致，参数命名不同（
  `.sh` 用环境变量 `SMOKE_KEEP_ATTACH=1`，`.ps1` 用 `-KeepAttach` switch）。

### evidence/ 目录约定

- 默认 evidence 落到 [`tool/ai/smoke/evidence/<yyyymmdd_hhmm>/`](./evidence/)，
  已通过根 `.gitignore` 里的 `tool/ai/smoke/evidence/` 忽略，不入 git。
- 建议按任务号建子目录（例：`evidence/c1/`、`evidence/d1_selftest/`），
  在完成汇报里把子目录**绝对路径**贴出来，reviewer 就能定位到当次证据。
- 手动指定目录：`.ps1` 传 `-OutDir`（有 `-Out` 别名），`.sh` 传第一个位置参数。

## 常见坐标（1080x2400，动态首页起点；2026-07-03 现场跑通）

| 步骤 | 元素 | 坐标 / 动作 |
|---|---|---|
| A | 右上搜索图标 | `tap 1000 145` |
| B | 搜索页输入框 | `tap 540 310` |
| C | 输入 + 回车 | `text "<kw>"` + `keyevent 66` |
| D | 搜索结果第 1 条卡片 | `tap 540 750` |
| E | 仓库详情第 3 个 tab (ISSUE) | `tap 675 340` |
| F | ISSUE 列表第 1 条 | `tap 540 951` |
| G | timeline 向下滚一屏 | `swipe 540 1800 540 500 500` |

**注意栈假设**：脚本第一步会 `am force-stop` 杀掉 app 进程再冷启动，
以避免"上一次的详情页栈还在，tap 落到错误页面"的坑
（这个坑 2026-07-03 真的踩过一次）。副作用：会杀 `flutter run` 的 debug 进程。
如果要保留 attach，export `SMOKE_KEEP_ATTACH=1` 后再跑 —— 但会失去清栈保证。

**换分辨率的校准法**：
1. `adb shell wm size` 确认物理分辨率
2. `adb exec-out screencap -p > /tmp/probe.png` 抓当前页
3. 目测元素中心在 **真实分辨率** 下的坐标（不是显示缩放后的坐标 —— 上次就栽在这个）
4. `adb shell input tap X Y` 直接验证，落错就调整
5. 把最终坐标写回上表并 commit

## 使用示例

```bash
# 把 app 送到 flutter/flutter 仓库 ISSUE 第 1 条并滚 timeline
tool/ai/smoke/open_pr_timeline.sh flutter 0

# 只做重启回首页
tool/ai/smoke/relaunch_app.sh
```

跑完后：
- `ls -la /tmp/gsy_smoke_*.png` 看每一步截图
- 把关键截图路径贴进[完成汇报三段式](../../../AGENTS.md#完成汇报三段式必填)的"看运行"段

## 不做什么

- 脚本**不做断言**（要不要过看的是截图和 `get_runtime_errors`）。
- 脚本**不 mock 数据**（要覆盖稀有事件分支请写单测 + JSON fixture）。
- 脚本**不依赖 flutter_driver**（本仓库未引入相关依赖）。
