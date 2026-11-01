import 'package:PiliPure/models/common/enum_with_label.dart';

/// 悬浮底栏收起成头像胶囊后的水平位置
enum CollapsedNavAlign with EnumWithLabel {
  left('居左'),
  center('居中'),
  right('居右');

  const CollapsedNavAlign(this.label);

  @override
  final String label;
}
