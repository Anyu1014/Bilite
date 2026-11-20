import 'package:bilite/models/common/home_tab_type.dart';
import 'package:bilite/pages/setting/models/model.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 冷启动默认打开的首页板块。
///
/// 同一个入口在「主页设置」和「外观设置」各挂一份，共用这里的 PopupModel：
/// 两边读写同一个 Pref，改完再 forceAppUpdate，另一处立刻同步。
PopupModel<HomeTabType> get defaultHomeTabSetting => PopupModel<HomeTabType>(
  leading: const Icon(Icons.tab_unselected_outlined),
  title: '冷启动默认打开板块',
  value: () => Pref.defaultHomeTab,
  items: HomeTabType.values,
  onSelected: (value, setState) {
    GStorage.setting
        .put(SettingBoxKey.defaultHomeTab, value.index)
        .whenComplete(() {
          setState();
          Get.forceAppUpdate();
        });
    SmartDialog.showToast('重启生效');
  },
);

List<SettingsModel> get homeTabSettings => [defaultHomeTabSetting];
