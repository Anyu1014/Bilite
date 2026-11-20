import 'dart:ui' show ImageFilter;

import 'package:flutter/physics.dart';

import 'package:bilite/common/widgets/bottom_bar_frame.dart';
import 'package:bilite/common/widgets/floating_navigation_bar.dart';
import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/utils/bili_colors.dart';
import 'package:bilite/pages/main/native_bottom_bar.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

const double _kBarHeight = bottomBarHeight;
const double _kBarRadius = _kBarHeight / 2;
// 药丸左右各留 6.5（与上下留白一致）：88 - 2*6.5
const double _kPillWidth = 75.0;
const double _kPillHeight = 46.0;
const double _kPillRadius = _kPillHeight / 2;
const double _kIconSize = 28.0;
const double _kCollapsedSize = bottomBarHeight;

final _nativeBarSpring = SpringSimulation(
  const SpringDescription(mass: 1, stiffness: 380, damping: 39),
  0,
  1,
  0,
);

class _NativeBarCurve extends Curve {
  const _NativeBarCurve();
  @override
  double transformInternal(double t) =>
      _nativeBarSpring.x(t * 0.42).clamp(0, 1);
}

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
    this.nativeItems,
  });

  final List<Map<String, Object?>>? nativeItems;

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
    final padding = MediaQuery.viewPaddingOf(context);
    final itemWidth = bottomBarWidth(1, showLabel: showLabel);
    final expandedWidth = bottomBarWidth(
      destinations.length,
      showLabel: showLabel,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(end: collapse.clamp(0.0, 1.0)),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: nativeItems == null ? 320 : 420),
      curve: nativeItems == null
          ? Curves.easeOutCubic
          : const _NativeBarCurve(),
      builder: (context, t, _) {
        final width = expandedWidth + (_kCollapsedSize - expandedWidth) * t;
        final usableWidth =
            MediaQuery.sizeOf(context).width - padding.left - padding.right;
        final compactSize = nativeItems == null
            ? _kCollapsedSize
            : nativeBottomBarHeight;
        final slide =
            ((usableWidth - compactSize) / 2 - bottomBarScreenGap) *
            t *
            collapsedAlign.x;
        final fallback = BottomBarFrame(
          width: width,
          offsetX:
              ((usableWidth - _kCollapsedSize) / 2 - bottomBarScreenGap) *
              t *
              collapsedAlign.x,
          child: _legacySurface(context, width, expandedWidth, itemWidth, t),
        );
        if (nativeItems != null) {
          return NativeBottomBarSurface(
            items: nativeItems!,
            selectedIndex: selectedIndex,
            showLabel: showLabel,
            collapse: t,
            expandedWidth: expandedWidth,
            compactOffset: slide,
            onDestinationSelected: onDestinationSelected,
            avatar: avatar,
            onCollapsedTap: onCollapsedTap,
            fallback: fallback,
          );
        }
        return fallback;
      },
    );
  }

  Widget _legacySurface(
    BuildContext context,
    double width,
    double expandedWidth,
    double itemWidth,
    double t,
  ) {
    // 跟随全局磨砂样式（设置 → 主页设置 → 悬浮底栏 → 磨砂玻璃样式）
    final glass = GlassPalette.of(context);
    final off = GlassPalette.style == GlassStyle.off;
    final glassColor = off
        ? Theme.of(context).colorScheme.surface
        : glass.surfaceBg;
    final borderColor = off ? const Color(0x00000000) : glass.surfaceBorder;
    // 悬浮底栏留一点很轻的投影，只用来把胶囊和背景分开（原先 0x42 的浓阴影太脏）。
    // 不跟随磨砂样式：关闭/高透/原生都要能看出边界。
    final glassShadow = Theme.of(context).brightness == Brightness.dark
        ? const Color(0x33000000)
        : const Color(0x14000000);
    final glassSigma = off ? 0.0 : glass.surfaceBlur;

    return Container(
      width: width,
      height: _kBarHeight,
      decoration: BoxDecoration(
        borderRadius: .circular(_kBarRadius),
        boxShadow: [
          BoxShadow(
            color: glassShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                              for (int i = 0; i < destinations.length; i++)
                                _GlassDestination(
                                  destination: destinations[i],
                                  selected: i == selectedIndex,
                                  showLabel: showLabel,
                                  width: itemWidth,
                                  onTap: () => onDestinationSelected(i),
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
    // 「图标跟随主题」：选中用 App 的粉色强调色（深浅色各一版），
    // 未选中用次要前景色；关闭后保持黑白两色。
    // 注意 M3 的 colorScheme.primary 是暗红色，不是 App 的粉色。
    final followTheme = Pref.floatingNavBarFollowTheme;
    final accent = theme.brightness == Brightness.dark
        ? BiliColors.pinkDark
        : BiliColors.pinkLight;
    final iconColor = selected
        ? (followTheme ? accent : colorScheme.onSurface)
        : (followTheme ? colorScheme.onSurfaceVariant : colorScheme.onSurface);
    return Column(
      mainAxisSize: .min,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: iconSize, color: iconColor),
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
                  ? (Pref.floatingNavBarFollowTheme
                        ? accent
                        : colorScheme.onSurface)
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
