#!/bin/bash
# 快速迭代：只改 Dart 文件时用这个，不重建、不跑 port_build
#   pilipure hot          → 热重载（改 UI/逻辑，<1s）
#   pilipure restart      → 热重启（清了状态/改了全局变量时用，2-3s）
#   pilipure shot         → 截图到 /Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/shots/last.png
set -euo pipefail
PID_FILE=/Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/flutter_run.pid
LOG=$(ls -t /Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/logs/flutter_run*.log 2>/dev/null | head -1)

[ -f "$PID_FILE" ] || { echo "没有 ${PID_FILE}：先手动跑 flutter run"; exit 1; }
pid=$(cat "$PID_FILE")
kill -0 "$pid" 2>/dev/null || { echo "flutter run ($pid) 已退出，需要重新启动"; exit 1; }

n=$(wc -l < "$LOG" 2>/dev/null || echo 0)   # 只看这条命令之后的新日志

case "${1:-reload}" in
  restart) kill -USR2 "$pid"; echo "hot restart → $pid" ;;
  shot)    source /Users/y/toolchains/env.sh; mkdir -p /Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/shots; adb exec-out screencap -p > /Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/shots/last.png; echo "/Users/y/Downloads/DSH/Mac工作区/PiliPure/.cache/shots/last.png" ;;
  *)       kill -USR1 "$pid"; echo "hot reload → $pid" ;;
esac

# 等编译结果落进日志，把错误直接抛出来
for _ in $(seq 1 40); do
  sleep 0.25
  new_lines=$(tail -n +$((n + 1)) "$LOG" | grep -E "^Reloaded .* in |^Restarted application|^Error:|^Failed to" || true)
  if [ -n "$new_lines" ]; then
    echo "$new_lines" | tail -3
    exit 0
  fi
done
echo "(日志里没看到结果，直接看 $(ls -t /tmp/flutter_run*.log 2>/dev/null | head -1))"
