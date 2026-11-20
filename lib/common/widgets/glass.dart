import 'dart:ui' show ImageFilter;

import 'package:bilite/models/common/enum_with_label.dart';
import 'package:bilite/utils/page_utils.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

/// 全局磨砂玻璃样式（设置里「磨砂玻璃样式」）
enum GlassStyle with EnumWithLabel {
  /// 关闭：不启用磨砂玻璃，回到原来的纯色背景
  off('关闭'),

  /// 高透磨砂：anyu 的 .action-capsule（--btn-bg 底 + --border-color 边框 + blur 10px，无投影）
  clear('高透磨砂'),

  /// 原生磨砂：anyu 的 .row-menu（--glass-2-bg 底 + blur 20px + 30px 投影）
  native('原生磨砂');

  const GlassStyle(this.label);

  @override
  final String label;
}

/// anyu 项目（velorah-hero）的磨砂玻璃配方，取自 public/music.html 的 CSS 变量：
///   --glass-2-bg     深色 rgba(8,14,24,.55) / 浅色 rgba(252,252,254,.62)
///   --glass-2-border 深色 rgba(255,255,255,.18) / 浅色 rgba(0,0,0,.10)
///   --glass-2-inset  深色 rgba(255,255,255,.14) / 浅色 rgba(255,255,255,.75)
///   --btn-bg         深色 rgba(255,255,255,.08) / 浅色 rgba(0,0,0,.05)
///   backdrop-filter: blur(14px) saturate(120%)（导航条用 blur(20px)）
///   box-shadow: 0 12px 30px rgba(0,0,0,.42), inset 0 1px 0 var(--glass-2-inset)
/// Flutter 的 BackdropFilter 只有高斯模糊（sigma ≈ CSS 半径 / 2），没有 saturate 通道。
class GlassPalette {
  const GlassPalette({
    required this.bg,
    required this.border,
    required this.inset,
    required this.itemBg,
    required this.itemBgHover,
    required this.shadow,
    required this.capsuleBg,
    required this.capsuleBorder,
  });

  factory GlassPalette.of(BuildContext context) {
    return Theme.of(context).brightness == .dark ? dark : light;
  }

  // 用 getter 而不是 static const：const 实例在 hot reload 时不会重新求值，改色号看不到效果
  static GlassPalette get dark => const GlassPalette(
    bg: Color.fromRGBO(8, 14, 24, 0.55),
    border: Color.fromRGBO(255, 255, 255, 0.18),
    inset: Color.fromRGBO(255, 255, 255, 0.14),
    itemBg: Color.fromRGBO(255, 255, 255, 0.08),
    itemBgHover: Color.fromRGBO(255, 255, 255, 0.15),
    shadow: Color.fromRGBO(0, 0, 0, 0.42),
    capsuleBg: Color.fromRGBO(255, 255, 255, 0.08),
    capsuleBorder: Color.fromRGBO(255, 255, 255, 0.15),
  );

  static GlassPalette get light => const GlassPalette(
    bg: Color.fromRGBO(252, 252, 254, 0.62),
    border: Color.fromRGBO(0, 0, 0, 0.10),
    inset: Color.fromRGBO(255, 255, 255, 0.75),
    itemBg: Color.fromRGBO(0, 0, 0, 0.05),
    itemBgHover: Color.fromRGBO(0, 0, 0, 0.10),
    // anyu 的 .row-menu 阴影两种模式下都是 0 12px 30px rgba(0,0,0,.42)
    shadow: Color.fromRGBO(0, 0, 0, 0.42),
    capsuleBg: Color.fromRGBO(0, 0, 0, 0.05),
    capsuleBorder: Color.fromRGBO(0, 0, 0, 0.10),
  );

  final Color bg;
  final Color border;
  final Color inset;
  final Color itemBg;
  final Color itemBgHover;
  final Color shadow;

  /// anyu `.action-capsule`：background 用 --btn-bg、border 用 --border-color
  final Color capsuleBg;
  final Color capsuleBorder;

  /// 菜单/弹窗专用：anyu `.liquid-glass` 的浅底 rgba(255,255,255,.01)，
  /// 配合 1.4px 渐变环实现「上面是白的两边是黑的」效果。
  static const Color cardBg = Color(0x03FFFFFF);

  static GlassPalette get card => const GlassPalette(
    bg: cardBg,
    border: Color(0x2EFFFFFF),
    inset: Color(0x1AFFFFFF),
    itemBg: Color(0x14FFFFFF),
    itemBgHover: Color(0x21FFFFFF),
    shadow: Color(0x2E000000),
    capsuleBg: Color(0x14FFFFFF),
    capsuleBorder: Color(0x2EFFFFFF),
  );

  /// CSS blur(14px) ≈ sigma 7（.row-menu 菜单/弹窗）
  static const double menuBlur = 7;

  /// CSS blur(10px) ≈ sigma 5（.action-capsule 悬浮底栏）
  static const double capsuleBlur = 5;

  /// 旧名保留
  static const double barBlur = capsuleBlur;

  static GlassStyle get style => Pref.glassStyle;

  /// 当前样式下玻璃面板的底色
  Color get surfaceBg => switch (style) {
    // off 时由 GlassSurface 用主题 surface 覆盖，这里的 bg 不会被用到
    GlassStyle.off => bg,
    GlassStyle.clear => capsuleBg,
    GlassStyle.native => bg,
  };

  /// 关闭磨砂后的纯色面板仍需一条很淡的灰边（底栏除外，见 glass_nav_bar.dart）
  /// anyu `.row-menu` 的 box-shadow：0 12px 30px rgba(0,0,0,.42)
  static const Color anyuShadow = Color(0x6B000000);

  /// anyu `.portal-card` / `.message` 的 box-shadow：
  /// `inset 0 1px 1px rgba(255,255,255,.16), 0 16px 48px rgba(0,0,0,.18)`
  static const BoxShadow anyuCardShadow = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 48,
    offset: Offset(0, 16),
  );
  static const Color anyuCardInset = Color(0x29FFFFFF);

  Color get offHairline => bg.computeLuminance() < 0.5
      ? const Color(0x1AFFFFFF) // 深色：白 10%
      : const Color(0x14000000); // 浅色：黑 8%

  /// 当前样式下玻璃面板的边框
  Color get surfaceBorder => switch (style) {
    GlassStyle.off => offHairline,
    GlassStyle.clear => capsuleBorder,
    GlassStyle.native => border,
  };

  /// 当前样式下的模糊强度（blur(10px) → 5，blur(20px) → 10，关闭 → 0）
  double get surfaceBlur => switch (style) {
    GlassStyle.off => 0,
    GlassStyle.clear => capsuleBlur,
    GlassStyle.native => 10,
  };

  /// 当前样式下的投影；高透磨砂与关闭没有投影
  Color? get surfaceShadow => style == GlassStyle.native ? shadow : null;

  /// 关闭磨砂时用的纯色底色（跟随主题 surface）
  static Color opaqueBgOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
}

/// sigma 为 0 时直接返回 child（关闭磨砂玻璃，省掉一次 BackdropFilter）
class _MaybeBlurWidget extends StatelessWidget {
  const _MaybeBlurWidget({
    required this.sigma,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  final double sigma;
  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (sigma <= 0) {
      return child;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}

/// anyu 风格的一块磨砂玻璃：背景模糊 + 半透明底色 + 1px 描边 + 顶部内高光 + 投影
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.blurSigma,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.palette,
    this.shadow = true,
    this.shadowColor,
    this.boxShadow,
    this.insetColor,
    this.surfaceColor,
    this.border = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double borderRadius;

  /// 为空时按当前 GlassStyle 取默认值
  final double? blurSigma;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final GlassPalette? palette;
  final bool shadow;

  /// 覆盖投影颜色（不传则按 GlassStyle 取；anyu 的 .row-menu 固定用 [GlassPalette.anyuShadow]）
  final Color? shadowColor;

  /// 直接指定整条投影（anyu `.portal-card` 用 [GlassPalette.anyuCardShadow]）
  final BoxShadow? boxShadow;

  /// 顶部 1px 内高光颜色（默认取 palette.inset）
  final Color? insetColor;

  /// 固定底色（菜单/弹窗用 [GlassPalette.cardBg]，不随主题与档位变化）
  final Color? surfaceColor;

  /// 是否画 1px 边框（顶栏这类通栏可以用 false，只保留底色与模糊）
  final bool border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? GlassPalette.of(context);
    final radius = BorderRadius.circular(borderRadius);
    final off = GlassPalette.style == GlassStyle.off;
    final shadowColor = this.shadowColor ?? p.surfaceShadow;
    final sigma = off ? 0.0 : (blurSigma ?? p.surfaceBlur);
    final surfaceColor = off
        ? Theme.of(context).colorScheme.surface
        : (this.surfaceColor ?? p.surfaceBg);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: !shadow
              ? null
              : [
                  boxShadow ??
                      (shadowColor != null
                          ? BoxShadow(
                              color: shadowColor,
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            )
                          : const BoxShadow(
                              color: Color(0x00000000),
                              blurRadius: 0,
                            )),
                ],
        ),
        // 环画在 ClipRRect 外层：放在里面会被圆角裁掉转角处的圆弧，只剩两段直线
        child: CustomPaint(
          foregroundPainter: border && !off
              ? LiquidEdgePainter(borderRadius)
              : null,
          child: ClipRRect(
            borderRadius: radius,
            clipBehavior: clipBehavior,
            child: _MaybeBlurWidget(
              sigma: sigma,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: radius,
                  border: off ? Border.all(color: p.surfaceBorder) : null,
                ),
                child: Stack(
                  children: [
                    // CSS inset 0 1px 1px rgba(255,255,255,.1)：顶部一道内高光
                    if (!off)
                      Positioned(
                        top: 0,
                        left: borderRadius,
                        right: borderRadius,
                        child: Container(
                          height: 1,
                          color: insetColor ?? const Color(0x1AFFFFFF),
                        ),
                      ),
                    Padding(padding: padding, child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// anyu 风格的展开列表：替换 Flutter 默认的白色 PopupMenu
Future<T?> showGlassMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  T? initialValue,

  /// 深色玻璃面板：播放器这类深色界面的菜单，让白色文字保持可读
  bool dark = false,
  // 与 showMenu 签名兼容，这里不参与布局
  bool requestFocus = true,
}) {
  return Navigator.of(context).push<T>(
    _GlassMenuRoute<T>(
      position: position,
      items: items,
      initialValue: initialValue,
      dark: dark,
    ),
  );
}

class _GlassMenuRoute<T> extends PopupRoute<T> {
  _GlassMenuRoute({
    required this.position,
    required this.items,
    this.initialValue,
    this.dark = false,
  });

  final RelativeRect position;
  final List<PopupMenuEntry<T>> items;
  final T? initialValue;
  final bool dark;

  @override
  /// 与 Dialog 的 barrier 同档，列表出现时背景同样变灰
  Color? get barrierColor => const Color(0x8A000000);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 140);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    // 靠近右边缘的按钮（如播放器右上角的「更多」）不能把菜单顶出屏幕
    const minMenuWidth = 160.0;
    final left = position.left.clamp(
      8.0,
      (overlay.size.width - minMenuWidth - 8).clamp(8.0, double.infinity),
    );
    final top = position.top.clamp(8.0, overlay.size.height - 120);
    final maxW = overlay.size.width - left - 8;
    final maxH = overlay.size.height - top - 8;
    return _GlassMenu<T>(
      items: items,
      initialValue: initialValue,
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      maxWidth: maxW,
      maxHeight: maxH,
      textScaler: media.textScaler,
      palette: dark ? GlassPalette.dark : null,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(curved),
        alignment: .topLeft,
        child: child,
      ),
    );
  }
}

class _GlassMenu<T> extends StatelessWidget {
  const _GlassMenu({
    required this.items,
    required this.initialValue,
    required this.position,
    required this.maxWidth,
    required this.maxHeight,
    required this.textScaler,
    this.palette,
  });

  final List<PopupMenuEntry<T>> items;
  final T? initialValue;
  final RelativeRect position;
  final double maxWidth;
  final double maxHeight;
  final TextScaler textScaler;
  final GlassPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? GlassPalette.of(context);
    final theme = Theme.of(context);
    // 菜单面板的明暗决定文字色：浅色玻璃用黑字，深色玻璃（播放器/深色主题）用白字。
    // 放在这里而不是每个 item 上，避免各调用点漏传、口径打架。
    final itemTextStyle = theme.textTheme.labelSmall!.copyWith(
      fontSize: 13,
      height: 1,
      // 高透磨砂的菜单更暗，用白字；关闭 / 原生磨砂用黑字。
      // 深色主题或显式深色面板一律白字。每次打开菜单重新求值。
      color:
          palette != null ||
              theme.brightness == Brightness.dark ||
              GlassPalette.style == GlassStyle.clear
          ? Colors.white
          : Colors.black,
    );
    final entries = <Widget>[];
    for (final item in items) {
      if (item is PopupMenuDivider) {
        entries.add(
          Divider(
            height: 9,
            thickness: 0.6,
            color: const Color(0x33FFFFFF),
          ),
        );
      } else if (item is PopupMenuItem<T>) {
        final selected = item.value == initialValue;
        entries.add(
          _GlassMenuItem<T>(
            item: item,
            selected: selected,
            palette: p,
            textStyle: itemTextStyle,
          ),
        );
      }
    }
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: .opaque,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        Positioned(
          left: position.left,
          top: position.top,
          child: GlassSurface(
            borderRadius: 14,
            palette: palette,
            surfaceColor: null,
            shadowColor: GlassPalette.anyuShadow,
            padding: const EdgeInsets.all(5),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 132,
                maxWidth: maxWidth.clamp(150, 300),
                maxHeight: maxHeight.clamp(100, 480),
              ),
              child: SingleChildScrollView(
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .stretch,
                    children: entries,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassMenuItem<T> extends StatefulWidget {
  const _GlassMenuItem({
    required this.item,
    required this.selected,
    required this.palette,
    required this.textStyle,
  });

  final PopupMenuItem<T> item;
  final bool selected;
  final GlassPalette palette;
  final TextStyle textStyle;

  @override
  State<_GlassMenuItem<T>> createState() => _GlassMenuItemState<T>();
}

class _GlassMenuItemState<T> extends State<_GlassMenuItem<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final bg = widget.selected
        ? p.itemBgHover
        : (_hover ? p.itemBg : Colors.transparent);
    final enabled = widget.item.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: .opaque,
        onTap: enabled
            ? () {
                final item = widget.item;
                Navigator.of(context).pop(item.value);
                // PopupMenuItem 自带的 onTap 在 pop 之后执行，不能丢
                item.onTap?.call();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          // anyu .row-menu button 是 height:28px，PopupMenuItem 默认 48 会撑大菜单
          constraints: const BoxConstraints.tightFor(height: 38),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DefaultTextStyle.merge(
            style: widget.textStyle,
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: widget.item.child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 全局磨砂玻璃弹窗：与 [AlertDialog] 参数一一对应，
/// 只是把不透明的 Material 换成磨砂玻璃面板（背景在面板内被模糊）。
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.titlePadding,
    this.titleTextStyle,
    this.content,
    this.contentPadding,
    this.contentTextStyle,
    this.actions,
    this.actionsPadding,
    this.actionsAlignment,
    this.buttonPadding,
    this.insetPadding,
    this.clipBehavior,
    this.alignment,
    this.constraints,
    this.scrollable = false,
  });

  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final Widget? content;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? contentTextStyle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final EdgeInsetsGeometry? buttonPadding;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDirection = Directionality.maybeOf(context);
    final m3 = theme.useMaterial3;

    final titleWidget = title == null
        ? null
        : Padding(
            padding:
                (titlePadding ??
                        EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          content == null ? 24 : 16,
                        ))
                    .resolve(textDirection)!,
            child: DefaultTextStyle(
              style:
                  titleTextStyle ??
                  (m3
                      ? theme.textTheme.headlineSmall!
                      : theme.textTheme.titleMedium!),
              child: title!,
            ),
          );

    Widget? contentWidget = content;
    if (contentWidget != null) {
      contentWidget = Padding(
        padding: (contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24))
            .resolve(textDirection)!,
        child: DefaultTextStyle(
          style: contentTextStyle ?? theme.textTheme.bodyMedium!,
          child: scrollable
              ? SingleChildScrollView(child: contentWidget)
              : contentWidget,
        ),
      );
    }

    final actionsWidget = actions == null
        ? null
        : Padding(
            padding:
                (actionsPadding ?? const EdgeInsets.fromLTRB(24, 8, 24, 24))
                    .resolve(textDirection)!,
            child: OverflowBar(
              alignment: actionsAlignment ?? MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: actions!,
            ),
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      // Dialog 默认 M3 圆角是 28：Clip.hardEdge 会把半径 16 的环在四个转角处剪掉
      // （只切到角落，直线段还在，所以看起来像「白边被截断」）。形状对齐 + 不外裁。
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.none,
      alignment: alignment,
      // 用 Dialog 的居中/内边距，但卡片本身换成磨砂玻璃，并用 IntrinsicWidth
      // 保证宽度贴合内容（AlertDialog 也是这么做的）。
      constraints: constraints ?? const BoxConstraints(minWidth: 280),
      child: GlassSurface(
        borderRadius: 16,
        palette: null,
        surfaceColor: null,
        boxShadow: GlassPalette.anyuCardShadow,
        insetColor: GlassPalette.anyuCardInset,
        blurSigma: GlassPalette.menuBlur,
        child: ConstrainedBox(
          // 宽度贴合内容但有下限，避免输入框等宽松子节点把内容挤在左边
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (titleWidget != null) titleWidget,
                if (contentWidget != null) contentWidget,
                if (actionsWidget != null) actionsWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// anyu `.liquid-glass::before` 的渐变描边：
/// `padding:1.4px` + `linear-gradient(180deg, .45 → .15 → 0 → 0 → .15 → .45)`
/// 用 mask 只留环 —— Flutter 里直接沿圆角矩形画 1.4px 渐变描边即可。
class LiquidEdgePainter extends CustomPainter {
  const LiquidEdgePainter(this.radius);

  final double radius;

  static const _edge = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    // 严格照抄 anyu：.45 → .15 → 0 → 0 → .15 → .45
    colors: [
      Color(0x73FFFFFF),
      Color(0x26FFFFFF),
      Color(0x00FFFFFF),
      Color(0x00FFFFFF),
      Color(0x26FFFFFF),
      Color(0x73FFFFFF),
    ],
    stops: [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    const width = 1.4;
    final rect = Offset.zero & size;
    // 贴合卡片边缘画整圈（含四角圆弧）；Dialog 的默认 28 圆角裁切已在
    // GlassAlertDialog 里对齐掉，否则转角处的弧会被剪断。
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius - 1),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = _edge.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant LiquidEdgePainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// 磨砂玻璃版 [PopupMenuButton]：接口保持兼容（color / requestFocus 忽略），
/// 菜单本体走 [showGlassMenu]。
class GlassPopupMenuButton<T> extends StatelessWidget {
  const GlassPopupMenuButton({
    super.key,
    this.initialValue,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip,
    this.child,
    this.icon,
    this.iconSize,
    this.padding,
    this.enabled = true,
    this.dark = false,
    // 兼容 PopupMenuButton 的参数，磨砂玻璃菜单不使用
    this.color,
    this.requestFocus = false,
  });

  final T? initialValue;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;
  final Widget? child;
  final Widget? icon;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  /// 深色玻璃面板（播放器使用）
  final bool dark;
  final Color? color;
  final bool requestFocus;

  @override
  Widget build(BuildContext context) {
    final content =
        child ??
        IconTheme.merge(
          data: IconThemeData(size: iconSize),
          child: icon ?? const SizedBox.shrink(),
        );
    final button = Builder(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () async {
                final box = ctx.findRenderObject() as RenderBox?;
                final anchor = box == null
                    ? Offset.zero
                    : box.localToGlobal(box.size.bottomLeft(Offset.zero));
                final value = await showGlassMenu<T>(
                  context: ctx,
                  position: PageUtils.menuPosition(anchor),
                  initialValue: initialValue,
                  items: itemBuilder(ctx),
                  dark: dark,
                );
                if (value != null) {
                  onSelected?.call(value);
                }
              }
            : null,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: content,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
