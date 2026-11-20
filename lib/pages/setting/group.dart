import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bilite/common/widgets/view_safe_area.dart';
import 'package:bilite/models/common/home_tab_type.dart';
import 'package:bilite/models/common/setting_type.dart';
import 'package:bilite/pages/setting/common_setting.dart';
import 'package:bilite/pages/setting/widgets/popup_item.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 设置分组项：只描述「入口」，真正的设置在 [CommonSetting] 里
class SettingGroupItem {
  const SettingGroupItem({
    required this.type,
    required this.icon,
    this.subtitle,
  });

  final SettingType type;
  final Icon icon;
  final String? subtitle;
}

/// 主页设置 / 播放设置 这类分组页
class SettingGroupPage extends StatelessWidget {
  const SettingGroupPage({
    super.key,
    required this.title,
    required this.items,
    this.showAppBar = true,
  });

  final String title;
  final List<SettingGroupItem> items;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final titleStyle = theme.textTheme.titleMedium!;
    final subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return SimpleScaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: ViewSafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: padding.bottom + 100,
          ),
          children: [
            for (final item in items)
              // 应用主题：直接进主题页（不再埋在外观设置里）
              if (item.type == .themeSetting)
                ListTile(
                  onTap: () => Get.toNamed('/colorSetting'),
                  leading: item.icon,
                  title: Text(item.type.title, style: titleStyle),
                  subtitle: item.subtitle == null
                      ? null
                      : Text(item.subtitle!, style: subTitleStyle),
                )
              // 冷启动默认板块：同样直接弹选择
              else if (item.type == .homeTabSetting)
                PopupListTile<HomeTabType>(
                  leading: item.icon,
                  title: Text(item.type.title, style: titleStyle),
                  descStyle: subTitleStyle,
                  value: () => (Pref.defaultHomeTab, Pref.defaultHomeTab.label),
                  itemBuilder: (context) =>
                      enumItemBuilder(HomeTabType.values),
                  onSelected: (value, setState) {
                    GStorage.setting
                        .put(SettingBoxKey.defaultHomeTab, value.index)
                        .whenComplete(() {
                          setState();
                          Get.forceAppUpdate();
                        });
                    SmartDialog.showToast('重启生效');
                  },
                )
              // 磨砂玻璃：不跳二级页，直接在本页弹选择
              else if (item.type == .glassSetting)
                PopupListTile<GlassStyle>(
                  leading: item.icon,
                  title: Text(item.type.title, style: titleStyle),
                  descStyle: subTitleStyle,
                  value: () => (Pref.glassStyle, Pref.glassStyle.label),
                  itemBuilder: (context) => enumItemBuilder(GlassStyle.values),
                  onSelected: (value, setState) {
                    GStorage.setting
                        .put(SettingBoxKey.floatingNavBarStyle, value.index)
                        .whenComplete(() {
                          setState();
                          Get.forceAppUpdate();
                        });
                  },
                )
              else
                ListTile(
                  onTap: () => Get.to(
                    () => CommonSetting(settingType: item.type),
                  ),
                  leading: item.icon,
                  title: Text(item.type.title, style: titleStyle),
                  subtitle: item.subtitle == null
                      ? null
                      : Text(item.subtitle!, style: subTitleStyle),
                ),
          ],
        ),
      ),
    );
  }
}
