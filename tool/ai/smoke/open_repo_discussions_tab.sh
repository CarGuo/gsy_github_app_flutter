#!/usr/bin/env bash
# tool/ai/smoke/open_repo_discussions_tab.sh
#
# 从 GSY app 首页导航到指定仓库的「讨论」tab，打开第 N 条 discussion。
# 主要用来验证：
#   - [discussion_item.dart](../../../lib/page/discussion/widget/discussion_item.dart)
#     列表项渲染（GSYUserIconWidget 头像 / category emoji Unicode 化 / 锁定态 chip）
#   - [discussion_detail_page.dart](../../../lib/page/discussion/discussion_detail_page.dart)
#     详情页深色 header 卡片 + Markdown body 卡片 + skeleton_notice 提示
#
# 用法：
#   tool/ai/smoke/open_repo_discussions_tab.sh [keyword] [result_index] [discussion_index]
#     keyword           搜索关键词。默认 "BettaFish"，命中已开启 Discussions 的
#                       fixture 仓库 [666ghj/BettaFish](https://github.com/666ghj/BettaFish)。
#     result_index      打开搜索结果的第几条（0-based，默认 0）。
#     discussion_index  打开 Discussion 列表的第几条（0-based，默认 0）。
#
# 前置：
#   - adb 已连接设备（1080x2400，本轮实测 jfxgpjeul7lrpjkz Android 33 zh 8.1.0）
#   - GSY app 已装到设备（debug 或 release）
#
# 已知 fixture（写死用，禁止再新建仓库/造 discussion 来伪造证据）：
#   仓库：666ghj/BettaFish（微舆 / 多 Agent 舆情分析助手，Discussions 已开启，数据活跃）
#   Discussion #680  b612sheryl  category=General
#     - 中文标题 + 有 body（中文正文）+ 有 1 条评论
#     - 覆盖：GSYUserIconWidget 圆头像 / General emoji（💬）Unicode 化 / Markdown body 渲染
#   Discussion #686  XavierCheng215  category=Q&A（🙏）  用于对照另一种 category emoji
#
# 反例（不要退到这些做冒烟）：
#   - CarGuo/gsy_github_app_flutter：探针未启用 Discussions，Discussion tab 会不可见，
#     只能用来验证「tab 条件隐藏」而不能验证列表/详情渲染。
#
# 输出（按序号命名，便于翻查）：
#   /tmp/gsy_smoke_disc_01_home.png                起始首页
#   /tmp/gsy_smoke_disc_02_search_open.png         打开搜索页
#   /tmp/gsy_smoke_disc_03_search_result.png       输入关键词后的结果
#   /tmp/gsy_smoke_disc_04_repo_detail.png         进入仓库详情（动态 tab）
#   /tmp/gsy_smoke_disc_05_discussion_list.png     切到「讨论」tab（本次实现的新 tab）
#   /tmp/gsy_smoke_disc_06_discussion_detail.png   打开第 N 条 discussion 详情
#
# 出问题第一时间看这些截图定位是哪一步失手。
#
# ⚠️  坐标教训（2026-07-20 沉淀）：
#     曾经踩过坑：直接用 IDE 里显示的截图像素坐标（460x968 缩略图）去 adb shell input tap，
#     结果 tap 全部落偏，把「点讨论 tab」变成了「点搜索框 / 点错卡片跳错 issue」。
#     真机 input tap 必须用**设备物理坐标**（wm size 输出的 1080x2400），
#     不是任何 IDE / 编辑器渲染的图片坐标。改分辨率必须整表重新校准。

set -euo pipefail

KEYWORD="${1:-BettaFish}"
RESULT_INDEX="${2:-0}"
DISCUSSION_INDEX="${3:-0}"

if [[ -z "$KEYWORD" ]]; then
  echo "用法: $0 [keyword] [result_index] [discussion_index]" >&2
  echo "例:   $0                          # 默认命中 666ghj/BettaFish，打开第 0 条 discussion" >&2
  echo "例:   $0 BettaFish 0 1            # 打开第 1 条 discussion" >&2
  exit 2
fi

# 坐标（1080x2400，2026-07-21 现场重测）
# ⚠️ 2026-07-20 曾用 "1000 145"，实测在部分 Android 系统条高度下 y=145 会落到状态栏边缘、
#    导致 tap 被状态栏拦截，脚本"以为进了搜索页"但其实还在首页动态；下一步坐标又会误点
#    某条动态事件卡（如 "将 666ghj/BettaFish fork 到 xxx"），最终进错仓库拿不到 5-tab
#    fixture。校准依据：真机 screencap 中搜索图标中心约在图像 x=0.909*W, y=0.0775*H。
#    实测证据截图（本次校准依据的原始 screencap，改坐标前请先照它复核）：
#      tool/dbg/discussion_smoke/v3_post_review/home_search_icon_calibration_20260721.png
SEARCH_ICON="981 186"
SEARCH_INPUT="540 310"
RESULT_CARDS=(
  "540 750"    # 第 0 条
  "540 1080"   # 第 1 条
  "540 1410"   # 第 2 条
)
# repository_detail_page tab 顺序（启用 Discussions 时）：
#   详情(0) README(1) ISSUE(2) 讨论(3) 文件(4)
# 第 4 个 tab 中心在 x=754 y=367
# ⚠️ 禁用 Discussions 的仓库只有 4 个 tab（详情/README/ISSUE/文件），此坐标会落空，
#    脚本会误认为已切 tab 却其实还在 README。执行前应先确保 fixture 仓库
#    hasDiscussionsEnabled=true（默认参数已锁 666ghj/BettaFish 满足此约束）。
REPO_DISCUSSION_TAB="754 367"

# Discussion 列表卡片纵坐标步进约 490px，起点约 y=615
DISCUSSION_CARDS=(
  "540 615"    # 第 0 条
  "540 1105"   # 第 1 条
  "540 1595"   # 第 2 条
)

SHOT_DIR="/tmp"
PKG="com.shuyu.gsygithub.gsygithubappflutter"

shot() {
  local name="$1"
  local out="${SHOT_DIR}/gsy_smoke_disc_${name}.png"
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
# 收键盘（否则下一步 tap 会落在键盘上）
adb shell input keyevent 4   # KEYCODE_BACK
sleep 1
shot "03_search_result"

if (( RESULT_INDEX < 0 || RESULT_INDEX >= ${#RESULT_CARDS[@]} )); then
  echo "[smoke] result_index=$RESULT_INDEX 超出预定义卡片坐标（0..${#RESULT_CARDS[@]}-1）" >&2
  exit 3
fi
echo "[smoke] 打开第 $RESULT_INDEX 条搜索结果..."
adb shell input tap ${RESULT_CARDS[$RESULT_INDEX]}
sleep 8
shot "04_repo_detail"

echo "[smoke] 切到「讨论」tab..."
adb shell input tap $REPO_DISCUSSION_TAB
sleep 6
shot "05_discussion_list"

if (( DISCUSSION_INDEX < 0 || DISCUSSION_INDEX >= ${#DISCUSSION_CARDS[@]} )); then
  echo "[smoke] discussion_index=$DISCUSSION_INDEX 超出预定义卡片坐标（0..${#DISCUSSION_CARDS[@]}-1）" >&2
  exit 4
fi
echo "[smoke] 打开第 $DISCUSSION_INDEX 条 discussion..."
adb shell input tap ${DISCUSSION_CARDS[$DISCUSSION_INDEX]}
sleep 8
shot "06_discussion_detail"

echo ""
echo "[smoke] 完成。请把关键截图路径写进 AGENTS.md 三段式的『看运行』段。"
echo "[smoke] ls -la ${SHOT_DIR}/gsy_smoke_disc_*.png"
