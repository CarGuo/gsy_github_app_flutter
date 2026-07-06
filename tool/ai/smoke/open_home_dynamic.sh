#!/usr/bin/env bash
# tool/ai/smoke/open_home_dynamic.sh
#
# 让 GSY app 回到"首页动态 tab"，走完 receive feed 的下拉刷新 + 上拉加载 + 慢滚
# 一整轮，把 5 张证据截图存到 /tmp/。主要用来验证 [dynamic_page.dart](../../../lib/page/dynamic/dynamic_page.dart)
# 与 [event_utils.dart](../../../lib/common/utils/event_utils.dart) 里的事件识别在真机上是否稳定。
#
# 覆盖的事件族（fixture 账号 CarSmallGuo received feed 前 40 条常见）：
#   - PushEvent（带 head short SHA）
#   - IssuesEvent opened（issue #n + title）
#   - ForkEvent（src → dst）
#   - WatchEvent started（关注了 repo）
#
# 未覆盖但对同一段 switch 分支等价的事件：
#   - DiscussionEvent / DiscussionCommentEvent / SponsorshipEvent /
#     PullRequestReviewThreadEvent
#     这四类在多数 received feed 里出现频率极低，单元测试已覆盖，见
#     [docs/04-quality/smoke-matrix.md](../../../docs/04-quality/smoke-matrix.md) 的
#     "首页动态 / 事件识别" 段落。
#
# 用法：
#   tool/ai/smoke/open_home_dynamic.sh
#
# 前置：
#   - adb 已连接设备（默认 1080x2400 竖屏；若为横屏，脚本会强制切竖屏）
#   - GSY app 已装到设备（debug 或 release）
#   - 已登录任意账号
#
# 输出（按序号命名，便于翻查）：
#   /tmp/gsy_home_01_launch.png       启动后首页动态 tab
#   /tmp/gsy_home_02_refreshed.png    下拉刷新后
#   /tmp/gsy_home_03_scrolled_deep.png 连续上滑 8 次后（大约到 1-2 天前）
#   /tmp/gsy_home_04_middle.png       慢滚回中段（PushEvent + Watch + Fork 混杂）
#   /tmp/gsy_home_05_after_loadmore.png 触发第 2 页加载后
#
# 出问题第一时间看这些截图定位是哪一步失手。

set -euo pipefail

PKG="com.shuyu.gsygithub.gsygithubappflutter"

echo "[1/6] 强制竖屏 + 冷启动 $PKG"
adb shell settings put system accelerometer_rotation 0 >/dev/null
adb shell settings put system user_rotation 0 >/dev/null
adb shell am force-stop "$PKG"
sleep 1
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 10
adb exec-out screencap -p > /tmp/gsy_home_01_launch.png

echo "[2/6] 下拉刷新"
adb shell input swipe 540 400 540 1400 400
sleep 4
adb exec-out screencap -p > /tmp/gsy_home_02_refreshed.png

echo "[3/6] 连续上滑 8 次触发分页 + 深入 1-2 天前"
for i in 1 2 3 4 5 6 7 8; do
  adb shell input swipe 540 1900 540 400 250
  sleep 0.5
done
sleep 3
adb exec-out screencap -p > /tmp/gsy_home_03_scrolled_deep.png

echo "[4/6] 慢滚回中段（PushEvent + Watch + Fork 混杂）"
adb shell input swipe 540 800 540 1500 400
sleep 1
adb shell input swipe 540 800 540 1500 400
sleep 1
adb exec-out screencap -p > /tmp/gsy_home_04_middle.png

echo "[5/6] 触发第 2 页 load more（再往下拉几次）"
adb shell input swipe 540 1900 540 200 300
sleep 3
adb shell input swipe 540 1900 540 200 300
sleep 3
adb exec-out screencap -p > /tmp/gsy_home_05_after_loadmore.png

echo "[6/6] 抓 flutter 层 EXCEPTION（应为空）"
adb logcat -d -s flutter:E flutter:F 2>&1 | head -n 30 || true

echo
echo "证据截图："
ls -1 /tmp/gsy_home_0*.png
