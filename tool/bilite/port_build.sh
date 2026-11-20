#!/bin/bash
# Bash port of the repo's lib/scripts/build.ps1 + patch.ps1 (CI recipe).
set -euo pipefail

REPO="${REPO:-/Users/y/Downloads/DSH/Mac工作区/Bilite/src}"
CACHE="${CACHE:-/Users/y/Downloads/DSH/Mac工作区/Bilite/.cache}"
FLUTTER_ROOT="${FLUTTER_ROOT:-/Users/y/toolchains/flutter}"
PLATFORM="${1:-android}"

# 一键清理：删掉 .cache/ 全部内容，下一次打包自动重建（不动 src、不动 build 成品）
if [ "$PLATFORM" = "clean" ]; then
  mkdir -p "$CACHE"
  find "$CACHE" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  echo "已清空 ${CACHE}（源码与 build/ 成品未动）"
  exit 0
fi
PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export PATH="$FLUTTER_ROOT/bin:$PATH"
# pub.dev is slow on this network; use the official CN mirror for resolution speed.
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
FLUTTER="$FLUTTER_ROOT/bin/flutter"

cd "$REPO"

echo "=== [1/4] version + bilite_release.json ==="
VERSION_NAME=$(grep -oE '^version: *[0-9.]+' pubspec.yaml | head -1 | grep -oE '[0-9.]+')
VERSION_CODE=$(git rev-list --count HEAD)
COMMIT_HASH=$(git rev-parse HEAD)
if [ "$PLATFORM" = "android" ]; then
  VERSION_NAME="${VERSION_NAME}-${COMMIT_HASH:0:9}"
fi
python3 - "$VERSION_NAME" "$VERSION_CODE" <<'PY'
import sys, re, io
name, code = sys.argv[1], sys.argv[2]
p = 'pubspec.yaml'
src = open(p, encoding='utf-8').read()
src = re.sub(r'^version: *[0-9.]+.*$', f'version: {name}+{code}', src, count=1, flags=re.M)
open(p, 'w', encoding='utf-8').write(src)
PY
python3 - "$VERSION_NAME" "$VERSION_CODE" "$COMMIT_HASH" <<'PY'
import sys, json, time
name, code, h = sys.argv[1], int(sys.argv[2]), sys.argv[3]
json.dump({"pili.name": name, "pili.code": code, "pili.hash": h,
           "pili.time": int(time.time())},
          open('bilite_release.json', 'w', encoding='utf-8'), separators=(',', ':'))
PY
echo "version=$VERSION_NAME+$VERSION_CODE hash=$COMMIT_HASH"

echo "=== [2/4] flutter framework patches ($PLATFORM) ==="
ALL=(modal_barrier text_selection mouse_cursor image_anim layout_builder navigation_drawer
     popup_menu fab null_safety_for_selectable_region selectable_region editable_text
     text_field scroll_position scrollable scrollable_gesture draggable_scrollable_sheet
     scaffold text text_painter sliver refresh_indicator double_tap_gesture)
IOS_APP_PATCHES=()
MATERIAL=(modal_barrier_material navigation_drawer popup_menu fab text_field scaffold refresh_indicator tabs)
CUPERTINO=()
case "$PLATFORM" in
  android)
    ALL+=(bottom_sheet_android scroll_view navigator)
    MATERIAL+=(bottom_sheet_android) ;;
  ios)
    IOS_APP_PATCHES+=(lib/scripts/bottom_sheet_ios_piliplus.patch lib/scripts/geetest_ios.patch)
    ALL+=(scroll_view bottom_sheet_ios_flutter navigator)
    MATERIAL+=(bottom_sheet_ios_flutter_material)
    CUPERTINO+=(bottom_sheet_ios_flutter) ;;
  *) echo "unsupported platform $PLATFORM" >&2; exit 1 ;;
esac

if [ "${#IOS_APP_PATCHES[@]}" -gt 0 ]; then
  for p in "${IOS_APP_PATCHES[@]}"; do
    git apply "$p" && echo "app patch: $p"
  done
else
  # Android build: drop the ios-only app patches first (they edit shared Dart files
  # and would otherwise leak into the Android binary). No-op on a clean tree.
  IOS_TOUCHED="lib/pages/common/slide/common_slide_page.dart lib/common/widgets/scaffold/mini_scaffold.dart lib/pages/login/geetest/geetest_webview_dialog.dart"
  if ! git diff --quiet -- $IOS_TOUCHED; then
    git checkout -- $IOS_TOUCHED
    # 仓库已改名为 Bilite：checkout 回到 HEAD 会把旧包名带回来，这里同步改回新名
    perl -pi -e 's{package:(PiliPlus|PiliPure)/}{package:bilite/}g' $IOS_TOUCHED
    echo "reverted ios-only app patches (android build)"
  fi
  rm -f lib/pages/login/geetest/geetest_plugin.dart
fi

cd "$FLUTTER_ROOT"
git reset --hard HEAD >/dev/null
for name in "${ALL[@]}"; do
  git apply "$REPO/lib/scripts/$name.patch" && echo "flutter patch: $name"
done
git status --porcelain | wc -l | xargs echo "flutter dirty files:"

echo "=== [3/4] pub get + package patches ==="
cd "$REPO"
# material_ui is always re-patched; cupertino_ui is patched only for ios, so drop its
# possibly ios-patched copy too (otherwise an android build compiles stale patched code).
rm -rf "$PUB_CACHE"/hosted/*/material_ui-* "$PUB_CACHE"/hosted/*/cupertino_ui-* 2>/dev/null || true
"$FLUTTER" pub get

find "$REPO/lib/scripts" -name "*.patch" -exec perl -pi -e "s/\r\n/\n/" {} +
patch_pkg () {  # $1 = pkg glob, rest = patch ids from dir
  local glob="$1"; shift
  local dir="$1"; shift
  local pkgdir
  pkgdir=$(ls -d "$PUB_CACHE"/hosted/*/$glob 2>/dev/null | sort | tail -1)
  [ -n "$pkgdir" ] || { echo "package $glob not in pub cache" >&2; exit 1; }
  echo "patching $(basename "$pkgdir")"
  for name in "$@"; do
    ( cd "$pkgdir" && git apply "$REPO/lib/scripts/$dir/$name.patch" && echo "  pkg patch: $name" )
  done
}

patch_pkg 'material_ui-*' material "${MATERIAL[@]}"
if [ "${#CUPERTINO[@]}" -gt 0 ]; then
  patch_pkg 'cupertino_ui-*' cupertino "${CUPERTINO[@]}"
fi

echo "=== [4/4] ready ==="
