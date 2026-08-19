import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 图标统一渲染：既支持内置 SVG 图标，也支持本地图片（AI 抠图结果）。
///
/// - 路径以 `.svg` 结尾 → 按内置资源渲染（叠加白色）；
/// - 其他本地路径 → 按图片文件渲染（保留原色，透明底 PNG 可直接展示）；
/// - 空路径 → 回退到默认 SVG 或 Material 图标。
class ItemIcon extends StatelessWidget {
  const ItemIcon({
    super.key,
    this.iconPath,
    this.fallbackSvg,
    this.fallbackIcon,
    required this.size,
  });

  final String? iconPath;
  final String? fallbackSvg;
  final IconData? fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = iconPath;
    if (path == null || path.isEmpty) {
      if (fallbackSvg != null) {
        return SvgPicture.asset(
          fallbackSvg!,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
      }
      return Icon(
        fallbackIcon ?? Icons.inventory_2_outlined,
        size: size,
        color: Colors.white,
      );
    }
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }
    return Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}

/// 列表卡片上的图标：照片（AI 抠图结果）直接展示，无绿色圆底；
/// 内置 SVG / 默认图标保留绿色圆底。
class ItemIconBadge extends StatelessWidget {
  const ItemIconBadge({
    super.key,
    this.iconPath,
    this.fallbackSvg,
    this.fallbackIcon,
    this.circleSize = 44,
    this.iconSize = 22,
    this.photoSize = 100,
  });

  final String? iconPath;
  final String? fallbackSvg;
  final IconData? fallbackIcon;

  /// 默认图标的绿色圆底直径。
  final double circleSize;

  /// 默认图标（SVG/Icon）在圆底内的尺寸。
  final double iconSize;

  /// 照片图标的直接展示尺寸。
  final double photoSize;

  bool get _isPhoto =>
      iconPath != null && iconPath!.isNotEmpty && !iconPath!.endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(iconPath!),
          width: photoSize,
          height: photoSize,
          fit: BoxFit.contain,
        ),
      );
    }
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ItemIcon(
          iconPath: iconPath,
          fallbackSvg: fallbackSvg,
          fallbackIcon: fallbackIcon,
          size: iconSize,
        ),
      ),
    );
  }
}
