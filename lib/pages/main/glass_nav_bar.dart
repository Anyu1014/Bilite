import 'dart:ui' show ImageFilter;

import 'package:PiliPure/common/widgets/floating_navigation_bar.dart';
import 'package:PiliPure/common/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';

// 全部按参考图 IMG_0358 的实测比例：
// 底栏 856x190、胶囊端 r≈h/2；药丸 276x148、端部半圆；图标高≈0.62×药丸高；
// 药丸占栏宽 0.322、上下留白 0.11×栏高；栏高/栏宽 = 0.222。
// 取槽宽 88 → 栏宽 264、栏高 59、药丸 85x46、图标 28，比例与参考图一致。
const double _kBarHeight = 59.0;
const double _kBarRadius = _kBarHeight / 2;
const double _kItemWidth = 86.0;
const double _kIconOnlyWidth = 88.0;
// 药丸左右各留 6.5（与上下留白一致）：88 - 2*6.5
const double _kPillWidth = 75.0;
const double _kPillHeight = 46.0;
const double _kPillRadius = _kPillHeight / 2;
const double _kIconSize = 28.0;
const double _kCollapsedSize = 59.0;

/// 药丸与底栏边缘的留白（上下一致）
const double _kBarInset = (_kBarHeight - _kPillHeight) / 2;

/// 收起后胶囊离屏幕边缘的小缝：贴边但不贴死
const double _kScreenGap = 18.0;

/// 磨砂玻璃悬浮底栏：
/// 展开时是整条毛玻璃导航栏，随页面下滑向中间收拢，
/// 收起后只保留一枚用户头像胶囊。
class GlassFloatingNavBar extends StatelessWidget {
  const GlassFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.avatar,
    required this.collapse,
    this.onCollapsedTap,
    this.showLabel = true,
    this.collapsedAlign = Alignment.center,
  });

  final int selectedIndex;
  final List<FloatingNavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  /// 收起后显示的用户头像
  final Widget avatar;

  /// 0 = 完全展开，1 = 完全收起
  final double collapse;

  /// 点击收起状态下的头像
  final VoidCallback? onCollapsedTap;

  /// 是否显示文字（关闭后只显示图标）
  final bool showLabel;

  /// 收起后头像胶囊的水平位置
  final Alignment collapsedAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == .dark;
    final padding = MediaQuery.viewPaddingOf(context);
    final itemWidth = showLabel ? _kItemWidth : _kIconOnlyWidth;
    final expandedWidth = destinations.length * itemWidth;

    // 跟随全局磨砂样式（设置 → 主页设置 → 悬浮底栏 → 磨砂玻璃样式）
    final glass = GlassPalette.of(context);
    final off = GlassPalette.style == GlassStyle.off;
    final glassColor = off
        ? Theme.of(context).colorScheme.surface
        : glass.surfaceBg;
    final borderColor = off ? const Color(0x00000000) : glass.surfaceBorder;
    final glassShadow = glass.surfaceShadow;
    final glassSigma = off ? 0.0 : glass.surfaceBlur;

    return Padding(
      padding: .fromLTRB(
        padding.left,
        0,
        padding.right,
        8 + padding.bottom,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: collapse.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final width = expandedWidth + (_kCollapsedSize - expandedWidth) * t;
          // 展开时始终居中；收起时只让药丸沿着「整条底栏的范围」滑向左/右端，
          // 位移上限 = (展开宽 - 收起宽) / 2，正好让胶囊外沿停在本栏边缘，不贴屏幕。
          // 收起后胶囊滑到接近屏幕边缘（而不是只滑到本栏端点），
          // 留 _kScreenGap 的缝，所以「贴边但不完全贴边」。
          final usableWidth =
              MediaQuery.sizeOf(context).width - padding.left - padding.right;
          final slide =
              ((usableWidth - _kCollapsedSize) / 2 - _kScreenGap) *
              t *
              collapsedAlign.x;
          return SizedBox(
            height: _kBarHeight,
            child: Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(slide, 0),
                child: Container(
                  width: width,
                  height: _kBarHeight,
                  decoration: BoxDecoration(
                    borderRadius: .circular(_kBarRadius),
                    boxShadow: glassShadow == null
                        ? null
                        : [
                            BoxShadow(
                              color: glassShadow,
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: .circular(_kBarRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: glassSigma,
                        sigmaY: glassSigma,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: .circular(_kBarRadius),
                          // 与顶栏一致：磨砂开启时无缝，关闭后给一条淡灰边
                          border: off ? .all(color: borderColor) : null,
                        ),
                        child: Stack(
                          alignment: .center,
                          children: [
                            // 展开态：导航项，收起时向中间收拢并被裁切
                            ClipRect(
                              child: OverflowBox(
                                maxWidth: expandedWidth,
                                maxHeight: _kBarHeight,
                                child: Opacity(
                                  opacity: (1 - t * 1.8).clamp(0.0, 1.0),
                                  child: IgnorePointer(
                                    ignoring: t > 0.35,
                                    child: SizedBox(
                                      width: expandedWidth,
                                      height: _kBarHeight,
                                      child: Row(
                                        children: [
                                          for (
                                            int i = 0;
                                            i < destinations.length;
                                            i++
                                          )
                                            _GlassDestination(
                                              destination: destinations[i],
                                              selected: i == selectedIndex,
                                              showLabel: showLabel,
                                              width: itemWidth,
                                              onTap: () =>
                                                  onDestinationSelected(i),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 收起态：用户头像
                            IgnorePointer(
                              ignoring: t < 0.35,
                              child: GestureDetector(
                                onTap: onCollapsedTap,
                                behavior: .opaque,
                                child: Opacity(
                                  opacity: t,
                                  child: SizedBox(
                                    width: _kBarHeight,
                                    height: _kBarHeight,
                                    child: Center(
                                      child: SizedBox(
                                        width: 46,
                                        height: 46,
                                        child: avatar,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassDestination extends StatelessWidget {
  const _GlassDestination({
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.width,
    required this.onTap,
  });

  final FloatingNavigationDestination destination;
  final bool selected;
  final bool showLabel;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // 有文字时收紧：图标 28→22、字 12→11、内边距收窄，保证药丸高度 ≤46、左右留白与仅图标时一致
    // 药丸两种模式完全一致：75×46、半圆端，与仅图标时同款
    const pillRadius = _kPillRadius;
    return SizedBox(
      width: width,
      height: _kBarHeight,
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashFactory: InkSparkle.splashFactory,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _kPillWidth,
              height: _kPillHeight,
              alignment: Alignment.center,
              padding: showLabel ? const EdgeInsets.all(4) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: selected
                    ? GlassPalette.of(context).itemBg
                    : Colors.transparent,
                borderRadius: .circular(pillRadius),
              ),
              // 有文字时整体缩放到药丸内，避免图标/字体偏大撑满
              child: showLabel
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _pillContent(theme, colorScheme),
                    )
                  : _pillContent(theme, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillContent(ThemeData theme, ColorScheme colorScheme) {
    final iconSize = showLabel ? 22.0 : _kIconSize;
    return Column(
      mainAxisSize: .min,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: iconSize),
          child: selected
              ? destination.selectedIcon ?? destination.icon
              : destination.icon,
        ),
        if (showLabel) ...[
          const SizedBox(height: 1),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: theme.textTheme.labelSmall!.copyWith(
              height: 1.0,
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(destination.label, maxLines: 1),
          ),
        ],
      ],
    );
  }
}
