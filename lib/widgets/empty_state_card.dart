import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// 空状态：还没有资产 + 添加资产 CTA（玻璃拟态按钮）
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, this.onAdd});

  /// 点击「添加资产」的回调；首页传入跳转添加页
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 图标（无圆底）
        SvgPicture.asset(
          'assets/CodeBuddyAssets/14_89/4.svg',
          width: 60,
          height: 66,
          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
        const SizedBox(height: 24),
        const Text('还没有资产', style: AppTextStyles.emptyTitle),
        const SizedBox(height: 8),
        const Text(
          '快去添加一笔资产开启你的资产管理之旅',
          style: AppTextStyles.emptySubtitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // 添加资产按钮（玻璃拟态）
        RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 120,
                  height: 47,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.72),
                        AppColors.primary.withValues(alpha: 0.88),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('添加资产', style: AppTextStyles.button),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
