import 'package:flutter/material.dart';

/// 了然 App 全局设计规范常量（依据 Figma 2_4 画布 440×956 移动端）。
///
/// 风格：玻璃拟态（Glassmorphism）+ 柔和渐变光斑 + 大圆角。
class AppColors {
  AppColors._();

  // 品牌主色
  static const Color primary = Color(0xFF10B981);

  // 页面背景
  static const Color background = Color(0xFFF4FAF8);

  // 文字色阶
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF64748B);

  // 背景光斑
  static const Color blobBlue = Color(0xFFBAE6FD);
  static const Color blobGreen = Color(0xFFA7F3D0);
  static const Color blobPink = Color(0xFFFBCFE8);

  // 卡片
  static const Color cardMint = Color(0x80E6FDF9); // rgba(230,253,249,0.50)
  static const Color cardWhite = Color(0xA8FFFFFF); // rgba(255,255,255,0.66)
  static const Color cardStroke = Color(0x80FFFFFF); // rgba(255,255,255,0.50)
  static const Color cardShadowPrimary = Color(0x0D0F172A); // rgba(15,23,42,0.05)
  static const Color cardShadowBlack = Color(0x0A000000); // rgba(0,0,0,0.04)

  // 空状态
  static const Color emptyIconBg = Color(0x1F55E9A7); // rgba(85,233,167,0.12)

  // 底部导航
  static const Color navSelectedBg = Color(0x1F10B981); // rgba(16,185,129,0.12)
  static const Color navSelectedStroke = Color(0x3310B981); // rgba(16,185,129,0.20)

  // 底部导航 · 右侧添加按钮（玻璃渐变）
  static const Color navAddGreen = Color(0xFF36C394);

  // 状态圆点
  static const Color dotActive = Color(0xFF34D399);
  static const Color dotRetired = Color(0xFF94A3B8);
  static const Color dotSold = Color(0xFFF87171);
}

/// 字体族
class AppFonts {
  AppFonts._();

  /// 数据 / 正文 / 按钮字体
  static const String manrope = 'Manrope';

  /// 品牌标题字体
  static const String brand = 'SchibstedGrotesk';
}

/// 统一样式快捷方法
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle statusBar = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle brandTitle = TextStyle(
    fontFamily: AppFonts.brand,
    fontSize: 25,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  /// 内容页副标题：14px / 800 / #475569（订阅管理/心愿清单/我的资产 等）
  /// 与首页 tagline 顶部位置一致，仅字重不同（按各页 Figma）
  static const TextStyle pageSubtitle = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  /// 空状态主文案：20px / 800 / Manrope / #0F172A（按内容页 Figma）
  static const TextStyle emptyTitleLg = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// 空状态副文案：14px / 800 / Manrope / #61758B
  static const TextStyle emptySubtitleLg = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Color(0xFF61758B),
    height: 1.2,
  );

  /// 空状态 CTA 按钮文字：18px / 800 / 白色
  static const TextStyle emptyCta = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle statusLabel = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle emptyTitle = TextStyle(
    fontFamily: AppFonts.brand,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

/// 全局主题
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.manrope,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.background,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      splashFactory: NoSplash.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
