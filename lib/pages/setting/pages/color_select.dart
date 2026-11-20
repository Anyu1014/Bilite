import 'package:bilite/common/widgets/bottom_bar_frame.dart';

import 'dart:io' show Platform;

import 'package:bilite/common/widgets/animated_height.dart';
import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/common/widgets/color_palette.dart';
import 'package:bilite/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bilite/main.dart' show MyApp;
import 'package:bilite/models/common/nav_bar_config.dart';
import 'package:bilite/models/common/theme/theme_color_type.dart';
import 'package:bilite/models/common/theme/theme_type.dart';
import 'package:bilite/pages/home/view.dart';
import 'package:bilite/pages/mine/controller.dart';
import 'package:bilite/pages/setting/slide_color_picker.dart';
import 'package:bilite/pages/setting/widgets/popup_item.dart';
import 'package:bilite/pages/setting/widgets/select_dialog.dart';
import 'package:bilite/utils/extension/get_ext.dart';
import 'package:bilite/utils/extension/theme_ext.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:bilite/utils/theme_utils.dart';
import 'package:collection/collection.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class ColorSelectPage extends StatefulWidget {
  const ColorSelectPage({super.key});

  @override
  State<ColorSelectPage> createState() => _ColorSelectPageState();
}

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

/// 调色板风格下拉里显示的名字：原生或 flex_seed_scheme 的变体名
String _paletteStyleLabel(int index) => index == Pref.nativePaletteStyle
    ? '原生'
    : Pref.variantOfPaletteStyle(index).variantName;

class _ColorSelectPageState extends State<ColorSelectPage> {
  final ctr = Get.put(_ColorSelectController());
  int _paletteStyle = Pref.paletteStyleIndex;

  Future<void> _onChanged([bool? val]) async {
    val ??= !ctr.dynamicColor.value;
    if (val && !await MyApp.initPlatformState()) {
      SmartDialog.showToast('设备可能不支持动态取色');
      if (kReleaseMode) {
        return;
      }
    }
    ctr.dynamicColor.value = val;
    await GStorage.setting.put(SettingBoxKey.dynamicColor, val);
    Get.updateMyAppTheme();
  }

  /// 退出「默认」风格（选调色板风格或换主题色时调用）
  Future<void> _cancelDefaultThemeStyle() async {
    if (!ctr.defaultThemeStyle.value) return;
    ctr.defaultThemeStyle.value = false;
    await GStorage.setting.put(SettingBoxKey.defaultThemeStyle, false);
  }

  Future<void> _onDefaultThemeStyleChanged(bool val) async {
    ctr.defaultThemeStyle.value = val;
    await GStorage.setting.put(SettingBoxKey.defaultThemeStyle, val);
    if (val) {
      // 默认风格固定用默认亮粉
      ctr.currentColor.value = 0;
      await GStorage.setting.put(SettingBoxKey.customColor, 0);
      // 切回默认时取消调色板风格，回到默认的 Material 3 legacy
      _paletteStyle = FlexSchemeVariant.material3Legacy.index;
      await GStorage.setting.put(
        SettingBoxKey.schemeVariant,
        _paletteStyle,
      );
    }
    Get.updateMyAppTheme();
  }

  late ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = theme.textTheme.titleMedium!;
    final subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.viewPaddingOf(
      context,
    ).copyWith(top: 0, bottom: 0);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('选择应用主题')),
      body: ListView(
        padding: .only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
        ),
        children: [
          ListTile(
            onTap: () async {
              final result = await showDialog<ThemeType>(
                context: context,
                builder: (context) => SelectDialog<ThemeType>(
                  title: '主题模式',
                  value: ctr.themeType.value,
                  values: ThemeType.values.map((e) => (e, e.label)).toList(),
                ),
              );
              if (result != null) {
                try {
                  Get.find<MineController>().themeType.value = result;
                } catch (_) {}
                ctr.themeType.value = result;
                // 先落盘再切，MyApp 重建时读到的才是新模式
                await GStorage.setting.put(
                  SettingBoxKey.themeMode,
                  result.index,
                );
                Get.changeThemeMode(ThemeUtils.themeMode = result.toThemeMode);
              }
            },
            leading: const Icon(Icons.flashlight_on_outlined),
            title: Text('主题模式', style: titleStyle),
            subtitle: Obx(
              () => Text(
                '当前模式：${ctr.themeType.value.label}',
                style: subTitleStyle,
              ),
            ),
          ),
          Obx(
            () => ListTile(
              title: const Text('默认'),
              subtitle: Text(
                '默认亮粉（与昵称同色）；我的页板块图标蓝色、数值灰色；底栏选中亮粉、未选黑色（选调色板风格即退出）',
                style: subTitleStyle,
              ),
              leading: IgnorePointer(
                // 单选状态只作展示，点击整行由 ListTile.onTap 处理，避免双重切换
                child: RadioGroup<bool>(
                  groupValue: ctr.defaultThemeStyle.value ? true : null,
                  onChanged: (_) {},
                  child: const Radio<bool>(
                    value: true,
                    materialTapTargetSize: .shrinkWrap,
                    visualDensity: .new(horizontal: -4, vertical: -4),
                  ),
                ),
              ),
              onTap: () =>
                  _onDefaultThemeStyleChanged(!ctr.defaultThemeStyle.value),
            ),
          ),
          PopupListTile<int>(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('调色板风格'),
            value: () => (_paletteStyle, _paletteStyleLabel(_paletteStyle)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: Pref.nativePaletteStyle,
                child: Text('原生'),
              ),
              for (final e in FlexSchemeVariant.values)
                PopupMenuItem(value: e.index, child: Text(e.variantName)),
            ],
            onSelected: (value, setState) async {
              _paletteStyle = value;
              // 选调色板风格即退出「默认」风格
              await _cancelDefaultThemeStyle();
              await GStorage.setting.put(SettingBoxKey.schemeVariant, value);
              Get.updateMyAppTheme();
              setState();
            },
          ),
          if (!Platform.isIOS)
            Obx(
              () => ListTile(
                title: const Text('动态取色'),
                leading: ExcludeFocus(
                  child: Checkbox(
                    value: ctr.dynamicColor.value,
                    onChanged: _onChanged,
                    materialTapTargetSize: .shrinkWrap,
                    visualDensity: const .new(horizontal: -4, vertical: -4),
                  ),
                ),
                onTap: _onChanged,
              ),
            ),
          Padding(
            padding: padding + const .all(12),
            child: Obx(_buildColorPanel),
          ),
          Padding(
            padding: padding,
            child: ExcludeFocus(
              child: IgnorePointer(
                child: Container(
                  height: size.height / 2,
                  width: size.width,
                  color: theme.colorScheme.surface,
                  child: const HomePage(),
                ),
              ),
            ),
          ),
          ExcludeFocus(
            child: IgnorePointer(
              child: BottomBarFrame(
                width: bottomBarWidth(
                  NavigationBarType.values.length,
                  showLabel: Pref.floatingNavBarLabel,
                ),
                child: NavigationBar(
                  height: bottomBarHeight,
                  destinations: NavigationBarType.values
                      .map(
                        (item) => NavigationDestination(
                          icon: item.icon,
                          label: item.label,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPanel() {
    final currentColor = ctr.currentColor.value;
    return AnimatedHeightWidgetExt(
      expand: !ctr.dynamicColor.value,
      duration: const Duration(milliseconds: 200),
      child: Wrap(
        spacing: 22,
        runSpacing: 18,
        alignment: .center,
        children: [
          Builder(
            builder: (context) {
              final isCurr = currentColor >= colorThemeTypes.length;
              final color = isCurr
                  ? Color(currentColor)
                  : colorThemeTypes[currentColor].color;
              return GestureDetector(
                behavior: .opaque,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => GlassAlertDialog(
                      clipBehavior: .hardEdge,
                      contentPadding: const .symmetric(vertical: 16),
                      title: const Text('Color Picker'),
                      content: SlideColorPicker(
                        color: color,
                        onChanged: (Color? color) {
                          if (color != null) {
                            final res = color.toARGB32();
                            _cancelDefaultThemeStyle();
                            ctr.currentColor.value = res;
                            GStorage.setting
                                .put(SettingBoxKey.customColor, res)
                                .whenComplete(Get.updateMyAppTheme);
                          }
                        },
                      ),
                    ),
                  );
                },
                child: Column(
                  spacing: 3,
                  children: [
                    ColorPalette(
                      // 预览的主色用原色，而不是 M3 派生出来的暗一档
                      colorScheme: color
                          .asColorSchemeSeed(
                            Pref.variantOfPaletteStyle(_paletteStyle),
                            theme.brightness,
                          )
                          .copyWith(primary: color),
                      selected: isCurr,
                    ),
                    Text(
                      '自定义',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurr
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ...colorThemeTypes.mapIndexed(
            (i, e) {
              final color = e.color;
              final isCurr = currentColor == i;
              return GestureDetector(
                behavior: .opaque,
                onTap: () async {
                  await _cancelDefaultThemeStyle();
                  ctr.currentColor.value = i;
                  await GStorage.setting.put(SettingBoxKey.customColor, i);
                  Get.updateMyAppTheme();
                },
                child: Column(
                  spacing: 3,
                  children: [
                    ColorPalette(
                      // 预览的主色用原色，而不是 M3 派生出来的暗一档
                      colorScheme: color
                          .asColorSchemeSeed(
                            Pref.variantOfPaletteStyle(_paletteStyle),
                            theme.brightness,
                          )
                          .copyWith(primary: color),
                      selected: isCurr,
                    ),
                    Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurr ? null : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColorSelectController extends GetxController {
  final RxBool dynamicColor = Pref.dynamicColor.obs;
  final RxBool defaultThemeStyle = Pref.defaultThemeStyle.obs;
  final RxInt currentColor = Pref.customColor.obs;
  final Rx<ThemeType> themeType = Pref.themeType.obs;
}
