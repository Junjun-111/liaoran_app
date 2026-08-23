import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'background_blobs.dart';
import 'bottom_nav_bar.dart';
import 'page_header.dart';

/// 内容页通用骨架：玻璃拟态背景 + 头部(PageHeader) + 可滚动内容 + 悬浮底部导航
///
/// 头部位置与首页 [HomePage] 完全一致（共用 `PageHeader.headerTopFor` 公式）。
/// 必须使用 `Align(topCenter)`，绝不用 `Center`（Center 会垂直居中导致顶部 padding 失效）。
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.currentIndex,
    this.onNavTap,
    this.subtitleStyle = AppTextStyles.pageSubtitle,
    this.header,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final String title;
  final String subtitle;
  final Widget body;

  /// 底部导航选中项索引（0=首页 1=订阅 2=心愿 3=资产 4=我的）
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  /// 副标题样式（默认 pageSubtitle 14/800；首页可传 tagline 14/400）
  final TextStyle? subtitleStyle;

  /// 自定义头部（覆盖默认 PageHeader）。个人中心等特殊页面可传入。
  final Widget? header;

  /// body 左右内边距
  final EdgeInsetsGeometry bodyPadding;

  static const double _navBarHeight = 66;
  static const double _navBarBottomMargin = 24;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double bottomInset = mediaQuery.padding.bottom;
    final double navBarBottom = bottomInset + _navBarBottomMargin;
    final double bottomReserved = _navBarHeight + navBarBottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        // 键盘弹出时不压缩页面高度，避免把底部悬浮导航栏顶起来
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 背景渐变光斑（铺满整屏）
            // 静态背景独立成层，滚动时不再反复重绘
            const Positioned.fill(
              child: RepaintBoundary(child: BackgroundBlobs()),
            ),
            // 内容区：从顶部开始
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    Responsive.contentWidthFor(constraints.maxWidth);
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: bottomReserved),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header ??
                              PageHeader(
                                title: title,
                                subtitle: subtitle,
                                subtitleStyle: subtitleStyle,
                              ),
                          const SizedBox(height: 20),
                          Padding(padding: bodyPadding, child: body),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // 悬浮底部导航
            Positioned(
              left: 0,
              right: 0,
              bottom: navBarBottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BottomNavBar(
                  currentIndex: currentIndex,
                  onTap: onNavTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
