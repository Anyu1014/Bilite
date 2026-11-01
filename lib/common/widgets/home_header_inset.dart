import 'package:material_ui/material_ui.dart';

/// 首页顶栏（含状态栏）当前占据的高度。
///
/// 首页把顶栏画成覆盖层（磨砂玻璃），内容需要自己留出这段空间：
/// 列表在顶部时从玻璃下方开始，向下滚动后内容会滑到玻璃后面被模糊。
class HomeHeaderInset extends InheritedWidget {
  const HomeHeaderInset({
    super.key,
    required this.value,
    required super.child,
  });

  final double value;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeHeaderInset>()?.value ??
      0.0;

  @override
  bool updateShouldNotify(HomeHeaderInset oldWidget) =>
      oldWidget.value != value;
}
