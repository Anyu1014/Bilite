import 'dart:io';

import 'package:bilite/common/widgets/bottom_bar_frame.dart';
import 'package:bilite/common/widgets/floating_navigation_bar.dart';
import 'package:bilite/common/widgets/glass.dart';
import 'package:bilite/pages/main/glass_nav_bar.dart';
import 'package:bilite/pages/main/native_bottom_bar.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart' hide NavigationIndicator;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const capability = MethodChannel('bilite/native_bottom_bar');
  late Directory directory;
  int? selected;
  const allItems = [
    {'id': 'home', 'label': '首页'},
    {'id': 'dynamics', 'label': '动态'},
    {'id': 'mine', 'label': '我的'},
  ];

  setUpAll(() async {
    final cache = await Directory('../.cache').absolute.create(recursive: true);
    directory = await cache.createTemp('bottom-bar-geometry-');
    Hive.init(directory.path);
    GStorage.setting = await Hive.openBox('setting');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await GStorage.setting.clear();
    selected = null;
    messenger
      ..setMockMethodCallHandler(capability, (_) async => true)
      ..setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['id'];
          messenger.setMockMethodCallHandler(
            MethodChannel('bilite/native_bottom_bar/$id'),
            (_) async => null,
          );
        }
        return null;
      });
  });
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(capability, null)
      ..setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  Widget floating({
    bool native = false,
    bool labels = false,
    int count = 3,
    double collapse = 0,
    Alignment align = Alignment.center,
  }) => GlassFloatingNavBar(
    selectedIndex: 0,
    destinations: [
      for (final item in allItems.take(count))
        FloatingNavigationDestination(
          icon: const Icon(Icons.home),
          label: item['label']!,
        ),
    ],
    nativeItems: native ? allItems.take(count).toList() : null,
    onDestinationSelected: (index) => selected = index,
    avatar: const Icon(Icons.person),
    collapse: collapse,
    showLabel: labels,
    collapsedAlign: align,
  );

  Widget material({
    required bool modern,
    required bool labels,
    required int count,
  }) => BottomBarFrame(
    width: bottomBarWidth(count, showLabel: labels),
    child: GlassSurface(
      borderRadius: 0,
      border: GlassPalette.style == GlassStyle.off,
      shadow: false,
      child: SizedBox(
        height: bottomBarHeight,
        child: modern
            ? NavigationBar(
                height: bottomBarHeight,
                selectedIndex: 0,
                onDestinationSelected: (index) => selected = index,
                destinations: [
                  for (final item in allItems.take(count))
                    NavigationDestination(
                      icon: const Icon(Icons.home),
                      label: item['label']!,
                    ),
                ],
              )
            : BottomNavigationBar(
                currentIndex: 0,
                iconSize: 16,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,
                onTap: (index) => selected = index,
                items: [
                  for (final item in allItems.take(count))
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home),
                      label: item['label']!,
                    ),
                ],
              ),
      ),
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget bar, {
    Size size = const Size(390, 844),
    EdgeInsets safe = const EdgeInsets.only(bottom: 34),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, padding: safe, viewPadding: safe),
          child: Scaffold(bottomNavigationBar: bar),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  void resetView(WidgetTester tester) => addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'expanded Flutter surfaces retain geometry and native canvas stays full width',
    (tester) async {
      resetView(tester);
      const screens = [
        (Size(390, 844), EdgeInsets.only(bottom: 34)),
        (Size(320, 640), EdgeInsets.zero),
        (Size(844, 390), EdgeInsets.fromLTRB(44, 0, 32, 21)),
      ];
      for (final (size, safe) in screens) {
        for (final labels in [false, true]) {
          for (final count in [2, 3]) {
            await pump(
              tester,
              floating(labels: labels, count: count),
              size: size,
              safe: safe,
            );
            final reference = tester.getRect(
              find.byType(BackdropFilter).first,
            );
            expect(reference.size, Size(count * (labels ? 86 : 88), 59));
            expect(reference.bottom, size.height - (safe.bottom > 0 ? 21 : 8));
            expect(
              reference.center.dx,
              safe.left + (size.width - safe.horizontal) / 2,
            );
            await pump(
              tester,
              floating(native: true, labels: labels, count: count),
              size: size,
              safe: safe,
            );
            final native = tester.getRect(find.byType(UiKitView));
            expect(native.size, Size(size.width - safe.horizontal, 62));
            expect(native.bottom, reference.bottom);
            expect(native.center.dx, reference.center.dx);
            for (final style in GlassStyle.values) {
              await tester.runAsync(
                () => GStorage.setting.put(
                  SettingBoxKey.floatingNavBarStyle,
                  style.index,
                ),
              );
              await pump(
                tester,
                floating(labels: labels, count: count),
                size: size,
                safe: safe,
              );
              expect(
                tester.getRect(find.byType(BackdropFilter).first),
                reference,
                reason: style.label,
              );
              for (final modern in [false, true]) {
                await pump(
                  tester,
                  material(modern: modern, labels: labels, count: count),
                  size: size,
                  safe: safe,
                );
                expect(
                  tester.getRect(find.byType(GlassSurface)),
                  reference,
                  reason: "${style.label}, Material ${modern ? 3 : 2}",
                );
              }
            }
            await pump(
              tester,
              FloatingNavigationBar(
                labelBehavior: labels
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.alwaysHide,
                destinations: [
                  for (final item in allItems.take(count))
                    FloatingNavigationDestination(
                      icon: const Icon(Icons.home),
                      label: item['label']!,
                    ),
                ],
              ),
              size: size,
              safe: safe,
            );
            final surface = find
                .descendant(
                  of: find.byType(FloatingNavigationBar),
                  matching: find.byType(DecoratedBox),
                )
                .first;
            expect(tester.getRect(surface), reference);
          }
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'native collapse keeps one platform frame and avatar shares the expanded baseline',
    (tester) async {
      resetView(tester);
      for (final align in [
        Alignment.centerLeft,
        Alignment.center,
        Alignment.centerRight,
      ]) {
        for (final collapse in [0.0, 0.4, 1.0]) {
          await pump(
            tester,
            floating(native: true, collapse: collapse, align: align),
          );
          final reference = tester.getRect(find.byType(UiKitView));
          expect(reference.size, const Size(390, 62));
          expect(reference.bottom, 844 - 21);
          final avatar = tester.getRect(
            find
                .descendant(
                  of: find.byType(NativeBottomBarSurface),
                  matching: find.byType(GestureDetector),
                )
                .first,
          );
          expect(avatar.center.dy, reference.center.dy);
          final expectedX = 195 + ((390 - 62) / 2 - 18) * collapse * align.x;
          expect(avatar.center.dx, closeTo(expectedX, 0.01));
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'home-indicator gap is mirrored on iOS while Android and custom gaps stay unchanged',
    (tester) async {
      resetView(tester);
      for (final safeBottom in [0.0, 21.0, 34.0, 48.0]) {
        for (final gap in [8.0, 30.0]) {
          const key = ValueKey('bottom-gap-surface');
          await pump(
            tester,
            BottomBarFrame(
              width: 264,
              bottomGap: gap,
              child: const SizedBox(key: key),
            ),
            safe: EdgeInsets.only(bottom: safeBottom),
          );
          final context = tester.element(find.byType(BottomBarFrame));
          final ios = Theme.of(context).platform == TargetPlatform.iOS;
          final mirrored = ios && safeBottom > 0 && gap == 8;
          final bottom = tester.getRect(find.byKey(key)).bottom;
          expect(844 - bottom, mirrored ? 21 : safeBottom + gap);
          if (mirrored) {
            const indicatorBottomGap = 8.0;
            const indicatorHeight = 5.0;
            const indicatorTop = 844 - indicatorBottomGap - indicatorHeight;
            expect(indicatorTop - bottom, indicatorBottomGap);
          }
        }
      }
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'Material 2 and 3 still select pages after resizing and remove safe-area padding only once',
    (tester) async {
      resetView(tester);
      for (final modern in [false, true]) {
        selected = null;
        await pump(tester, material(modern: modern, labels: true, count: 3));
        await tester.tap(find.text('我的'));
        expect(selected, 2);
        final bar = modern
            ? find.byType(NavigationBar)
            : find.byType(BottomNavigationBar);
        final data = MediaQuery.of(tester.element(bar));
        expect(data.padding.bottom, 0);
        expect(data.viewPadding.bottom, 0);
      }
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}
