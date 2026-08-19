import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 页面背景：三个大尺寸柔和渐变光斑（浅蓝右上 / 浅绿中左 / 浅粉右下）
class BackgroundBlobs extends StatelessWidget {
  const BackgroundBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 440.0;
        final cy = h / 956.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 浅蓝光斑：画布 (200,40)，320×320
            Positioned(
              left: 200 * cx,
              top: 40 * cy,
              child: _Blob(color: AppColors.blobBlue, size: 320 * cx, opacity: 0.80),
            ),
            // 浅绿光斑：画布 (-100,320)，360×360
            Positioned(
              left: -100 * cx,
              top: 320 * cy,
              child: _Blob(color: AppColors.blobGreen, size: 360 * cx, opacity: 0.85),
            ),
            // 浅粉光斑：画布 (220,600)，340×340
            Positioned(
              left: 220 * cx,
              top: 600 * cy,
              child: _Blob(color: AppColors.blobPink, size: 340 * cx, opacity: 0.70),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.55),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}
