import 'dart:io';

import 'package:PiliPure/common/style.dart';
import 'package:PiliPure/common/widgets/floating_navigation_bar.dart';
import 'package:PiliPure/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPure/common/widgets/image/network_img_layer.dart';
import 'package:PiliPure/common/widgets/main_layout.dart';
import 'package:PiliPure/common/widgets/route_aware_mixin.dart';
import 'package:PiliPure/models/common/nav_bar_config.dart';
import 'package:PiliPure/pages/home/view.dart';
import 'package:PiliPure/pages/main/controller.dart';
import 'package:PiliPure/models/common/collapsed_nav_align.dart';
import 'package:PiliPure/common/widgets/glass.dart';
import 'package:PiliPure/pages/main/glass_nav_bar.dart';
import 'package:PiliPure/utils/android/bindings.g.dart';
import 'package:PiliPure/utils/app_scheme.dart';
import 'package:PiliPure/utils/desktop/tray_controller.dart';
import 'package:PiliPure/utils/desktop/window_controller.dart';
import 'package:PiliPure/utils/extension/context_ext.dart';
import 'package:PiliPure/utils/extension/size_ext.dart';
import 'package:PiliPure/utils/extension/theme_ext.dart';
import 'package:PiliPure/utils/mobile_observer.dart';
import 'package:PiliPure/utils/platform_utils.dart';
import 'package:PiliPure/utils/storage.dart';
import 'package:PiliPure/utils/storage_pref.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends PopScopeState<MainApp>
    with RouteAware, RouteAwareMixin, WidgetsBindingObserver {
  final _mainController = Get.put(MainController());
  late EdgeInsets _padding;
  late ColorScheme _colorScheme;
  Brightness? _brightness;

  @override
  bool get initCanPop => false;

  @override
  void initState() {
    super.initState();
    addObserverMobile(this);
    if (Platform.isMacOS) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
    if (PlatformUtils.isDesktop) {
      WindowController.instance.init();
      TrayController.instance.init();
    }
    if (!Platform.isMacOS) {
      PiliScheme.init();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _padding = MediaQuery.viewPaddingOf(context);
    _colorScheme = ColorScheme.of(context);
    final brightness = _colorScheme.brightness;
    NetworkImgLayer.reduce =
        NetworkImgLayer.reduceLuxColor != null && brightness.isDark;
    if (PlatformUtils.isDesktop) {
      if (_brightness != brightness) {
        _brightness = brightness;
        nativeapi.Application.instance.setBrightness(
          brightness == .dark ? .dark : .light,
        );
      }
    }
    if (!_mainController.useSideBar) {
      _mainController.useBottomNav = MediaQuery.sizeOf(context).isPortrait;
    }
  }

  @override
  void didPopNext() {
    addObserverMobile(this);
    _mainController
      ..checkUnreadDynamic()
      ..checkDefaultSearch(true)
      ..checkUnread(_mainController.useBottomNav);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mainController
        ..checkUnreadDynamic()
        ..checkDefaultSearch(true)
        ..checkUnread(_mainController.useBottomNav);
    }
  }

  @override
  void dispose() {
    if (Platform.isMacOS) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    if (PlatformUtils.isDesktop) {
      WindowController.instance.dispose();
      TrayController.instance.dispose();
    }
    removeObserverMobile(this);
    PiliScheme.listener?.cancel();
    GStorage.close();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    return event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyR &&
        HardwareKeyboard.instance.isMetaPressed &&
        _mainController.refreshRecommendations();
  }

  @pragma('vm:prefer-inline')
  static void _onBack() {
    if (Platform.isAndroid) {
      AndroidHelper.back();
    }
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (_mainController.directExitOnBack) {
      _onBack();
    } else {
      if (_mainController.selectedIndex.value != 0) {
        _mainController
          ..setIndex(0)
          ..barOffset?.value = 0.0
          ..showBottomBar?.value = true
          ..setSearchBar();
      } else {
        _onBack();
      }
    }
  }

  /// 普通底栏（非悬浮）也跟随磨砂玻璃样式：透明底 + 一层 GlassSurface
  Widget _glassBottomNav(Widget bar) => GlassSurface(
    borderRadius: 0,
    // 磨砂开启时无缝，关闭时留一条淡灰边（与顶栏一致）
    border: GlassPalette.style == GlassStyle.off,
    shadow: false,
    child: bar,
  );

  Widget? get _bottomNav {
    Widget? bottomNav;
    if (_mainController.navigationBars.length > 1) {
      if (_mainController.floatingNavBar) {
        final barOffset = _mainController.barOffset;
        final showBottomBar = _mainController.showBottomBar;
        bottomNav = Obx(() {
          final double collapse = barOffset != null
              ? (barOffset.value / Style.topBarHeight).clamp(0.0, 1.0)
              : (showBottomBar?.value ?? true)
              ? 0.0
              : 1.0;
          return GlassFloatingNavBar(
            onDestinationSelected: _mainController.setIndex,
            selectedIndex: _mainController.selectedIndex.value,
            collapse: collapse,
            avatar: _glassBarAvatar(),
            onCollapsedTap: () {
              barOffset?.value = 0.0;
              showBottomBar?.value = true;
            },
            showLabel: Pref.floatingNavBarLabel,
            collapsedAlign: switch (Pref.floatingNavBarAlign) {
              CollapsedNavAlign.left => Alignment.centerLeft,
              CollapsedNavAlign.center => Alignment.center,
              CollapsedNavAlign.right => Alignment.centerRight,
            },
            destinations: _mainController.navigationBars
                .map(
                  (e) => FloatingNavigationDestination(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    selectedIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          );
        });
      } else if (_mainController.enableMYBar) {
        bottomNav = Obx(
          () => _glassBottomNav(
            NavigationBar(
              maintainBottomViewPadding: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: _mainController.setIndex,
            selectedIndex: _mainController.selectedIndex.value,
              destinations: _mainController.navigationBars
                  .map(
                    (e) => NavigationDestination(
                      label: e.label,
                      icon: _buildIcon(type: e),
                      selectedIcon: _buildIcon(type: e, selected: true),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      } else {
        bottomNav = Obx(
          () => _glassBottomNav(
            BottomNavigationBar(
              currentIndex: _mainController.selectedIndex.value,
              backgroundColor: Colors.transparent,
              elevation: 0,
            onTap: _mainController.setIndex,
            iconSize: 16,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: .fixed,
              items: _mainController.navigationBars
                  .map(
                    (e) => BottomNavigationBarItem(
                      label: e.label,
                      icon: _buildIcon(type: e),
                      activeIcon: _buildIcon(type: e, selected: true),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }

      // 悬浮底栏由 GlassFloatingNavBar 自行处理收起（向中间收拢成头像），
      // 因此不再整体滑出屏幕
      if (_mainController.hideBottomBar && !_mainController.floatingNavBar) {
        if (_mainController.barOffset case final barOffset?) {
          return Obx(
            () => FractionalTranslation(
              translation: Offset(
                0.0,
                barOffset.value / Style.topBarHeight,
              ),
              child: bottomNav,
            ),
          );
        }
        if (_mainController.showBottomBar case final showBottomBar?) {
          return Obx(
            () => AnimatedSlide(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              offset: Offset(0, showBottomBar.value ? 0 : 1),
              child: bottomNav,
            ),
          );
        }
      }
    }

    return bottomNav;
  }

  Widget _sideBar() {
    if (_mainController.navigationBars.length > 1) {
      if (context.isTablet && _mainController.optTabletNav) {
        return Padding(
          padding: const .only(top: 25),
          child: MediaQuery.removePadding(
            context: context,
            removeRight: true,
            child: Obx(
              () => DrawerTheme(
                data: DrawerThemeData(
                  width:
                      (_mainController.hideSideBarLabel ? 80 : 130) +
                      _padding.left,
                ),
                child: NavigationDrawer(
                  /// apply `lib/scripts/navigation_drawer.patch`
                  flex: 5,
                  backgroundColor: Colors.transparent,
                  onDestinationSelected: _mainController.setIndex,
                  selectedIndex: _mainController.selectedIndex.value,
                  header: Expanded(flex: 4, child: userAndSearchVertical()),
                  tilePadding: const .symmetric(vertical: 5, horizontal: 12),
                  indicatorShape: _mainController.hideSideBarLabel
                      ? const RoundedRectangleBorder(
                          borderRadius: .all(.circular(12)),
                        )
                      : const RoundedRectangleBorder(
                          borderRadius: .all(.circular(16)),
                        ),
                  children: _mainController.navigationBars
                      .map(
                        (e) => NavigationDrawerDestination(
                          label: _mainController.hideSideBarLabel
                              ? Semantics(
                                  label: e.label,
                                  child: const SizedBox.shrink(),
                                )
                              : Text(e.label),
                          icon: _buildIcon(type: e),
                          selectedIcon: _buildIcon(
                            type: e,
                            selected: true,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        );
      }
      return Obx(
        () => NavigationRail(
          groupAlignment: 0.5,
          labelType: _mainController.hideSideBarLabel ? .none : .selected,
          leading: userAndSearchVertical(),
          backgroundColor: Colors.transparent,
          onDestinationSelected: _mainController.setIndex,
          selectedIndex: _mainController.selectedIndex.value,
          destinations: _mainController.navigationBars
              .map(
                (e) => NavigationRailDestination(
                  label: Text(e.label),
                  icon: _buildIcon(type: e),
                  selectedIcon: _buildIcon(type: e, selected: true),
                ),
              )
              .toList(),
        ),
      );
    }
    return Container(
      width: 80,
      margin: .only(top: 12 + _padding.top, left: _padding.left),
      child: userAndSearchVertical(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_mainController.mainTabBarView) {
      child = TabBarView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: _mainController.useBottomNav ? .horizontal : .vertical,
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    } else {
      child = PageView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainController.navigationBars.asMap().entries.map((e) {
          final page = e.value.page;
          if (e.key == 0) return page; // 首页自己处理状态栏内边距
          return Padding(
            padding: .only(top: _padding.top),
            child: page,
          );
        }).toList(),
      );
    }

    Widget? sideBar;
    Widget? bottomNav;
    final EdgeInsets padding;
    if (_mainController.useBottomNav) {
      bottomNav = _bottomNav;
      if (bottomNav != null) {
        bottomNav = MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: bottomNav,
        );
      }
      // 首页铺满整屏（内容可滑到状态栏/顶栏玻璃下面），其它页各自补顶部内边距
      padding = _padding.copyWith(top: 0, bottom: 0);
    } else {
      sideBar = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: _colorScheme.outline.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: _sideBar(),
      );
      padding = .only(top: _padding.top, right: _padding.right);
    }

    child = Material(
      child: MainLayout(
        sideBar: sideBar,
        bottomNav: bottomNav,
        body: Stack(
          children: [
            Padding(padding: padding, child: child),
            // 状态栏区域同样走磨砂玻璃（首页自己的顶栏已含状态栏，跳过避免双层/接缝）
            if (_padding.top > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Obx(
                    () => _mainController.selectedIndex.value == 0
                        ? const SizedBox.shrink()
                        : SizedBox(
                            height: _padding.top,
                            child: GlassSurface(
                              borderRadius: 0,
                              border: GlassPalette.style == GlassStyle.off,
                              shadow: false,
                              child: SizedBox.expand(),
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (PlatformUtils.isMobile) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: _colorScheme.brightness,
          statusBarIconBrightness: _colorScheme.brightness.reverse,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: _colorScheme.brightness.reverse,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildIcon({required NavigationBarType type, bool selected = false}) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == .dynamics
        ? Obx(
            () {
              final dynCount = _mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label: _mainController.dynamicBadgeMode == .number
                    ? Text(dynCount.toString())
                    : null,
                padding: const .symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }

  /// 磨砂底栏收起后显示的用户头像
  Widget _glassBarAvatar() {
    return Obx(() {
      final account = _mainController.accountService;
      final scheme = _colorScheme;
      if (account.isLogin.value) {
        return ClipOval(
          child: NetworkImgLayer(
            type: .avatar,
            src: account.face.value,
            width: 46,
            height: 46,
            borderRadius: BorderRadius.zero,
          ),
        );
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: .circle,
          color: scheme.primaryContainer,
        ),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: 24,
            color: scheme.onPrimaryContainer,
          ),
        ),
      );
    });
  }

  Widget userAndSearchVertical() {
    return Column(
      children: [
        userAvatar(colorScheme: _colorScheme, mainController: _mainController),
        const SizedBox(height: 8),
        msgBadge(_mainController),
        IconButton(
          tooltip: '搜索',
          icon: const Icon(
            Icons.search_outlined,
            semanticLabel: '搜索',
          ),
          onPressed: () => Get.toNamed('/search'),
        ),
      ],
    );
  }
}
