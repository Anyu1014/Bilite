import 'package:PiliPure/models/common/collapsed_nav_align.dart';
import 'package:PiliPure/common/widgets/glass.dart';
import 'package:PiliPure/pages/setting/models/model.dart';
import 'package:PiliPure/utils/storage.dart';
import 'package:PiliPure/utils/storage_key.dart';
import 'package:PiliPure/utils/storage_pref.dart';
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
  const SwitchModel(
    title: '显示文字',
    subtitle: '默认只显示图标，与参考样式一致',
    leading: Icon(Icons.text_fields),
    setKey: SettingBoxKey.floatingNavBarLabel,
    defaultVal: false,
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
