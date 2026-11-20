import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/pages/setting/models/model.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get glassSettings => [
  PopupModel<GlassStyle>(
    title: '磨砂玻璃',
    leading: const Icon(Icons.blur_on),
    value: () => Pref.glassStyle,
    items: GlassStyle.values,
    onSelected: (value, setState) {
      GStorage.setting
          .put(SettingBoxKey.floatingNavBarStyle, value.index)
          .whenComplete(() {
            setState();
            Get.forceAppUpdate();
          });
    },
  ),
];
