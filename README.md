# Bilite

哔哩哔哩第三方客户端，Android / iOS 双端，基于 Flutter 开发。

Bilite 是 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 的个人定制版：保留上游完整的播放、弹幕、直播、动态、收藏与离线能力，重做了外观、图标与设置结构，并移除了上游的自更新通道。

## 特性

- 双端一致：Android 与 iOS 共用同一份 Dart 代码与界面
- 粉色系图标与品牌视觉，磨砂玻璃悬浮底栏
- 设置项按分组重排，减少层级跳转
- 播放器支持手势、倍速、画中画、后台播放与投屏
- 弹幕、直播、番剧、动态、收藏、历史、离线缓存
- 无自更新通道，版本由本仓库发布

## 下载

安装包放在**各版本分支**的 `release/<版本>/` 目录下，同名文件对应同一份源码：

- `release/1.3/Bilite-1.3.apk`：Android，arm64-v8a，最低 Android 8.0
- `release/1.3/Bilite-1.3.ipa`：iOS，ad-hoc 签名，需自签后安装

即：要 1.3 的包，切到 `1.3` 分支取 `release/1.3/`；要 1.4 的包，切到 `1.4` 分支取 `release/1.4/`。

## 分支与发布

**一个版本一个分支，分支名就是版本号。**

- 分支名严格等于版本号，两段式数字：`1.3`、`1.4`、`1.5`……不用 `v` 前缀，不带日期和后缀。
- 每个版本分支里同时存放：该版本的完整源码 + `release/<版本>/` 下的 Android 与 iOS 安装包。
- 分支一经发布不再改动源码；发现问题在新版本分支修复，避免已发布分支与已发安装包对不上。
- `main` 只跟随源码主线，不放安装包。

发布一个新版本的固定动作：

```bash
# 1. 源码打包（Android + iOS）
bilite apk && bilite ipa

# 2. 建版本分支并放入安装包
git checkout -b 1.4
mkdir -p release/1.4 && cp ../build/latest/Bilite-1.4.* release/1.4/
git add -A && git commit -m "Bilite 1.4：源码与双端安装包"
git push -u origin 1.4
```

提交信息统一写成 `Bilite <版本>：源码与双端安装包`，便于在分支列表里一眼认出发布点。

## 从源码构建

需要 Flutter 3.47 及以上、Android SDK 36、Xcode 16（iOS）。

```bash
flutter pub get
flutter build apk --release --split-per-abi      # Android
flutter build ipa --release                      # iOS
```

产物在 `build/app/outputs/`。

## 目录结构

```
src/
├── lib/          # Dart 源码：页面、组件、播放器、API
├── android/      # Android 原生工程
├── ios/          # iOS 原生工程
└── assets/       # 图标、字体与静态资源
```

## 致谢

本项目的基础来自上游开源项目 **PiliPlus**（<https://github.com/bggRGjQaUbCoE/PiliPlus>），Bilite 在其上完成定制。感谢 PiliPlus 作者与所有贡献者的工作。

同时感谢 PiliPlus 所依赖的开源生态，包括 Flutter、media-kit、dio、getx、hive 等项目。

## 声明

本项目与哔哩哔哩官方无任何隶属或合作关系，仅供学习与技术研究使用。所有视频、弹幕与用户内容版权归原作者及哔哩哔哩所有。请于下载后 24 小时内删除。

## 许可

GPL-3.0，见 [LICENSE](LICENSE)。
