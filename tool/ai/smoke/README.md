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

## 装机命令（重要）

**禁止使用 `flutter install`。** 该命令内部走 `adb uninstall <pkg>` + `adb install`，
会顺手把 `/data/data/com.shuyu.github/` 下的全部 SharedPreferences 抹掉，
`TOKEN_KEY` 一并没了 —— 设备上等同强制登出，reviewer 无法直接复核 fixture。

正确姿势（本仓库已固化到 [AGENTS.md 禁止行为](../../../AGENTS.md#禁止行为)）：

```bash
# 1. 构建 release APK（首选 arm64，跟 CarGuo 主设备一致）
flutter build apk --release --target-platform=android-arm64 --no-shrink

# 2. 用 adb install -r 覆盖安装，保留 app data
adb install -r build/app/outputs/flutter-apk/app-release.apk
#              ^^ 关键：-r = reinstall, 保留 /data/data/<pkg>/
```

如果**必须**重装（例如包名或签名变了），先手动导出 token 再装：

```bash
# 装机前：把 token 从设备上导出（root/debuggable 才有 shared_prefs 可读权限）
adb exec-out run-as com.shuyu.github cat shared_prefs/FlutterSharedPreferences.xml \
  | grep -oP 'flutter\.token"[^<]+' > /tmp/gsy_token_backup.xml

# 装机
adb install -r <apk>

# 装完：如果 token 丢了，从登录页新加的「Token 登录」入口粘回来（详见
# lib/page/login/login_page.dart）
```

真机上没登录时，可以直接在登录页填入 PAT 走 [TokenLoginAction](../../../lib/redux/login_redux.dart) 恢复。
避免走 OAuth webview 那一整套 client_id / client_secret 依赖，
特别适合刚被 `flutter install` 坑过、手上只有一个 fine-grained token 的场景。

## 脚本清单

| 脚本 | 作用 | 产物 |
|---|---|---|
| [`open_pr_timeline.sh`](./open_pr_timeline.sh) | 从首页导航到指定仓库 issue/PR 列表，打开第 N 条并滚 timeline | `/tmp/gsy_smoke_*.png` 序列 |
| [`open_repo_discussions_tab.sh`](./open_repo_discussions_tab.sh) | 从首页导航到指定仓库「讨论」tab，打开第 N 条 discussion（验证 [discussion_item.dart](../../../lib/page/discussion/widget/discussion_item.dart) / [discussion_detail_page.dart](../../../lib/page/discussion/discussion_detail_page.dart)） | `/tmp/gsy_smoke_disc_*.png` 序列 |
| [`relaunch_app.sh`](./relaunch_app.sh) | 强制回到 GSY 首页（清 back stack） | `/tmp/gsy_smoke_home.png` |
| [`open_home_dynamic.sh`](./open_home_dynamic.sh) | 首页动态 tab 冷启 → 下拉刷新 → 上滑分页 → 中段慢滚 → load more → 抓 logcat 分类计数（bash / macOS / Linux / WSL） | `/tmp/gsy_home_*.png` + logcat 计数摘要 |
| [`open_home_dynamic.ps1`](./open_home_dynamic.ps1) | 同 `open_home_dynamic.sh`，PowerShell 7 版本（Windows 首选） | `evidence/<yyyymmdd_hhmm>/*.png` + `logcat_full.txt` |
| [`open_my_repositories.ps1`](./open_my_repositories.ps1) | 从首页进入“我的”及认证 owner 仓库列表；可用 `-ExpectedFirstRepository <name>` 继续验证私库动态/详情/ISSUE/文件（issue #943） | `evidence/<yyyymmdd_hhmm>_issue_943/*.png` + UI XML + app PID logcat |
| [`probe_device_rotation.ps1`](./probe_device_rotation.ps1) | Discussions §3.1 pt.4 前置：中立诊断真机旋转 override（`settings get/put accelerometer_rotation` + `user_rotation` + `wm user-rotation` + `dumpsys display` 摘要）；默认只读，`-Apply` 才写 | `evidence/<yyyymmdd_hhmm>/rotation_probe_report.txt` + `rotation_probe_raw.json` + `dumpsys_display.txt` |

### probe_device_rotation.ps1（真机坐标 tap 前置）

背景：真机验收 pt.1/2/4/5 都被"tap 落错"卡住，根因是自动旋转 / 旋转 override
经常不在 `user_rotation=0` 的干净状态。roadmap [§3.1 pt.4](../../../docs/00-overview/roadmap.md)
列出的 4 条排查思路一直没沉淀成脚本，每次接手都要现拼命令。

这个脚本把 pt.4 4 条思路翻译成 4 步中立诊断：

| 脚本 step | 对应 pt.4 排查思路 | 行为 |
|---|---|---|
| step1 baseline | 补充上下文（wm size / density / dumpsys display / hwrotation prop） | 只读 |
| step2 settings probe | 思路 1：`settings get/put accelerometer_rotation + user_rotation` | 只读；`-Apply` 才写 0 |
| step3 wm user-rotation probe | 思路 2：`wm user-rotation lock 0`（部分厂商 ROM 才支持） | 只读探测；`-Apply` 才 lock |
| step4 summary | 思路 3：`adb reboot` 兜底 → `-OfferReboot` 只提示，不代跑；思路 4：flutter_driver 依赖需 PR 描述里显式提出 | 生成 verdict 建议 |

用法（Windows 首选）：

```pwsh
# 只读诊断（推荐先跑一次，把 baseline 落到 evidence）
pwsh -NoProfile -File tool\ai\smoke\probe_device_rotation.ps1 -Device jfxgpjeul7lrpjkz

# 排查完确认要修才 -Apply（会写 accelerometer_rotation=0 + user_rotation=0；
# ROM 支持时再 wm user-rotation lock 0）
pwsh -NoProfile -File tool\ai\smoke\probe_device_rotation.ps1 -Apply -Screenshot -Device jfxgpjeul7lrpjkz
```

产物落 `evidence/<yyyymmdd_hhmm>/`，`.gitignore` 已忽略：

- `rotation_probe_report.txt`：人类可读逐步报告 + verdict
- `rotation_probe_raw.json`：结构化字段（reviewer / 后续脚本可复用）
- `dumpsys_display.txt` / `settings_dump.txt` / `wm_size.txt` / `wm_density.txt`：原始快照
- `screencap_before.png` / `screencap_after.png`（`-Screenshot` 才生成）

**与 AGENTS.md 允许清单的关系**：本脚本不做 GitHub 意义上的 mutation。
`settings put` / `wm user-rotation lock` 属于**设备侧诊断修改**，只在显式 `-Apply`
时下发；author 在完成汇报里需要注明是否 `-Apply` 过。

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
| E' | 仓库详情第 4 个 tab (讨论，仅在 Discussions 启用时可见) | `tap 754 367` |
| F | ISSUE 列表第 1 条 | `tap 540 951` |
| F' | Discussion 列表第 1 条 | `tap 540 615` |
| G | timeline 向下滚一屏 | `swipe 540 1800 540 500 500` |

**注意栈假设**：脚本第一步会 `am force-stop` 杀掉 app 进程再冷启动，
以避免"上一次的详情页栈还在，tap 落到错误页面"的坑
（这个坑 2026-07-03 真的踩过一次）。副作用：会杀 `flutter run` 的 debug 进程。
如果要保留 attach，export `SMOKE_KEEP_ATTACH=1` 后再跑 —— 但会失去清栈保证。

**换分辨率的校准法**：
1. `adb shell wm size` 确认物理分辨率
2. `adb exec-out screencap -p > /tmp/probe.png` 抓当前页
3. 目测元素中心在 **真实分辨率** 下的坐标（不是显示缩放后的坐标 —— 上次就栽在这个）。
   **具体来说**：IDE / 编辑器打开 PNG 时通常会缩到 ~460×968 显示；
   在这个缩略图上量出的像素坐标**不能直接**塞给 `adb shell input tap`。
   必须按 `设备分辨率 / 缩略图分辨率` 的比例乘回去
   （2026-07-20 又踩过一次：本仓库 1080×2400 vs IDE 缩略 460×968，
    比例 ≈ ×2.35 / ×2.48，忘乘会点到搜索框或点错卡片跳错 issue）。
4. `adb shell input tap X Y` 直接验证，落错就调整
5. 把最终坐标写回上表并 commit

## 使用示例

```bash
# 把 app 送到 flutter/flutter 仓库 ISSUE 第 1 条并滚 timeline
tool/ai/smoke/open_pr_timeline.sh flutter 0

# 把 app 送到 666ghj/BettaFish 仓库「讨论」tab 并打开第 0 条 discussion
tool/ai/smoke/open_repo_discussions_tab.sh

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
