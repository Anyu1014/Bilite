import 'dart:io';

import 'package:bilite/build_config.dart';
import 'package:bilite/common/constants.dart';
import 'package:bilite/common/widgets/back_detector.dart';
import 'package:bilite/common/widgets/custom_toast.dart';
import 'package:bilite/common/widgets/route_aware_mixin.dart';
import 'package:bilite/common/widgets/scale_app.dart';
import 'package:bilite/common/widgets/scroll_behavior.dart';
import 'package:bilite/http/init.dart';
import 'package:bilite/models/common/theme/theme_color_type.dart';
import 'package:bilite/plugin/pl_player/utils/fullscreen.dart';
import 'package:bilite/router/app_pages.dart';
import 'package:bilite/services/account_service.dart';
import 'package:bilite/services/download/download_service.dart';
import 'package:bilite/services/logger.dart';
import 'package:bilite/services/service_locator.dart';
import 'package:bilite/utils/cache_manager.dart';
import 'package:bilite/utils/date_utils.dart';
import 'package:bilite/utils/desktop/calc_window_position.dart';
import 'package:bilite/utils/device_utils.dart';
import 'package:bilite/utils/extension/core_palettes_ext.dart';
import 'package:bilite/utils/extension/theme_ext.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart' show FlexSchemeVariant;
import 'package:bilite/utils/font_utils.dart';
import 'package:bilite/utils/ios/pip_helper.dart';
import 'package:bilite/utils/json_file_handler.dart';
import 'package:bilite/utils/max_screen_size.dart';
import 'package:bilite/utils/path_utils.dart';
import 'package:bilite/utils/platform_utils.dart';
import 'package:bilite/utils/request_utils.dart';
import 'package:bilite/utils/storage.dart';
import 'package:bilite/utils/storage_key.dart';
import 'package:bilite/utils/storage_pref.dart';
import 'package:bilite/utils/theme_utils.dart';
import 'package:bilite/utils/utils.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';
import 'package:window_manager/window_manager.dart';

WebViewEnvironment? webViewEnvironment;

EdgeInsets? tmpPadding;

Future<void> _initDownPath() async {
  if (PlatformUtils.isDesktop) {
    final customDownPath = Pref.downloadPath;
    if (customDownPath != null && customDownPath.isNotEmpty) {
      try {
        final dir = Directory(customDownPath);
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        downloadPath = customDownPath;
      } catch (e) {
        downloadPath = defDownloadPath;
        await GStorage.setting.delete(SettingBoxKey.downloadPath);
        if (kDebugMode) {
          debugPrint('download path error: $e');
        }
      }
    } else {
      downloadPath = defDownloadPath;
    }
  } else if (Platform.isAndroid) {
    final externalStorageDirPath = (await getExternalStorageDirectory())?.path;
    downloadPath = externalStorageDirPath != null
        ? path.join(externalStorageDirPath, PathUtils.downloadDir)
        : defDownloadPath;
  } else {
    downloadPath = defDownloadPath;
  }
}

Future<void> _initTmpPath() async {
  tmpDirPath = (await getTemporaryDirectory()).path;
}

Future<void> _initAppPath() async {
  appSupportDirPath = (await getApplicationSupportDirectory()).path;
}

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await _initAppPath();
  try {
    await GStorage.init();
  } catch (e) {
    await Utils.copyText(e.toString(), needToast: false);
    if (kDebugMode) debugPrint('GStorage init error: $e');
    DeviceUtils.exitApp();
  }
  ScaledWidgetsFlutterBinding.instance.scaleFactor = Pref.uiScale;
  await Future.wait([
    _initDownPath(),
    _initTmpPath(),
    CacheManager.ensureInitialized(),
    ?FontUtils.init(),
  ]);
  Get
    ..lazyPut(AccountService.new)
    ..lazyPut(DownloadService.new);
  HttpOverrides.global = _CustomHttpOverrides();

  if (PlatformUtils.isMobile) {
    if (Platform.isAndroid) MaxScreenSize.init();
    await Future.wait([
      if (Pref.horizontalScreen) ?fullMode() else ?portraitUpMode(),
      setupServiceLocator(),
      if (Platform.isIOS) IOSPipHelper.init(),
    ]);
  } else if (Platform.isWindows) {
    if (await WebViewEnvironment.getAvailableVersion() != null) {
      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: path.join(appSupportDirPath, 'flutter_inappwebview'),
        ),
      );
    }
  } else if (Platform.isMacOS || Platform.isLinux) {
    await setupServiceLocator();
  }

  Request();
  Request.setCookie();
  RequestUtils.syncHistoryStatus();

  SmartDialog.config.toast = SmartConfigToast(displayType: .onlyRefresh);

  FocusManager.instance.addEarlyKeyEventHandler(_onKeyEvent);

  if (PlatformUtils.isMobile) {
    SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    if (Platform.isAndroid) {
      FlutterDisplayMode.supported.then((mode) {
        final String? storageDisplay = GStorage.setting.get(
          SettingBoxKey.displayMode,
        );
        DisplayMode? displayMode;
        if (storageDisplay != null) {
          displayMode = mode.firstWhereOrNull(
            (e) => e.toString() == storageDisplay,
          );
        }
        FlutterDisplayMode.setPreferredMode(displayMode ?? DisplayMode.auto);
      });
    } else {
      ScreenBrightnessPlatform.instance.setAutoReset(false);
    }
  }

  if (Pref.dynamicColor) {
    await MyApp.initPlatformState();
  }

  if (Pref.enableLog) {
    // 异常捕获 logo记录
    final customParameters = {
      'Build Time': DateFormatUtils.format(
        BuildConfig.buildTime,
        format: DateFormatUtils.longFormatDs,
      ),
      'Commit Hash': BuildConfig.commitHash,
      'MPV Api Version':
          '${NativePlayer.apiVersion >> 16}.${NativePlayer.apiVersion & 0xFFFF}',
    };
    final fileHandler = await JsonFileHandler.init();

    Catcher2(
      [?fileHandler, const ConsoleHandler()],
      const MyApp(),
      logger: logger,
      customParameters: customParameters,
    );
  } else {
    runApp(const MyApp());
  }

  if (PlatformUtils.isDesktop) {
    final window = WindowManager.instance.getCurrent();
    if (window != null) {
      window
        ..titleBarStyle = Pref.showWindowTitleBar ? .normal : .hidden
        ..isWindowControlButtonsVisible = true
        ..bounds = calcWindowBounds()
        ..minimumSize = DeviceUtils.desktopMinSize
        ..isVisibleInTaskbar = true
        ..title = Constants.appName;
      if (Pref.isWindowMaximized) window.maximize();
      void show([_]) => window
        ..focus()
        ..show();
      switch (WidgetsBinding.instance.schedulerPhase) {
        case .idle || .postFrameCallbacks:
          WidgetsBinding.instance.scheduleFrameCallback(show);
        case .transientCallbacks || .midFrameMicrotasks || .persistentCallbacks:
          WidgetsBinding.instance.addPostFrameCallback(show);
      }
    }
  }
}

KeyEventResult _onKeyEvent(KeyEvent event) {
  if (event is KeyDownEvent && event.logicalKey == .escape) {
    _onBack();
    return .handled;
  }
  return .ignored;
}

void _onBack() {
  if (SmartDialog.checkExist()) {
    SmartDialog.dismiss();
    return;
  }

  final route = Get.routing.route;
  if (route is GetPageRoute) {
    if (route.popDisposition == .doNotPop) {
      route.onPopInvokedWithResult(false, null);
      return;
    }
  }

  final navigator = Get.key.currentState!;
  if (navigator.canPop()) {
    navigator.pop();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ColorScheme? _light, _dark;

  static (ThemeData, ThemeData) getAllTheme() {
    final dynamicColor = _light != null && _dark != null && Pref.dynamicColor;

    final ColorScheme lightScheme, darkScheme;
    if (dynamicColor) {
      lightScheme = _light!;
      darkScheme = _dark!;
    } else {
      // 默认风格固定用默认亮粉 + Material-3 legacy，背景走原生纯白/纯黑
      final defaultStyle = Pref.defaultThemeStyle;
      final customColor = Pref.customColor;
      final brandColor = defaultStyle
          ? colorThemeTypes.first.color
          : colorThemeTypes.elementAtOrNull(customColor)?.color ??
                Color(customColor);
      final variant = defaultStyle
          ? FlexSchemeVariant.material3Legacy
          : Pref.schemeVariant;

      lightScheme = brandColor.asColorSchemeSeed(variant, .light);
      darkScheme = brandColor.asColorSchemeSeed(variant, .dark);
    }

    final nativeBackground =
        !dynamicColor && (Pref.isNativePaletteStyle || Pref.defaultThemeStyle);

    // 标签选中态直接用所选主题色原色（M3 派生主色偏暗，和亮粉等原色差太多）
    final rawAccent = dynamicColor
        ? null
        : Pref.defaultThemeStyle
        ? colorThemeTypes.first.color
        : colorThemeTypes.elementAtOrNull(Pref.customColor)?.color ??
              Color(Pref.customColor);

    ThemeData applyRawAccent(ThemeData theme) => rawAccent == null
        ? theme
        : theme.copyWith(
            tabBarTheme: theme.tabBarTheme.copyWith(
              labelColor: rawAccent,
              indicatorColor: rawAccent,
            ),
          );

    return (
      ThemeUtils.lightTheme = applyRawAccent(
        ThemeUtils.getThemeData(
          colorScheme: lightScheme,
          isDynamic: dynamicColor,
          nativeBackground: nativeBackground,
        ),
      ),
      ThemeUtils.darkTheme = applyRawAccent(
        ThemeUtils.getThemeData(
          isDark: true,
          colorScheme: darkScheme,
          isDynamic: dynamicColor,
          nativeBackground: nativeBackground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (light, dark) = getAllTheme();
    return GetMaterialApp(
      title: Constants.appName,
      theme: light,
      darkTheme: dark,
      themeMode: ThemeUtils.themeMode = Pref.themeMode,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: const Locale("zh", "CN"),
      fallbackLocale: const Locale("zh", "CN"),
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      initialRoute: '/',
      getPages: Routes.getPages,
      defaultTransition: Pref.pageTransition,
      builder: FlutterSmartDialog.init(
        toastBuilder: CustomToast.new,
        loadingBuilder: LoadingWidget.new,
        notifyStyle: const FlutterSmartNotifyStyle(
          warningBuilder: NotifyWarning.new,
        ),
        builder: _builder,
      ),
      navigatorObservers: [
        routeObserver,
        FlutterSmartDialog.observer,
      ],
      scrollBehavior: PlatformUtils.isDesktop
          ? const CustomScrollBehavior()
          : null,
    );
  }

  static Widget _builder(BuildContext context, Widget? child) {
    final uiScale = Pref.uiScale;
    final mediaQuery = MediaQuery.of(context);
    final textScaler = TextScaler.linear(Pref.defaultTextScale);
    if (uiScale != 1.0) {
      child = MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: textScaler,
          size: mediaQuery.size / uiScale,
          padding: tmpPadding ?? mediaQuery.padding / uiScale,
          viewInsets: mediaQuery.viewInsets / uiScale,
          viewPadding: tmpPadding ?? mediaQuery.viewPadding / uiScale,
          devicePixelRatio: mediaQuery.devicePixelRatio * uiScale,
        ),
        child: child!,
      );
    } else {
      child = MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: textScaler,
          padding: tmpPadding,
          viewPadding: tmpPadding,
        ),
        child: child!,
      );
    }
    if (PlatformUtils.isDesktop) {
      return BackDetector(
        onBack: _onBack,
        child: child,
      );
    }
    return child;
  }

  /// from [DynamicColorBuilderState.initPlatformState]
  static Future<bool> initPlatformState() async {
    if (_light != null || _dark != null) return true;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final colors = await DynamicColorPlugin.channel.invokeMethod(
        DynamicColorPlugin.methodName,
      );

      if (colors != null) {
        final corePalettes = CorePalettesExt.fromList(colors.toList());
        if (kDebugMode) {
          debugPrint('dynamic_color: Core palette detected.');
        }
        _light = corePalettes.toColorScheme();
        _dark = corePalettes.toColorScheme(brightness: Brightness.dark);
        return true;
      }
    } on PlatformException {
      if (kDebugMode) {
        debugPrint('dynamic_color: Failed to obtain core palette.');
      }
    }

    try {
      final Color? accentColor = await DynamicColorPlugin.getAccentColor();

      if (accentColor != null) {
        if (kDebugMode) {
          debugPrint('dynamic_color: Accent color detected.');
        }
        final variant = Pref.schemeVariant;
        _light = accentColor.asColorSchemeSeed(variant, .light);
        _dark = accentColor.asColorSchemeSeed(variant, .dark);
        return true;
      }
    } on PlatformException {
      if (kDebugMode) {
        debugPrint('dynamic_color: Failed to obtain accent color.');
      }
    }
    if (kDebugMode) {
      debugPrint('dynamic_color: Dynamic color not detected on this device.');
    }
    GStorage.setting.put(SettingBoxKey.dynamicColor, false);
    return false;
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // ..maxConnectionsPerHost = 32
    /// The default value is 15 seconds.
    //   ..idleTimeout = const Duration(seconds: 15);
    if (kDebugMode || Pref.badCertificateCallback) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
