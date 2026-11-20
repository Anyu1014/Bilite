import 'dart:math' as math;

import 'package:bilite/common/assets.dart';
import 'package:material_ui/material_ui.dart';

/// 下拉刷新指示器：用 App 的 TV 图标代替系统转圈。
/// 下拉时按进度转动半圈，进入刷新后持续旋转。
class RefreshIconIndicator extends StatefulWidget {
  const RefreshIconIndicator({super.key, this.value});

  /// 下拉进度 0..1；null 表示正在刷新
  final double? value;

  @override
  State<RefreshIconIndicator> createState() => _RefreshIconIndicatorState();
}

class _RefreshIconIndicatorState extends State<RefreshIconIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant RefreshIconIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _sync();
  }

  void _sync() {
    if (widget.value == null) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface.withValues(alpha: 0.92),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, child) {
            final angle = widget.value == null
                ? _spin.value * 2 * math.pi
                : widget.value! * math.pi;
            return Transform.rotate(angle: angle, child: child);
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              Assets.loading,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
