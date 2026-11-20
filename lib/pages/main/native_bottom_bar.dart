import 'package:bilite/common/widgets/bottom_bar_frame.dart';
import 'package:bilite/utils/bili_colors.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// UIKit owns the material, selected capsule, tab items and accessibility.
/// Flutter keeps the existing scroll progress and account avatar.
class NativeBottomBarSurface extends StatefulWidget {
  const NativeBottomBarSurface({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.showLabel,
    required this.collapse,
    required this.expandedWidth,
    required this.onDestinationSelected,
    required this.avatar,
    required this.fallback,
    this.onCollapsedTap,
    this.compactOffset = 0,
  });

  final List<Map<String, Object?>> items;
  final int selectedIndex;
  final bool showLabel;
  final double collapse;
  final double expandedWidth;
  final ValueChanged<int> onDestinationSelected;
  final Widget avatar;
  final Widget fallback;
  final VoidCallback? onCollapsedTap;
  final double compactOffset;

  @override
  State<NativeBottomBarSurface> createState() => _NativeBottomBarSurfaceState();
}

class _NativeBottomBarSurfaceState extends State<NativeBottomBarSurface> {
  static const _capabilities = MethodChannel('bilite/native_bottom_bar');
  static Future<bool> _isSupported() async {
    try {
      return await _capabilities.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  late final _supported = _isSupported();
  MethodChannel? _channel;
  Map<String, Object?>? _lastConfiguration;

  Map<String, Object?> _configuration(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return {
      'items': widget.items,
      'selectedIndex': widget.selectedIndex,
      'showLabel': widget.showLabel,
      'collapse': widget.collapse,
      'expandedWidth': widget.expandedWidth,
      'compactOffset': widget.compactOffset,
      'dark': dark,
      'unselectedTint':
          (Pref.floatingNavBarFollowTheme
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface)
              .toARGB32(),
      'tint':
          (Pref.floatingNavBarFollowTheme
                  ? (dark ? BiliColors.pinkDark : BiliColors.pinkLight)
                  : theme.colorScheme.onSurface)
              .toARGB32(),
    };
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _supported,
    builder: (context, snapshot) {
      if (snapshot.data != true) return widget.fallback;
      final configuration = _configuration(context);
      // Do not recreate the platform view during scroll or unread-count updates.
      if (_lastConfiguration != null && _channel != null) {
        _channel!.invokeMethod<void>('update', configuration);
      }
      _lastConfiguration = configuration;
      final t = widget.collapse.clamp(0.0, 1.0);
      final fade = ((t - 0.25) / 0.75).clamp(0.0, 1.0);
      final opacity = fade * fade * (3 - 2 * fade);
      return BottomBarFrame(
        width:
            MediaQuery.sizeOf(context).width -
            MediaQuery.viewPaddingOf(context).horizontal,
        height: nativeBottomBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: UiKitView(
                viewType: 'bilite/native_bottom_bar',
                creationParams: configuration,
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: (id) {
                  if (!mounted) return;
                  _channel = MethodChannel('bilite/native_bottom_bar/$id')
                    ..setMethodCallHandler((call) async {
                      if (!mounted || call.method != 'select') return;
                      final index = call.arguments;
                      if (index is int &&
                          index >= 0 &&
                          index < widget.items.length) {
                        widget.onDestinationSelected(index);
                      }
                    });
                  _channel!.invokeMethod<void>('update', _lastConfiguration);
                },
              ),
            ),
            Transform.translate(
              offset: Offset(widget.compactOffset, 0),
              child: IgnorePointer(
                ignoring: t < 0.75,
                child: GestureDetector(
                  onTap: widget.onCollapsedTap,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: 0.88 + 0.12 * t,
                      child: SizedBox(
                        width: nativeBottomBarHeight,
                        height: nativeBottomBarHeight,
                        child: Center(
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: widget.avatar,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
