#!/usr/bin/env bash
# tool/ai/smoke/open_pr_timeline.sh
#
# 从 GSY app 首页导航到指定仓库的 ISSUE 列表，打开第 N 条并滚一次 timeline。
# 主要用来验证 [issue_timeline_item.dart](../../../lib/page/issue/widget/issue_timeline_item.dart)
# 的事件行渲染是否正常。
#
# 用法：
#   tool/ai/smoke/open_pr_timeline.sh [keyword] [index]
#     keyword   搜索关键词。不传时默认 "gsy_github_app_flutter"，会命中
#               [CarGuo/gsy_github_app_flutter](https://github.com/CarGuo/gsy_github_app_flutter)
#               作为固定 fixture 仓库使用。
#     index     打开搜索结果的第几条（0-based，默认 0）
#
# 前置：
#   - adb 已连接设备（1080x2400）
#   - GSY app 已装到设备（debug 或 release）
#
# 已知 fixture PR（写死用，不允许再随机大海捞针找 PR）：
#   仓库：CarGuo/gsy_github_app_flutter
#   PR：#938  Copilot Android APK 优化
#     - reviewed / state=commented / body_len=788（覆盖 F1 本质修复的正向路径）
#     - ready_for_review / review_requested / merged / closed / assigned 等新事件全覆盖
#   注意：如需其它 PR 覆盖 approved/changes_requested body，请优先在 CarGuo 名下的 PR 里搜集，
#   而不是新建 fixture 仓库或造 PR（GSY 是只读客户端，写 PR 不是它的定位）。
#
# 输出（按序号命名，便于翻查）：
#   /tmp/gsy_smoke_01_home.png       起始首页
#   /tmp/gsy_smoke_02_search_open.png 打开搜索页
#   /tmp/gsy_smoke_03_search_result.png 输入关键词后的结果
#   /tmp/gsy_smoke_04_repo_detail.png 进入仓库详情（动态 tab）
#   /tmp/gsy_smoke_05_issue_list.png  切到 ISSUE tab
#   /tmp/gsy_smoke_06_issue_detail_top.png 打开第 N 条 issue/PR
#   /tmp/gsy_smoke_07_issue_detail_scrolled.png 向下滚一屏后的 timeline
#
# 出问题第一时间看这些截图定位是哪一步失手。

set -euo pipefail

KEYWORD="${1:-gsy_github_app_flutter}"
INDEX="${2:-0}"

if [[ -z "$KEYWORD" ]]; then
  echo "用法: $0 [keyword] [index]" >&2
  echo "例:   $0                          # 默认命中 CarGuo/gsy_github_app_flutter，打开第一条（#938）" >&2
  echo "例:   $0 GSYVideoPlayer 0         # 换其它 fixture 仓库" >&2
  exit 2
fi

# 坐标（1080x2400），改分辨率请重新校准并同步 README
# 这些坐标是 2026-07-03 现场跑通过的，别改
SEARCH_ICON="1000 145"
SEARCH_INPUT="540 310"
RESULT_CARDS=(
  "540 750"    # 第 0 条
  "540 1080"   # 第 1 条
  "540 1410"   # 第 2 条
)
REPO_ISSUE_TAB="675 340"
ISSUE_CARD_FIRST="540 951"

SHOT_DIR="/tmp"
PKG="com.shuyu.gsygithub.gsygithubappflutter"

shot() {
  local name="$1"
  local out="${SHOT_DIR}/gsy_smoke_${name}.png"
  adb exec-out screencap -p > "$out"
  echo "[smoke] $out"
}

# 每次都从首页起，保证坐标可复现
"$(dirname "$0")/relaunch_app.sh" >/dev/null
shot "01_home"

echo "[smoke] 打开搜索页..."
adb shell input tap $SEARCH_ICON
sleep 2
shot "02_search_open"

echo "[smoke] 输入关键词 '$KEYWORD' 并回车..."
adb shell input tap $SEARCH_INPUT
sleep 1
adb shell input text "$KEYWORD"
sleep 1
adb shell input keyevent 66  # KEYCODE_ENTER
sleep 5
shot "03_search_result"

if (( INDEX < 0 || INDEX >= ${#RESULT_CARDS[@]} )); then
  echo "[smoke] index=$INDEX 超出预定义卡片坐标（0..${#RESULT_CARDS[@]}-1）" >&2
  exit 3
fi
echo "[smoke] 打开第 $INDEX 条搜索结果..."
adb shell input tap ${RESULT_CARDS[$INDEX]}
sleep 6
shot "04_repo_detail"

echo "[smoke] 切到 ISSUE tab..."
adb shell input tap $REPO_ISSUE_TAB
sleep 4
shot "05_issue_list"

echo "[smoke] 打开 ISSUE 列表第 1 条..."
adb shell input tap $ISSUE_CARD_FIRST
sleep 6
shot "06_issue_detail_top"

echo "[smoke] 向下滑动一屏（滚 timeline）..."
adb shell input swipe 540 1800 540 500 500
sleep 2
shot "07_issue_detail_scrolled"

echo ""
echo "[smoke] 完成。请把关键截图路径写进 AGENTS.md 三段式的『看运行』段。"
echo "[smoke] ls -la ${SHOT_DIR}/gsy_smoke_*.png"
