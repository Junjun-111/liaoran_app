import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// 底部悬浮毛玻璃胶囊导航：5 个导航项 + 右侧玻璃添加按钮
///
/// [currentIndex] 控制选中项（0~4，对应 首页/订阅/心愿/资产/我的）。
/// [onTap] 为点击回调，参数为被点击项的索引。
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  static const _icons = [
    'assets/CodeBuddyAssets/14_89/5.svg',
    'assets/CodeBuddyAssets/14_89/6.svg',
    'assets/CodeBuddyAssets/14_89/7.svg',
    'assets/CodeBuddyAssets/14_89/8.svg',
    'assets/CodeBuddyAssets/14_89/9.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 毛玻璃胶囊
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(33),
              child: RepaintBoundary(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 66,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(33),
                      border:
                          Border.all(color: AppColors.cardStroke, width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadowPrimary,
                          blurRadius: 22,
                          offset: Offset(0, 11),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < _icons.length; i++)
                          _NavItem(
                            key: ValueKey('nav_$i'),
                            asset: _icons[i],
                            selected: i == currentIndex,
                            onTap: onTap == null ? null : () => onTap!(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _AddButton(
            key: const ValueKey('nav_add'),
            onTap: onTap == null ? null : () => onTap!(-1),
          ),
        ],
      ),
    );
  }
}

/// 单个导航项；选中态为玻璃圆圈
class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.asset,
    this.selected = false,
    this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    const iconSize = 24.0;
    final radius = size / 2;
    final selected = widget.selected;
    final iconColor = selected ? AppColors.primary : AppColors.textHint;
    final icon = SvgPicture.asset(
      widget.asset,
      width: iconSize,
      height: iconSize,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        child: selected
            ? ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: RepaintBoundary(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: size,
                      height: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.navSelectedBg,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                            color: AppColors.navSelectedStroke, width: 1.0),
                      ),
                      child: icon,
                    ),
                  ),
                ),
              )
            : Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                child: icon,
              ),
      ),
    );
  }
}

/// 右侧圆形添加按钮：玻璃拟态
class _AddButton extends StatefulWidget {
  const _AddButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        child: ClipOval(
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navAddGreen.withValues(alpha: 0.80),
                      AppColors.navAddGreen.withValues(alpha: 0.95),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/CodeBuddyAssets/14_89/10.svg',
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
