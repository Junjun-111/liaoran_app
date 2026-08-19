import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// emoji 图标的存储前缀：icon 字段为 `emoji:<emoji>` 时按文字渲染。
const String emojiIconPrefix = 'emoji:';

/// 把 emoji 转成可存储的 icon 值。
String emojiIcon(String emoji) => '$emojiIconPrefix$emoji';

/// 判断 icon 值是否为 emoji 图标。
bool isEmojiIconPath(String? path) =>
    path != null && path.startsWith(emojiIconPrefix);

/// 从 icon 值中取出 emoji 字符；不是 emoji 图标时返回 null。
String? emojiFromIconPath(String? path) =>
    isEmojiIconPath(path) ? path!.substring(emojiIconPrefix.length) : null;

/// emoji 图标展示：无背景、居中、距容器边缘留 2、尽量放大填满方块。
class EmojiIconSquare extends StatelessWidget {
  const EmojiIconSquare({
    super.key,
    required this.emoji,
    this.size = 100,
  });

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            emoji,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 图标统一渲染：既支持内置 SVG 图标，也支持本地图片（AI 抠图结果）。
///
/// - 路径以 `.svg` 结尾 → 按内置资源渲染（叠加白色）；
/// - `emoji:<emoji>` → 直接渲染该 emoji 文字；
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
    final emoji = emojiFromIconPath(path);
    if (emoji != null) {
      return Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size, height: 1),
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
      iconPath != null &&
      iconPath!.isNotEmpty &&
      !iconPath!.endsWith('.svg') &&
      !isEmojiIconPath(iconPath);

  @override
  Widget build(BuildContext context) {
    final emoji = emojiFromIconPath(iconPath);
    if (emoji != null) {
      return EmojiIconSquare(emoji: emoji, size: photoSize);
    }
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
