#!/usr/bin/env bash
# tool/ai/smoke/relaunch_app.sh
# 强制把 GSY app 拉到前台并回到动态首页。
# 用途：每次冒烟测试起点都保证 UI 状态干净，避免上一次遗留的详情栈影响 tap。
#
# 分辨率假设：1080x2400。换分辨率请先跑一次 screencap 校准坐标。
#
# 输出：/tmp/gsy_smoke_home.png

set -euo pipefail

PKG="com.shuyu.gsygithub.gsygithubappflutter"
OUT="/tmp/gsy_smoke_home.png"

if ! adb devices | grep -qE "\bdevice\b"; then
  echo "[relaunch] adb 未检测到设备，先跑 'adb devices'" >&2
  exit 1
fi

echo "[relaunch] 强杀 app 进程以清空栈..."
if [ "${SMOKE_KEEP_ATTACH:-0}" = "1" ]; then
  echo "[relaunch] SMOKE_KEEP_ATTACH=1，保留 flutter run attach，不 force-stop"
else
  adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
  sleep 1
fi
echo "[relaunch] 回桌面后冷启动 app..."
adb shell input keyevent KEYCODE_HOME >/dev/null || true
sleep 1
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 10

adb exec-out screencap -p > "$OUT"
echo "[relaunch] 截图: $OUT"
