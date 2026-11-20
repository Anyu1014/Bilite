import 'package:bilite/pages/setting/models/dm_settings.dart';
import 'package:bilite/pages/setting/models/dyn_settings.dart';
import 'package:bilite/pages/setting/models/extra_settings.dart';
import 'package:bilite/pages/setting/models/floating_nav_settings.dart';
import 'package:bilite/pages/setting/models/glass_style_settings.dart';
import 'package:bilite/pages/setting/models/home_tab_settings.dart';
import 'package:bilite/pages/setting/models/model.dart';
import 'package:bilite/pages/setting/models/play_settings.dart';
import 'package:bilite/pages/setting/models/privacy_settings.dart';
import 'package:bilite/pages/setting/models/recommend_settings.dart';
import 'package:bilite/pages/setting/models/reply_settings.dart';
import 'package:bilite/pages/setting/models/style_settings.dart';
import 'package:bilite/pages/setting/models/video_settings.dart';

enum SettingType {
  privacySetting('隐私设置'),
  recommendSetting('推荐流设置'),
  videoSetting('音视频设置'),
  playSetting('播放器设置'),
  dmSetting('弹幕设置'),
  replySetting('评论设置'),
  dynSetting('动态设置'),
  themeSetting('应用主题'),
  styleSetting('外观设置'),
  glassSetting('磨砂玻璃'),
  floatingNavBarSetting('悬浮底栏'),
  homeTabSetting('冷启动默认打开板块'),
  extraSetting('其它设置'),
  webdavSetting('WebDAV 设置'),
  about('关于'),
  ;

  final String title;
  const SettingType(this.title);

  List<SettingsModel> get settings => switch (this) {
    .privacySetting => privacySettings,
    .recommendSetting => recommendSettings,
    .videoSetting => videoSettings,
    .playSetting => playSettings,
    .dmSetting => dmSettings,
    .dynSetting => dynSettings,
    .replySetting => replySettings,
    .styleSetting => styleSettings,
    .glassSetting => glassSettings,
    .floatingNavBarSetting => floatingNavSettings,
    .homeTabSetting => homeTabSettings,
    .extraSetting => extraSettings,
    .themeSetting || .webdavSetting || .about => throw UnimplementedError(),
  };
}
