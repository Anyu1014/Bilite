import 'dart:io';

import 'package:bilite/common/widgets/floating_navigation_bar.dart';
import 'package:bilite/pages/main/glass_nav_bar.dart';
import 'package:bilite/pages/main/native_bottom_bar.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capability = MethodChannel('bilite/native_bottom_bar');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  final creates = <Map<Object?, Object?>>[];
  final updates = <Map<Object?, Object?>>[];
  int? selected;
  int expanded = 0;
  const items = [
    {'id': 'mine', 'label': '我的'},
    {'id': 'dynamics', 'label': '动态', 'badge': '12'},
    {'id': 'home', 'label': '首页'},
  ];

  setUpAll(() async {
    final cache = await Directory('../.cache').absolute.create(recursive: true);
    directory = await cache.createTemp('native-bottom-bar-');
    Hive.init(directory.path);
    GStorage.setting = await Hive.openBox('setting');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    creates.clear();
    updates.clear();
    selected = null;
    expanded = 0;
    await GStorage.setting.clear();
    messenger.setMockMethodCallHandler(capability, (_) async => true);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<Object?, Object?>;
        creates.add(args);
        messenger.setMockMethodCallHandler(
          MethodChannel('bilite/native_bottom_bar/${args['id']}'),
          (call) async {
            if (call.method == 'update') {
              updates.add(call.arguments as Map<Object?, Object?>);
            }
            return null;
          },
        );
      }
      return null;
    });
  });
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(capability, null)
      ..setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final args in creates) {
      messenger.setMockMethodCallHandler(
        MethodChannel('bilite/native_bottom_bar/${args['id']}'),
        null,
      );
    }
  });

  Widget bar({
    double collapse = 0,
    bool labels = false,
    Alignment align = Alignment.center,
    bool native = true,
  }) => MaterialApp(
    home: Scaffold(
      bottomNavigationBar: GlassFloatingNavBar(
        selectedIndex: 1,
        destinations: [
          for (final item in items)
            FloatingNavigationDestination(
              icon: const Icon(Icons.home),
              label: item['label']!,
            ),
        ],
        nativeItems: native ? items : null,
        onDestinationSelected: (value) => selected = value,
        avatar: const SizedBox(key: ValueKey('account-avatar')),
        onCollapsedTap: () => expanded++,
        collapse: collapse,
        showLabel: labels,
        collapsedAlign: align,
      ),
    ),
  );

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'system view preserves tab order, badges, labels and selection callbacks',
    (tester) async {
      await pump(tester, bar());
      expect(find.byType(UiKitView), findsOneWidget);
      expect(creates, hasLength(1));
      expect(updates.last['items'], items);
      expect(updates.last['selectedIndex'], 1);
      expect(updates.last['showLabel'], false);
      final id = creates.single['id'];
      Future<void> select(Object index) async {
        await messenger.handlePlatformMessage(
          'bilite/native_bottom_bar/$id',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('select', index),
          ),
          (_) {},
        );
      }

      await select(2);
      expect(selected, 2);
      await select(-1);
      await select(3);
      expect(selected, 2);
      await pump(tester, bar(labels: true));
      expect(creates, hasLength(1));
      expect(updates.last['showLabel'], true);
      expect(updates.last['expandedWidth'], 258);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'same collapse geometry, account avatar and tap-to-expand rules',
    (tester) async {
      await pump(tester, bar());
      final expandedRect = tester.getRect(find.byType(UiKitView));
      expect(expandedRect.width, 800);
      expect(expandedRect.height, 62);
      await pump(tester, bar(collapse: 1, align: Alignment.centerRight));
      final collapsedRect = tester.getRect(find.byType(UiKitView));
      expect(collapsedRect, expandedRect);
      final avatarRect = tester.getRect(
        find.byKey(const ValueKey('account-avatar')),
      );
      expect(avatarRect.center.dy, expandedRect.center.dy);
      expect(avatarRect.center.dx, 800 - 18 - 31);
      expect(updates.last['compactOffset'], 800 / 2 - 18 - 31);
      expect(updates.last['collapse'], 1);
      expect(find.byKey(const ValueKey('account-avatar')), findsOneWidget);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('account-avatar'))),
      );
      expect(expanded, 1);
      expect(selected, isNull);
      expect(creates, hasLength(1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('old iOS and explicit opt-out retain the existing Flutter bar', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(capability, (_) async => false);
    await pump(tester, bar(labels: true));
    expect(find.byType(UiKitView), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    await tester.tap(find.text('首页'));
    expect(selected, 2);
    await pump(tester, bar(native: false));
    expect(find.byType(NativeBottomBarSurface), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
    'animation keeps the native frame and avatar centerline fixed',
    (tester) async {
      await pump(tester, bar());
      final frame = tester.getRect(find.byType(UiKitView));
      for (final target in [1.0, 0.0]) {
        await tester.pumpWidget(
          bar(collapse: target, align: Alignment.centerLeft),
        );
        for (var step = 0; step < 7; step++) {
          await tester.pump(const Duration(milliseconds: 70));
          expect(tester.getRect(find.byType(UiKitView)), frame);
          final avatar = tester.getRect(
            find.byKey(const ValueKey('account-avatar')),
          );
          expect(avatar.center.dy, closeTo(frame.center.dy, 0.001));
          expect(tester.takeException(), isNull);
        }
        expect(updates.last['collapse'], target);
      }
      expect(creates, hasLength(1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'theme updates do not recreate native view or change global glass',
    (tester) async {
      await tester.runAsync(
        () => GStorage.setting.put(SettingBoxKey.floatingNavBarStyle, 1),
      );
      await pump(tester, bar());
      final tint = updates.last['tint'];
      await tester.runAsync(
        () => GStorage.setting.put(
          SettingBoxKey.floatingNavBarFollowTheme,
          false,
        ),
      );
      await pump(tester, bar());
      expect(updates.last['tint'], isNot(tint));
      expect(updates.last['unselectedTint'], updates.last['tint']);
      expect(GStorage.setting.get(SettingBoxKey.floatingNavBarStyle), 1);
      expect(creates, hasLength(1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
