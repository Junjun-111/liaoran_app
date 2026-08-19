import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 内容页统一头部：标题 + 副标题
///
/// 顶部位置与首页 [HomePage] 完全一致：
/// - 小米岛屏（topInset > 36）时固定用 24 + 30 = 54dp
/// - 普通屏用 topInset + 30
/// - 必须放在 `Align(alignment: Alignment.topCenter)` 内，
///   不能用 `Center`（Center 会垂直居中导致顶部 padding 失效）
///
/// 标题 25px / 800 / SchibstedGrotesk；副标题默认 14px / 800 / #475569（pageSubtitle）。
/// 首页副标题是 400 字重（tagline），可通过 [subtitleStyle] 覆盖。
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleStyle = AppTextStyles.pageSubtitle,
    this.titleStyle = AppTextStyles.brandTitle,
  });

  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// 计算头部顶部 padding（与首页一致）
  static double headerTopFor(double topInset) {
    const double statusBarRowBottom = 24;
    return (topInset > 36 ? statusBarRowBottom : topInset) + 30;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final headerTop = headerTopFor(topInset);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, headerTop, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: subtitleStyle),
        ],
      ),
    );
  }
}
