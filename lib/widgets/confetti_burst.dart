import 'dart:math';

import 'package:flutter/material.dart';

/// 喷发总时长（秒）
const double _burstSeconds = 2.0;

/// 礼花纸屑：从底部中心向上喷出，受重力影响自然散开、飘落，
/// 结尾柔和淡出，结束后组件自动移除。
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2000);

  static const _colors = [
    Color(0xFFF94144),
    Color(0xFFF8961E),
    Color(0xFFF9C74F),
    Color(0xFF90BE6D),
    Color(0xFF43AA8B),
    Color(0xFF577590),
    Color(0xFF9B5DE5),
    Color(0xFFF15BB5),
    Color(0xFF00BBF9),
  ];

  late final List<_Particle> _particles;
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(130, (_) => _Particle(random, _colors));
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle(Random r, List<Color> colors)
      : color = colors[r.nextInt(colors.length)],
        size = 6 + r.nextDouble() * 8,
        delay = r.nextDouble() * 0.18,
        // 水平初速：向左右自然散开
        vx = (r.nextDouble() - 0.5) * 0.95,
        // 向上初速（屏幕高度/秒）
        vy = 0.85 + r.nextDouble() * 0.75,
        wobble = r.nextDouble() * 6.28,
        spin = (r.nextDouble() - 0.5) * 10;

  final Color color;
  final double size;
  final double delay;
  final double vx;
  final double vy;
  final double wobble;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  /// 重力加速度（屏幕高度/秒²）
  static const _gravity = 1.05;

  static double _smooth(double x) => x * x * (3 - 2 * x);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final x0 = w * 0.5;
    final y0 = h + 16;
    final seconds = _burstSeconds * progress;

    for (final p in particles) {
      final span = 1 - p.delay;
      final t = span <= 0
          ? 1.0
          : ((progress - p.delay) / span).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      final sec = seconds - p.delay * 2.0;
      if (sec <= 0) continue;

      // 匀加速运动：先上升后下落（重力）
      final x = x0 +
          p.vx * sec * w +
          sin(p.wobble + sec * 6) * 14 * sec;
      final y = y0 - p.vy * sec * h + 0.5 * _gravity * sec * sec * h;

      // 开头快速显现，结尾柔和淡出
      final opacity = t < 0.06
          ? t / 0.06
          : t > 0.72
              ? 1 - _smooth((t - 0.72) / 0.28)
              : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.wobble + sec * p.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * (0.8 + 0.2 * opacity),
          height: p.size * 0.62 * (0.8 + 0.2 * opacity),
        ),
        Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
