import 'package:PiliPure/common/widgets/custom_icon.dart';
import 'package:PiliPure/common/widgets/glass.dart';
import 'package:PiliPure/common/widgets/flutter/list_tile.dart';
import 'package:PiliPure/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPure/common/widgets/view_safe_area.dart';
import 'package:PiliPure/http/login.dart';
import 'package:PiliPure/models/common/setting_type.dart';
import 'package:PiliPure/pages/about/view.dart';
import 'package:PiliPure/pages/login/controller.dart';
import 'package:PiliPure/pages/setting/common_setting.dart';
import 'package:PiliPure/pages/setting/group.dart';
import 'package:PiliPure/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPure/pages/webdav/view.dart';
import 'package:PiliPure/utils/accounts.dart';
import 'package:PiliPure/utils/accounts/account.dart';
import 'package:PiliPure/utils/extension/size_ext.dart';
import 'package:PiliPure/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class _SettingsModel {
  final SettingType? type;
  final String? groupTitle;
  final List<SettingGroupItem>? children;
  final String? subtitle;
  final Icon icon;

  const _SettingsModel({
    this.type,
    this.groupTitle,
    this.children,
    this.subtitle,
    required this.icon,
  });

  String get title => type?.title ?? groupTitle ?? '';
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late _SettingsModel _selected = _items.first;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  late bool _isPortrait;
  late ThemeData theme;

  static const List<_SettingsModel> _items = [
    // 主页设置：推荐流 + 外观
    _SettingsModel(
      groupTitle: '主页设置',
      subtitle: '推荐流、外观主题、首页与动态红点',
      icon: Icon(Icons.home_outlined),
      children: [
        SettingGroupItem(
          type: .recommendSetting,
          subtitle: '推荐来源（web/app）、刷新保留内容、过滤器',
          icon: Icon(Icons.explore_outlined),
        ),
        SettingGroupItem(
          type: .glassSetting,
          subtitle: '关闭 / 原生磨砂 / 高透磨砂（顶栏、底栏、菜单、弹窗全局）',
          icon: Icon(Icons.blur_on),
        ),
        SettingGroupItem(
          type: .floatingNavBarSetting,
          subtitle: '磨砂玻璃底栏：是否显示文字、收起后的位置',
          icon: Icon(MdiIcons.soundbar),
        ),
        SettingGroupItem(
          type: .styleSetting,
          subtitle: '横屏适配（平板）、侧栏、列宽、首页、动态红点、主题、字号、图片、帧率等',
          icon: Icon(Icons.style_outlined),
        ),
      ],
    ),
    // 播放设置：音视频 + 播放器 + 弹幕 + 评论
    _SettingsModel(
      groupTitle: '播放设置',
      subtitle: '音视频、播放器、弹幕、评论',
      icon: Icon(Icons.play_circle_outline),
      children: [
        SettingGroupItem(
          type: .videoSetting,
          subtitle: '画质、音质、解码、缓冲、音频输出等',
          icon: Icon(Icons.video_settings_outlined),
        ),
        SettingGroupItem(
          type: .playSetting,
          subtitle: '双击/长按、全屏、后台播放、弹幕、字幕、底部进度条等',
          icon: Icon(Icons.touch_app_outlined),
        ),
        SettingGroupItem(
          type: .dmSetting,
          subtitle: '点击弹幕、弹幕行高、彩色弹幕、合并弹幕',
          icon: Icon(CustomIcons.dm_settings),
        ),
        SettingGroupItem(
          type: .replySetting,
          subtitle: '过滤、屏蔽、记录、默认展示等',
          icon: Icon(Icons.comment_outlined),
        ),
      ],
    ),
    _SettingsModel(
      type: .dynSetting,
      subtitle: '过滤、屏蔽、默认展示等',
      icon: Icon(CustomIcons.motion_photos_on_outlined),
    ),
    _SettingsModel(
      type: .privacySetting,
      subtitle: '账号、黑名单',
      icon: Icon(Icons.privacy_tip_outlined),
    ),
    _SettingsModel(
      type: .extraSetting,
      subtitle: '震动、搜索、收藏、ai、评论、动态、代理、WebDAV、缓存等',
      icon: Icon(Icons.extension_outlined),
    ),
    _SettingsModel(
      type: .about,
      icon: Icon(Icons.info_outline),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme = Theme.of(context);
    _isPortrait = MediaQuery.sizeOf(context).isPortrait;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: _isPortrait ? const Text('设置') : Text(_selected.title),
      ),
      body: ViewSafeArea(
        child: _isPortrait
            ? _buildList(theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildList(theme),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    flex: 6,
                    child: _selected.children != null
                        ? SettingGroupPage(
                            title: _selected.title,
                            items: _selected.children!,
                            showAppBar: false,
                          )
                        : switch (_selected.type!) {
                            .webdavSetting => const WebDavSettingPage(
                              showAppBar: false,
                            ),
                            .about => const AboutPage(showAppBar: false),
                            final type => CommonSetting(
                              settingType: type,
                              showAppBar: false,
                            ),
                          },
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _noAccount.close();
    super.dispose();
  }

  void _toPage(_SettingsModel item) {
    final children = item.children;
    if (children != null) {
      if (_isPortrait) {
        Get.to(
          () => SettingGroupPage(title: item.title, items: children),
        );
      } else {
        _selected = item;
        setState(() {});
      }
      return;
    }
    final type = item.type!;
    if (_isPortrait) {
      Get.to(
        () => switch (type) {
          .webdavSetting => const WebDavSettingPage(),
          .about => const AboutPage(),
          _ => CommonSetting(settingType: type),
        },
      );
    } else {
      _selected = item;
      setState(() {});
    }
  }

  Color? _getTileColor(ThemeData theme, _SettingsModel item) {
    if (_isPortrait) {
      return null;
    } else {
      return identical(item, _selected)
          ? theme.colorScheme.onInverseSurface
          : null;
    }
  }

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: [
        _buildSearchItem(theme),
        ..._items
            .take(_items.length - 1)
            .map(
              (item) => ListTile(
                tileColor: _getTileColor(theme, item),
                onTap: () => _toPage(item),
                leading: item.icon,
                title: Text(item.title, style: titleStyle),
                subtitle: item.subtitle == null
                    ? null
                    : Text(item.subtitle!, style: subTitleStyle),
              ),
            ),
        ListTile(
          onTap: () => LoginPageController.switchAccountDialog(context),
          leading: const Icon(Icons.switch_account_outlined),
          title: Text('切换账号', style: titleStyle),
        ),
        Obx(
          () => _noAccount.value
              ? const SizedBox.shrink()
              : ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  onTap: () => _logoutDialog(context),
                  title: Text('退出登录', style: titleStyle),
                ),
        ),
        ListTile(
          tileColor: _getTileColor(theme, _items.last),
          onTap: () => _toPage(_items.last),
          leading: _items.last.icon,
          title: Text(_items.last.title, style: titleStyle),
        ),
      ],
    );
  }

  Future<void> _removeAccounts(Set<LoginAccount> accounts) async {
    await Accounts.deleteAll(accounts);
    if (mounted) _noAccount.value = Accounts.account.isEmpty;
  }

  static Future<LoginAccount?> _logoutWrapper(LoginAccount account) async {
    try {
      final res = await LoginHttp.logout(account);
      return res.isSuccess ? account : null;
    } catch (e, s) {
      Utils.reportError(e, s);
      return null;
    }
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return GlassAlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _removeAccounts(result);
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await Future.wait(result.map(_logoutWrapper));
                SmartDialog.dismiss();
                final logoutAccounts = res.nonNulls.toSet();
                if (logoutAccounts.isEmpty) {
                  SmartDialog.showToast('所选账号均退出登录失败');
                } else {
                  Get.back();
                  _removeAccounts(logoutAccounts);
                  if (logoutAccounts.length != result.length) {
                    result.removeWhere(logoutAccounts.contains);
                    SmartDialog.showToast(
                      '账号 ${result.map((i) => i.mid).join(",")} 退出登录失败',
                    );
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchItem(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 8,
    ),
    child: Material(
      color: theme.colorScheme.onInverseSurface,
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: InkWell(
        onTap: () => Get.toNamed('/settingsSearch'),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  size: 18,
                  applyTextScaling: true,
                  Icons.search,
                ),
                Text(
                  ' 搜索',
                  style: TextStyle(height: 1),
                  strutStyle: StrutStyle(height: 1, leading: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
