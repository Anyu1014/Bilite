# PiliPure 双端源码移植与构建（macOS / 本机）

上游：https://github.com/bggRGjQaUbCoE/PiliPlus （Flutter 3.47.9 客户端，B 站第三方客户端）
本目录产物：Android APK（3 个 ABI）+ iOS 未上架 IPA（ad-hoc 签名），均在 `out/`。

本机版本已按需求**改名为 PiliPure**并**替换应用图标**（粉色 PiliPure 电视 logo），双端一起生效。

## 目录

```
PiliPlus/
├── src/                     # upstream 源码 (git clone --depth 1, HEAD 265f879) + 本地改名/图标改动
├── port_build.sh            # CI 的 lib/scripts/patch.ps1 + build.ps1 的 bash 移植
├── make_icons.py            # 由一张 2048x2048 原图生成 Android/iOS 全部图标尺寸
├── assets_src/              # 图标源图（pilipure_icon_source.jpg）
├── out/                     # 最终产物
│   ├── PiliPure-android-2.2.0-arm64-v8a.apk        (25M)
│   ├── PiliPure-android-2.2.0-armeabi-v7a.apk      (25M)
│   ├── PiliPure-android-2.2.0-x86_64.apk           (25M)
│   └── PiliPure_ios_2.2.0+1.ipa                    (25M, ad-hoc 签名)
└── preview/                 # 安卓模拟器运行截图
```

## 改名 / 换图标改了什么

| 位置 | 改动 |
| --- | --- |
| `lib/common/constants.dart` | `Constants.appName = 'PiliPure'`（"关于"页、分享文案等） |
| `android/app/src/main/res/values/string.xml` | `app_name` → PiliPure |
| `android/app/src/debug/res/values/string.xml` | debug 名 → PiliPure debug |
| `android/app/src/main/AndroidManifest.xml` | 两处 `intent-filter android:label` → PiliPure |
| `android/app/build.gradle.kts` | dev flavor 的 `resValue app_name` → PiliPure dev |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` / `CFBundleName` → PiliPure |
| Android 图标 | `mipmap-{mdpi..xxxhdpi}/ic_launcher.png` 48/72/96/144/192 + `ic_launcher_foreground.png`（adaptive，108dp 画布内图占 72dp）+ `mipmap-anydpi-v26/ic_launcher.xml` 改为纯前景/背景两层，`colors.xml` 背景 `#FDA3BF` |
| iOS 图标 | `Assets.xcassets/AppIcon.appiconset` 全部 25 个 PNG |
| 应用内 logo | `assets/images/logo/{logo.png,logo_2.png,desktop/logo_large.png}` 512×512 |

**故意没改**（改了会破坏升级/构建）：`pubspec.yaml` 的 Dart 包名 `PiliPlus`（牵连全部 `package:PiliPlus/` import）、
`applicationId com.example.piliplus`、上游源码仓库链接、webview 的 JS 桥名 `window.PiliPlus`。

## 工具链（/Users/y/toolchains）

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| Flutter | 3.47.9 (Dart 3.13.7, rev c197ca5199) | `git clone -b 3.47.9` 到 `/Users/y/toolchains/flutter`，**保留 .git**，因为上游补丁需要 `git apply` |
| JDK | 21.0.12.1 (jdk-21) | |
| Android SDK | platforms 35/36/37.0、build-tools 37.0.0、ndk 28.2.13676358 (r28c)、cmake 3.22.1 | NDK/CMake 由 AGP 构建时自动安装 |
| Xcode | 27.0 (27A5252f) | Xcode-beta，经 `DEVELOPER_DIR` 指定 |
| CocoaPods | 1.17.0 | `gem install --user-install`，可执行文件在 `~/.gem/ruby/2.6.0/bin/pod`（不在默认 PATH） |

## 构建方式

上游 CI 依赖 PowerShell 脚本；本机用 `port_build.sh` 等价复刻（步骤与 `lib/scripts/patch.ps1`、`build.ps1` 一致）：

```bash
cd PiliPlus/src
source /Users/y/toolchains/env.sh

# Android
bash ../port_build.sh android
flutter build apk --release --split-per-abi --dart-define-from-file=pili_release.json --no-pub

# iOS（必须先打 iOS 补丁集，Flutter 仓库会被 git reset --hard 重置）
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
bash ../port_build.sh ios
flutter build ios --release --no-codesign --dart-define-from-file=pili_release.json --no-pub
cd dist && rm -rf Payload *.ipa && ln -s ../build/ios/iphoneos Payload
find Payload/Runner.app/Frameworks -type d -name "*.framework" \
  -exec codesign --force --sign - --preserve-metadata=identifier,entitlements {} \;
codesign --force --sign - --preserve-metadata=identifier,entitlements Payload/Runner.app
zip -rq9 PiliPure_ios_2.2.0+1.ipa Payload
```

脚本做了四件事：

1. 改写 `pubspec.yaml` 版本并生成 `pili_release.json`（`pili.name/code/hash/time`，供 `lib/build_config.dart` 读取）。
2. 在 Flutter SDK 里 `git reset --hard` 后 `git apply` 框架补丁（24 个：`modal_barrier` … `double_tap_gesture`，android 追加 `bottom_sheet_android/scroll_view/navigator`，ios 追加 `bottom_sheet_ios_flutter/scroll_view/navigator`）。
3. 删除 pub cache 里的 `material_ui-*` **和 `cupertino_ui-*`** 后 `flutter pub get`（走 `pub.flutter-io.cn` 镜像），再按平台打补丁：`material_ui-1.9.0` 8–9 个（`modal_barrier_material` … `tabs`，android 追加 `bottom_sheet_android`，ios 追加 `bottom_sheet_ios_flutter_material`），ios 另对 `cupertino_ui-1.1.5` 打 `bottom_sheet_ios_flutter`。
   - 必须同时删 `cupertino_ui-*`：它只有 iOS 补丁，若残留 iOS 版副本，Android 编译会因 `popGestureEnabled_` / `gesturePop` 不存在而失败。
4. ios 平台额外对 app 仓库打 `lib/scripts/bottom_sheet_ios_piliplus.patch`、`lib/scripts/geetest_ios.patch`（改的是共享 Dart 文件，**转去编 Android 前要 `git checkout` 回滚这几处**：`lib/pages/common/slide/common_slide_page.dart`、`lib/common/widgets/scaffold/mini_scaffold.dart`、`lib/pages/login/geetest/geetest_webview_dialog.dart`、`pubspec.yaml`，并删除 `lib/pages/login/geetest/geetest_plugin.dart`）。

## 产物验证

- **Android**：模拟器 `piliplus`（android-35 google_apis arm64-v8a, Pixel 7, 4G userdata）安装启动成功，
  `versionName=2.2.0-265f879fa`, `versionCode=1`, `targetSdk=37`；
  桌面/应用列表显示 **PiliPure** 与新图标（`preview/pilipure_launcher.png`），"关于"页显示新 logo、PiliPure 与版本号（`preview/pilipure_about.png`），
  首页推荐流可正常拉取真实稿件（`preview/pilipure_app_01.png`）。
- **iOS**：`build/ios/iphoneos/Runner.app (67.6MB)`，Frameworks 与主二进制均为 ad-hoc 签名；
  IPA 内 `CFBundleDisplayName/CFBundleName = PiliPure`、`CFBundleShortVersionString 2.2.0`、AppIcon 已随包编译。
  未做真机安装验证（无开发者证书 / 未越狱），属"可自签安装"级别。

## 本地界面改动（第 5 轮，仅改源码，未打包）

| 需求 | 落地位置 |
| --- | --- |
| 关于页「当前版本」显示 1.0 | `lib/pages/about/view.dart`：`static const currentVersion = '1.0';`（不再取 `BuildConfig.versionName+code`） |
| 关于页加作者 Anyu（在版本之上） | 同文件，在「当前版本」`ListTile` 前插入 `ListTile(leading: Icons.person_outline, title: '作者', trailing: 'Anyu')` |
| 关于页删除 Source Code 行 | 同文件，删掉带 `Constants.sourceCodeUrl` 的那条 `ListTile`（Build Time/Commit Hash、问题反馈保留） |
| 关于页顶部图标改圆角 | `assets/images/logo/logo.png` 换成 1024×1024 圆角遮罩版（`make_icons.py` 同源图生成），`logo_2.png` 同步 256×256 |
| 外观设置「悬浮底栏」默认开 | `lib/pages/setting/models/style_settings.dart` `defaultVal: true` + 副标题；`lib/utils/storage_pref.dart` `defaultValue: true` |
| 悬浮底栏改磨砂玻璃 | 新文件 `lib/pages/main/glass_nav_bar.dart`：`BackdropFilter(ImageFilter.blur(sigmaX:22, sigmaY:22))` + 半透明白/深色底 + 细白边 |
| 下滑时向中间收起、收起后显示头像 | 同文件：`TweenAnimationBuilder` 320ms 把宽度从 `n*86+8` 收到 64，导航项向中间裁切淡出，头像淡入成胶囊；点胶囊展开（`onCollapsedTap` 归零 `barOffset` 并 `showBottomBar=true`） |

`lib/pages/main/view.dart` 的 `_bottomNav` 里，`floatingNavBar` 分支从 `FloatingNavigationBar` 换成 `GlassFloatingNavBar`，
`collapse` 由 `barOffset / Style.topBarHeight`（sync 模式）或 `showBottomBar`（instant 模式）驱动；
原「整条滑出屏幕」的 `AnimatedSlide/FractionalTranslation` 对悬浮底栏关闭（`if (hideBottomBar && !floatingNavBar)`）。

只改 Dart 文件时不用重建，用这个（实测 0.2–1s 出结果）：

```bash
bash hot.sh            # 热重载
bash hot.sh restart    # 热重启（改了全局状态/启动逻辑）
bash hot.sh shot       # 截图到 preview/last.png
```

预览（debug，包名 `com.example.piliplus.debug`，不产出交付 APK）：

```bash
cd PiliPlus/src && source /Users/y/toolchains/env.sh
bash ../port_build.sh android
flutter run -d emulator-5554 --debug --no-pub --dart-define-from-file=pili_release.json
# 改完代码热重载：kill -USR1 $(cat /tmp/flutter_run.pid)
```

截图：`preview/pure_02_home.png`（底部磨砂玻璃三页签）、`preview/pure_03_collapsed.png`（下滑收起成头像胶囊）、
`preview/pure_04_mine.png`（点胶囊展开 + 切到「我的」）、`preview/pure_06_about.png`（关于页）、
`preview/pure_07_appearance.png`（外观设置里开关默认开）。

## 设置页重组（第 6 轮）

设置首页从上到下：**主页设置 → 播放设置 → 动态设置 → 隐私设置 → 其它设置 → WebDAV → 切换账号 → 关于**（退出登录在切换账号下方）。

| 分组 | 二级入口 |
| --- | --- |
| 主页设置 | 推荐流设置、外观设置 |
| 播放设置 | 音视频设置、播放器设置、弹幕设置、评论设置 |

改动：
- 新增 `lib/pages/setting/group.dart`：`SettingGroupItem`（一个二级入口描述）+ `SettingGroupPage`（分组页，竖屏独立页、横屏塞进右侧面板）。
- `lib/pages/setting/view.dart`：`_SettingsModel` 增加 `groupTitle` / `children`（`type` 变可空），`_items` 重排成上面 7 项，
  `_toPage` 对分组跳 `SettingGroupPage`，横屏状态从 `SettingType _type` 改成 `_SettingsModel _selected`（分组也能占右栏）。
- `lib/utils/desktop/window_controller.dart`：依赖被重新解析到 nativeapi 0.5.5 后 `WindowEvent` 增加了 `WindowDockedEvent/WindowUndockedEvent`，
  穷尽 switch 编译失败，补 `default: break;`（桌面端不需要处理这两个事件）。
- `SettingType` 枚举没动（分组不是设置项），所以设置搜索页、`CommonSetting` 行为完全不变。

截图：`preview/set_home_group.png`、`preview/set_play_group.png`、`preview/set_play_detail.png`。

## 磨砂玻璃（第 8 轮：照搬 anyu 的玻璃配方）

原设计在 anyu 项目里：`/Users/y/Downloads/DSH/Mac工作区/velorah-hero`（Capacitor + Vue）。
- 全局玻璃令牌：`src/index.css` 的 `.portal-shell--glass .portal-card` / `.portal-nav`
  → `background: rgba(8,15,22,.42)`、`backdrop-filter: blur(20px) saturate(120%)`、
  `box-shadow: inset 0 1px 1px rgba(255,255,255,.16), 0 16px 48px rgba(0,0,0,.18)`。
- 展开列表/面板（图二那张播放页同款）：`public/music.html` 的 `--glass-2-*` 变量
  → 深色 `bg rgba(8,14,24,.55)` / 浅色 `rgba(252,252,254,.62)`；描边 深 `rgba(255,255,255,.18)` / 浅 `rgba(0,0,0,.10)`；
  顶部内高光 深 `rgba(255,255,255,.14)` / 浅 `.75`；`blur(14px) saturate(120%)`；`box-shadow: 0 12px 30px rgba(0,0,0,.42), inset 0 1px 0 …`；
  列表项 `--btn-bg` 深 `.08` / 浅 `.05`，hover `--btn-hover` 深 `.15` / 浅 `.10`，项圆角 8、面板圆角 12。
- 字体下拉（另一种列表）：`src/index.css` 的 `.hero-font-options` → `border-radius:16px; background:rgba(12,20,28,.52); backdrop-filter:blur(20px)`。

落到 Flutter：
- 新增 `lib/common/widgets/glass.dart`：`GlassPalette`（上面的深浅两套色值）、`GlassSurface`（`ClipRRect + BackdropFilter(blur) + 半透明底 + 1px 描边 + 顶部内高光 + 投影`）、
  `showGlassMenu()`（自写 `PopupRoute`，替代白色 `showMenu`；保留 `PopupMenuItem` 的 `height/enabled/onTap`，支持分隔线）。
- 悬浮底栏 `lib/pages/main/glass_nav_bar.dart` 改用 `GlassPalette`（bg/border/inset/shadow、`barBlur=10`，对应 CSS blur(20px)），选中药丸用 `itemBg`。
- 全项目 8 处 `showMenu(`（设置下拉、图片长按菜单、私信/超级弹幕/直播聊天/下载菜单、看图器）统一换成 `showGlassMenu(`。
- Flutter 的 `BackdropFilter` 只有高斯模糊，没有 `saturate()` 通道，饱和度那一点点差别未复刻；`blur(14px)` 取 `sigma≈7`（Chrome 的 sigma = 半径/2）。

## 已知取舍

- 源码为浅克隆（`--depth 1`），因此 CI 里 `git rev-list --count HEAD` 算出的 build 号是 `1`，版本显示 `2.2.0+1`（Android 侧 `2.2.0-265f879fa`）。
- 签名：Android 走 `signingConfigs["debug"]`（`key.properties` 缺失时自动回退）；iOS 为 ad-hoc（`codesign --sign -`），上真机需重签。
- 网络：`pub.dev` 在本机极慢，构建统一走 `pub.flutter-io.cn` + `storage.flutter-io.cn`；
  **手工执行 flutter 命令也要先 export 这两个变量**，否则 `pub get` 会把依赖重解析到 pub.dev 的未打补丁副本，编译立刻报 `widget isn't defined` 之类的一堆错；`dl.google.com` 拉 SDK manifest 与
  `repo.maven.apache.org` 偶发超时/503，重跑一次即可（Gradle 会续用已下载的依赖）。
- 磁盘：完整构建约 13–14G（Flutter SDK 2.3G、NDK 2.8G、pub cache 1.1G、Gradle wrapper+cache ~2G、模拟器 1.4G、build 产物 2G+）。
  **本机按用户要求不再删除任何构建工具/缓存**；如需腾空间，只清 `src/build`、`src/.dart_tool`、Xcode `DerivedData` 这类可再生成的中间产物（会拖慢下次重建）。
