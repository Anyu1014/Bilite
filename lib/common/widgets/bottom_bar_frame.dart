import 'package:material_ui/material_ui.dart';

// Keep every home bottom bar in the native platform view's layout frame.
const double bottomBarHeight = 59;
const double nativeBottomBarHeight = 62;
const double bottomBarBottomGap = 8;
const double bottomBarScreenGap = 18;

double bottomBarWidth(int itemCount, {required bool showLabel}) =>
    itemCount * (showLabel ? 86.0 : 88.0);

class BottomBarFrame extends StatelessWidget {
  const BottomBarFrame({
    super.key,
    required this.width,
    required this.child,
    this.offsetX = 0,
    this.bottomGap = bottomBarBottomGap,
    this.height = bottomBarHeight,
  });

  final double width;
  final Widget child;
  final double offsetX;
  final double bottomGap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final mirrorHomeIndicator =
        Theme.of(context).platform == TargetPlatform.iOS &&
        padding.bottom > 0 &&
        bottomGap == bottomBarBottomGap;
    // shortcut: assumes a 5pt Home indicator with 8pt bottom clearance; recalibrate if system geometry changes.
    final bottomInset = mirrorHomeIndicator
        ? 5 + 2 * bottomGap
        : bottomGap + padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        0,
        padding.right,
        bottomInset,
      ),
      child: SizedBox(
        height: height,
        child: Align(
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: SizedBox(
              width: width,
              height: height,
              // The outer frame already handles these safe-area insets.
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                removeBottom: true,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
