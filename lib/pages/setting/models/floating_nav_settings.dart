import 'dart:io';

import 'package:bilite/models/common/collapsed_nav_align.dart';
import 'package:bilite/pages/setting/models/model.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get floatingNavSettings => [
  const SwitchModel(
    title: '启用悬浮底栏',
    subtitle: '磨砂玻璃底栏，下滑时收拢成头像',
    leading: Icon(MdiIcons.soundbar),
    setKey: SettingBoxKey.floatingNavBar,
    defaultVal: true,
    needReboot: true,
  ),
  if (Platform.isIOS)
    SwitchModel(
      title: 'iOS 原生液态玻璃底栏',
      subtitle: 'iOS 26 及以上使用系统底栏，仅改变外观，不影响顶栏磨砂',
      leading: const Icon(Icons.blur_on),
      setKey: SettingBoxKey.iosNativeBottomBar,
      defaultVal: true,
      onChanged: (_) => Get.forceAppUpdate(),
    ),
  const SwitchModel(
    title: '显示文字',
    subtitle: '默认只显示图标，与参考样式一致',
    leading: Icon(Icons.text_fields),
    setKey: SettingBoxKey.floatingNavBarLabel,
    defaultVal: false,
  ),
  SwitchModel(
    title: '图标跟随主题',
    subtitle: '选中项用 App 的粉色强调色，关闭后保持黑白',
    leading: const Icon(Icons.palette_outlined),
    setKey: SettingBoxKey.floatingNavBarFollowTheme,
    defaultVal: true,
    onChanged: (value) => Get.forceAppUpdate(),
  ),
  PopupModel<CollapsedNavAlign>(
    title: '收起后位置',
    leading: const Icon(Icons.align_horizontal_center),
    value: () => Pref.floatingNavBarAlign,
    items: CollapsedNavAlign.values,
    onSelected: (value, setState) {
      GStorage.setting
          .put(SettingBoxKey.floatingNavBarAlign, value.index)
          .whenComplete(setState);
    },
  ),
];
