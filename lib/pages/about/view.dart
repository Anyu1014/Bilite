import 'dart:async';

import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/common/assets.dart';
import 'package:bilite/common/constants.dart';
import 'package:bilite/common/style.dart';
import 'package:bilite/common/widgets/dialog/dialog.dart';
import 'package:bilite/common/widgets/dialog/export_import.dart';
import 'package:bilite/common/widgets/dialog/simple_dialog_option.dart';
import 'package:bilite/common/widgets/flutter/list_tile.dart';
import 'package:bilite/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bilite/utils/accounts.dart';
import 'package:bilite/utils/app_scheme.dart';
import 'package:bilite/utils/cache_manager.dart';
import 'package:bilite/utils/date_utils.dart';
import 'package:bilite/utils/device_utils.dart';
import 'package:bilite/utils/extension/num_ext.dart';
import 'package:bilite/utils/page_utils.dart';
import 'package:bilite/utils/platform_utils.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  /// 关于页显示的版本号（手写；只改这一处文本）
  static const currentVersion = '1.3';

  /// 源码仓库地址（安装包在各版本分支的 dist/<版本>/ 下）
  static const repositoryUrl = 'https://github.com/Anyu1014/Bilite';
  static const repositoryName = 'Anyu1014/Bilite';
  RxString cacheSize = ''.obs;

  late int _pressCount = 0;

  @override
  void initState() {
    super.initState();
    getCacheSize();
  }

  @override
  void dispose() {
    cacheSize.close();
    super.dispose();
  }

  void getCacheSize() {
    CacheManager.loadApplicationCache().then((res) {
      if (mounted) {
        cacheSize.value = res.formatSize;
      }
    });
  }

  void _showDialog() => showDialog(
    context: context,
    builder: (context) => GlassAlertDialog(
      constraints: Style.dialogFixedConstraints,
      content: TextField(
        autofocus: true,
        onSubmitted: (value) {
          Get.back();
          if (value.isNotEmpty) {
            PiliScheme.routePushFromUrl(value);
          }
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const style = TextStyle(fontSize: 15);
    final outline = theme.colorScheme.outline;
    final subTitleStyle = TextStyle(fontSize: 13, color: outline);
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      appBar: showAppBar ? AppBar(title: const Text('关于')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: [
          GestureDetector(
            onTap: () {
              if (++_pressCount == 5) {
                _pressCount = 0;
                _showDialog();
              }
            },
            onSecondaryTap: PlatformUtils.isDesktop ? _showDialog : null,
            child: Image.asset(
              width: 150,
              height: 150,
              excludeFromSemantics: true,
              cacheWidth: 150.cacheSize(context),
              Assets.logo,
            ),
          ),
          ListTile(
            title: Text(
              Constants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(height: 2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('作者'),
            trailing: Text('Anyu', style: subTitleStyle),
          ),
          ListTile(
            onLongPress: () => Utils.copyText(currentVersion),
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => Utils.copyText(currentVersion),
            title: const Text('当前版本'),
            leading: const Icon(Icons.commit_outlined),
            trailing: Text(
              currentVersion,
              style: subTitleStyle,
            ),
          ),
          ListTile(
            onTap: () => PageUtils.launchURL(repositoryUrl),
            leading: const Icon(Icons.code_outlined),
            title: const Text('仓库'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(repositoryName, style: subTitleStyle),
                const SizedBox(width: 6),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            height: 30,
            color: theme.colorScheme.outlineVariant,
          ),
          ListTile(
            onTap: () {
              if (cacheSize.value.isNotEmpty) {
                showConfirmDialog(
                  context: context,
                  title: const Text('提示'),
                  content: const Text('该操作将清除图片及网络请求缓存数据，确认清除？'),
                  onConfirm: () async {
                    SmartDialog.showLoading(msg: '正在清除...');
                    try {
                      await CacheManager.clearLibraryCache();
                      SmartDialog.showToast('清除成功');
                    } catch (err) {
                      SmartDialog.showToast(err.toString());
                    } finally {
                      SmartDialog.dismiss();
                    }
                    getCacheSize();
                  },
                );
              }
            },
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除缓存'),
            subtitle: Obx(
              () => Text(
                '图片及网络缓存 ${cacheSize.value}',
                style: subTitleStyle,
              ),
            ),
          ),
          ListTile(
            title: const Text('导入/导出登录信息'),
            leading: const Icon(Icons.import_export_outlined),
            onTap: () => showImportExportDialog<Map<String, dynamic>>(
              context,
              title: '登录信息',
              localFileName: () => 'account',
              onExport: () =>
                  Utils.jsonEncoder.convert(Accounts.account.toMap()),
              onImport: Accounts.importJsonAccount,
            ),
          ),
          ListTile(
            title: const Text('导入/导出设置'),
            dense: false,
            leading: const Icon(Icons.import_export_outlined),
            onTap: () => showImportExportDialog<Map<String, dynamic>>(
              context,
              title: '设置',
              localFileName: () => 'setting_${DeviceUtils.platformName}',
              onExport: GStorage.exportAllSettings,
              onImport: GStorage.importAllJsonSettings,
            ),
          ),
          ListTile(
            title: const Text('导入/导出所有数据'),
            dense: false,
            leading: const Icon(Icons.archive_outlined),
            onTap: () => showDataImportExportDialog(context),
          ),
          ListTile(
            title: const Text('重置所有设置'),
            leading: const Icon(Icons.settings_backup_restore_outlined),
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  clipBehavior: Clip.hardEdge,
                  title: const Text('是否重置所有设置？'),
                  children: [
                    DialogOption(
                      onPressed: () async {
                        Get.back();
                        await Future.wait([
                          GStorage.setting.clear(),
                          GStorage.video.clear(),
                        ]);
                        SmartDialog.showToast('重置成功');
                      },
                      child: const Text('重置可导出的设置', style: style),
                    ),
                    DialogOption(
                      onPressed: () async {
                        Get.back();
                        await GStorage.clear();
                        SmartDialog.showToast('重置成功');
                      },
                      child: const Text('重置所有数据（含登录信息）', style: style),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
