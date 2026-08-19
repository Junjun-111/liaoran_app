import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 按压反馈：按下轻微缩小（仅 transform，不参与手势竞争）。
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
