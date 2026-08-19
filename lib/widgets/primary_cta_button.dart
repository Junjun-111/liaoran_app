import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 实心绿色 CTA 按钮（Figma：#10B981 实心，圆角 72，无玻璃）。
///
/// 原为 订阅管理 / 我的资产 / 心愿清单 三个页面各自私有的 `_PrimaryCta`，
/// 视觉完全一致，现抽取为共享组件，页面统一复用。
class PrimaryCtaButton extends StatelessWidget {
  const PrimaryCtaButton({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(72),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3310B981),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(label, style: AppTextStyles.emptyCta),
        ),
      ),
    );
  }
}
