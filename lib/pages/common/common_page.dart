import 'package:bilite/common/style.dart';
import 'package:bilite/pages/home/controller.dart';
import 'package:bilite/pages/main/controller.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

abstract class CommonPageState<T extends StatefulWidget> extends State<T> {
  RxDouble? _barOffset;
  RxBool? _showTopBar;
  RxBool? _showBottomBar;
  final _mainController = Get.find<MainController>();

  bool get needsCorrection => false;

  /// 只有「快速上滑」才展开底栏，慢速上滑保持收起（对齐 TiebaPure 手感）
  // 速度单位 px/ms，约 1200 px/s
  static const double _kExpandVelocity = 1.2;
  int _lastScrollTs = 0;
  double _lastScrollPixels = 0;

  @override
  void initState() {
    super.initState();
    _barOffset = _mainController.barOffset;
    _showBottomBar = _mainController.showBottomBar;
    try {
      _showTopBar = Get.find<HomeController>().showTopBar;
    } catch (_) {}
  }

  Widget onBuild(Widget child) {
    if (_barOffset != null) {
      return NotificationListener<ScrollNotification>(
        onNotification: onNotificationType2,
        child: child,
      );
    }
    if (_showTopBar != null || _showBottomBar != null) {
      return NotificationListener<UserScrollNotification>(
        onNotification: onNotificationType1,
        child: child,
      );
    }
    return child;
  }

  bool onNotificationType1(UserScrollNotification notification) {
    if (!_mainController.useBottomNav) return false;
    if (notification.metrics.axis == .horizontal) return false;
    switch (notification.direction) {
      case .forward:
        _showTopBar?.value = true;
        _showBottomBar?.value = true;
      case .reverse:
        _showTopBar?.value = false;
        _showBottomBar?.value = false;
      case _:
    }
    return false;
  }

  void _updateOffset(double scrollDelta) {
    _barOffset!.value = clampDouble(
      _barOffset!.value + scrollDelta,
      0.0,
      Style.topBarHeight,
    );
  }

  bool onNotificationType2(ScrollNotification notification) {
    if (!_mainController.useBottomNav) return false;

    final metrics = notification.metrics;
    if (metrics.axis == .horizontal) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails == null) return false;
      final pixel = metrics.pixels;
      final scrollDelta = notification.scrollDelta ?? 0;
      if (pixel < 0.0 && scrollDelta > 0) return false;

      final nowTs = DateTime.now().microsecondsSinceEpoch;
      final dtMs = _lastScrollTs == 0 ? 0 : (nowTs - _lastScrollTs) / 1000;
      final speed = dtMs > 0 ? (pixel - _lastScrollPixels).abs() / dtMs : 0.0;
      _lastScrollTs = nowTs;
      _lastScrollPixels = pixel;

      if (scrollDelta < 0) {
        // 向上回滚：快速上滑才展开；慢速拖动保持收起
        if (pixel <= metrics.minScrollExtent + 1 ||
            speed >= _kExpandVelocity) {
          _barOffset!.value = 0.0;
        }
        return false;
      }
      if (needsCorrection) {
        final value = _barOffset!.value;
        final newValue = clampDouble(
          value + scrollDelta,
          0.0,
          Style.topBarHeight,
        );
        final offset = value - newValue;
        if (offset != 0) {
          _barOffset!.value = newValue;
          if (pixel < 0.0 && scrollDelta < 0.0 && value > 0.0) {
            return false;
          }
          Scrollable.of(notification.context!).position.correctBy(offset);
        }
      } else {
        _updateOffset(scrollDelta);
      }
      return false;
    }

    if (notification is OverscrollNotification) {
      _updateOffset(notification.overscroll);
      return false;
    }

    return false;
  }

  @override
  void dispose() {
    _barOffset = null;
    _showTopBar = null;
    _showBottomBar = null;
    super.dispose();
  }
}
