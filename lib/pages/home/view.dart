import 'package:bilite/common/style.dart';
import 'package:bilite/common/widgets/custom_height_widget.dart';
import 'package:bilite/common/widgets/image/network_img_layer.dart';
import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/common/widgets/home_header_inset.dart';
import 'package:bilite/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bilite/pages/common/common_page.dart';
import 'package:bilite/pages/home/controller.dart';
import 'package:bilite/pages/main/controller.dart';
import 'package:bilite/pages/mine/controller.dart';
import 'package:bilite/utils/extension/get_ext.dart';
import 'package:bilite/utils/extension/size_ext.dart';
import 'package:bilite/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  late ColorScheme _colorScheme;
  final _homeController = Get.putOrFind(HomeController.new);
  final _mainController = Get.find<MainController>();

  @override
  bool get needsCorrection => _homeController.hideTopBar;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget tabBar;
    if (_homeController.tabs.length > 1) {
      tabBar = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 42,
          width: double.infinity,
          child: TabBar(
            controller: _homeController.tabController,
            tabs: _homeController.tabs.map((e) => Tab(text: e.label)).toList(),
            isScrollable: true,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            splashBorderRadius: Style.mdRadius,
            tabAlignment: TabAlignment.center,
            onTap: (_) {
              feedBack();
              if (!_homeController.tabController.indexIsChanging) {
                _homeController.animateToTop();
              }
            },
          ),
        ),
      );
      if (_homeController.hideTopBar &&
          _mainController.barHideType == .instant) {
        tabBar = Material(
          color: _colorScheme.surface,
          child: tabBar,
        );
      }
    } else {
      tabBar = const SizedBox(height: 6);
    }
    final showAppBar =
        !_mainController.useSideBar && MediaQuery.sizeOf(context).isPortrait;
    final mq = MediaQuery.of(context);
    // 顶栏覆盖层：内容在它下面滚动，玻璃模糊才有对象
    // 首页现在铺满整屏（含状态栏），内容要自己让出状态栏 + 顶栏高度
    final tabsInset = _homeController.tabs.length > 1 ? 46.0 : 6.0;
    final header = GlassSurface(
      borderRadius: 0,
      // 磨砂开启时保持无缝；关闭后给纯色块一条淡灰边
      border: GlassPalette.style == GlassStyle.off,
      shadow: false,
      child: Column(
        children: [
          SizedBox(height: mq.padding.top),
          if (showAppBar) customAppBar(),
          tabBar,
        ],
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          // 留白 = 顶栏当前实际高度：顶栏收起（滚动隐藏搜索行）时,
          // 内容跟着缩进到标签栏下沿，不会在中段空出一条。
          // 动画时长与 customAppBar 的 AnimatedSize 一致，避免跳变。
          child: Obx(() {
            final hidden = _mainController.barOffset != null
                ? _mainController.barOffset!.value > Style.topBarHeight / 2
                : !(_homeController.showTopBar?.value ?? true);
            final target =
                mq.padding.top +
                (showAppBar && !hidden ? Style.topBarHeight : 0.0) +
                tabsInset +
                4.0; // 玻璃下沿与首行卡片留一点缝
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: target),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) =>
                  HomeHeaderInset(value: value, child: child!),
              child: onBuild(
                tabBarView(
                  controller: _homeController.tabController,
                  children: _homeController.tabs.map((e) => e.page).toList(),
                ),
              ),
            );
          }),
        ),
        Positioned(top: 0, left: 0, right: 0, child: header),
      ],
    );
  }

  Widget customAppBar() {
    const padding = EdgeInsets.fromLTRB(14, 6, 14, 0);
    final child = Row(
      children: [
        searchBar(),
        const SizedBox(width: 4),
        msgBadge(_mainController),
        const SizedBox(width: 8),
        userAvatar(colorScheme: _colorScheme, mainController: _mainController),
      ],
    );
    final content = Padding(padding: padding, child: child);
    if (_homeController.hideTopBar) {
      final barOffset = _mainController.barOffset;
      final showTopBar = _homeController.showTopBar;
      return Obx(() {
        // 用「是否越过一半」做阈值，配合隐式动画 = 自然的淡出上移，而不是跟着滚动一点点往上压
        final hidden = barOffset != null
            ? barOffset.value > Style.topBarHeight / 2
            : !(showTopBar?.value ?? true);
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: hidden ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: hidden ? const Offset(0, -0.35) : Offset.zero,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: hidden
                  ? const SizedBox(width: double.infinity)
                  : SizedBox(height: Style.topBarHeight, child: content),
            ),
          ),
        );
      });
    }
    return SizedBox(height: Style.topBarHeight, child: content);
  }

  Widget searchBar() {
    const radius = 25.0;
    const borderRadius = BorderRadius.all(Radius.circular(radius));
    // 搜索框沿用 anyu 的标准磨砂玻璃（GlassSurface：底色 + 渐变玻璃环 + 顶部内高光），
    // 与展开列表、弹窗同一套观感；关闭磨砂时它自己回退成纯色面板。
    return Expanded(
      child: SizedBox(
        height: 44,
        child: GlassSurface(
          borderRadius: radius,
          shadow: false,
          // 只借它的边缘（1.4px 渐变环 + 顶部 1px 内高光），
          // 底色仍用原来的淡灰填充，避免搜索框在白底顶栏上整块消失；
          // blurSigma 0：这里不需要二次模糊，顶栏已经磨过一次。
          blurSigma: 0,
          surfaceColor: Colors.transparent,
          child: Material(
            color: _colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              splashColor: _colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              onTap: () => Get.toNamed(
                '/search',
                parameters: _homeController.enableSearchWord
                    ? {'hintText': _homeController.defaultSearch.value}
                    : null,
              ),
              child: SizedBox.expand(
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_outlined,
                      color: _colorScheme.onSecondaryContainer,
                      semanticLabel: '搜索',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => Text(
                          _homeController.defaultSearch.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _colorScheme.outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
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

Widget userAvatar({
  required ColorScheme colorScheme,
  required MainController mainController,
}) {
  return Semantics(
    label: "我的",
    child: Obx(
      () {
        if (mainController.accountService.isLogin.value) {
          return Stack(
            clipBehavior: .none,
            children: [
              NetworkImgLayer(
                type: .avatar,
                width: 34,
                height: 34,
                src: mainController.accountService.face.value,
              ),
              Positioned.fill(
                child: Material(
                  type: .transparency,
                  child: InkWell(
                    onTap: mainController.toMinePage,
                    splashColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    customBorder: const CircleBorder(),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Obx(
                  () => MineController.anonymity.value
                      ? IgnorePointer(
                          child: Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              size: 14,
                              MdiIcons.incognito,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        }
        return SizedBox(
          width: 38,
          height: 38,
          child: IconButton(
            tooltip: '点击登录',
            style: IconButton.styleFrom(
              padding: .zero,
              backgroundColor: colorScheme.onInverseSurface,
            ),
            onPressed: mainController.toMinePage,
            icon: Icon(
              Icons.person_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    ),
  );
}

Widget msgBadge(MainController mainController) {
  return Obx(
    () {
      if (mainController.accountService.isLogin.value) {
        final count = mainController.msgUnReadCount.value;
        final isNumBadge = mainController.msgBadgeMode == .number;
        return IconButton(
          tooltip: '消息',
          onPressed: () {
            mainController
              ..clearUnreadMsg()
              ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
            Get.toNamed('/whisper');
          },
          icon: Badge(
            isLabelVisible:
                mainController.msgBadgeMode != .hidden && count != null,
            alignment: isNumBadge
                ? const Alignment(0.0, -0.85)
                : const Alignment(1.0, -0.85),
            label: isNumBadge && count != null ? Text(count) : null,
            child: const Icon(Icons.notifications_none),
          ),
        );
      }
      return const SizedBox.shrink();
    },
  );
}
