import 'package:flutter/material.dart';

/// 弹窗输入控制器生命周期容器。
///
/// 弹窗关闭后仍有退场动画，此时若外部立即 dispose 控制器，会触发
/// “TextEditingController used after being disposed” 崩溃。
/// 本组件让控制器由弹窗自身持有，随弹窗销毁时统一释放，彻底规避该问题。
class DialogControllers extends StatefulWidget {
  const DialogControllers({
    super.key,
    required this.create,
    required this.builder,
  });

  final List<TextEditingController> Function() create;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  )
  builder;

  @override
  State<DialogControllers> createState() => _DialogControllersState();
}

class _DialogControllersState extends State<DialogControllers> {
  late final List<TextEditingController> _controllers = widget.create();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}
