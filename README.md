# PiliPure

哔哩哔哩第三方 Android / iOS 客户端，基于 Flutter 开发；本项目是 PiliPlus 的个人定制版。

## 定制内容

- 应用名、包名统一为 PiliPure（Android `applicationId` / iOS bundle id 均为 `com.pilipure.app`）
- 粉色系图标，磨砂玻璃悬浮底栏，设置项按分组重排
- 移除上游自更新通道

## 目录

```
PiliPure/
├── build/   # 交付产物：latest/ 当前安装包，history/ 旧版本
├── src/     # Flutter 源码、原生工程、打包脚本（本仓库）
└── .cache/  # 构建日志、临时文件，可随时删除
```

## 构建

打包统一走共用工具箱入口，不直接调用项目内脚本：

```bash
/Users/y/toolchains/bin/pilipure apk      # Android，3 个 ABI
/Users/y/toolchains/bin/pilipure ipa      # iOS（ad-hoc 签名）
/Users/y/toolchains/bin/pilipure install  # 安装到已连接设备
/Users/y/toolchains/bin/pilipure out      # 列出 build/latest 与 build/history
```

产物落在 `build/latest/`，同名旧版本自动移入 `build/history/`。

## 声明

本项目与哔哩哔哩官方无任何隶属或合作关系，仅供学习与技术研究，请于下载后 24 小时内删除。
