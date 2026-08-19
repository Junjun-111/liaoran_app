import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 长按卡片：在卡片中间显示红色垃圾桶按钮，点击后二次确认再删除。
///
/// 资产 / 订阅 / 心愿卡片共用，交互完全一致，仅确认文案可配置。
class LongPressDeleteCard extends StatefulWidget {
  const LongPressDeleteCard({
    super.key,
    required this.child,
    this.onTap,
    required this.onDelete,
    this.title = '删除资产',
    this.message = '删除后不可恢复，确认要删除该资产吗？',
    this.confirmLabel = '确认删除',
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  /// 确认弹窗标题
  final String title;

  /// 确认弹窗说明
  final String message;

  /// 确认按钮文字
  final String confirmLabel;

  @override
  State<LongPressDeleteCard> createState() => _LongPressDeleteState();
}

class _LongPressDeleteState extends State<LongPressDeleteCard> {
  OverlayEntry? _deleteOverlay;

  @override
  void dispose() {
    _deleteOverlay?.remove();
    _deleteOverlay = null;
    super.dispose();
  }

  void _closeDeleteButton() {
    _deleteOverlay?.remove();
    _deleteOverlay = null;
  }

  void _showDeleteButton() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final cardTopLeft = renderBox.localToGlobal(Offset.zero);
    final cardSize = renderBox.size;
    const buttonSize = 52.0;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDeleteButton,
              child: ColoredBox(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.14),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            left: cardTopLeft.dx + cardSize.width / 2 - buttonSize / 2,
            top: cardTopLeft.dy + cardSize.height / 2 - buttonSize / 2,
            child: _DeleteCircleButton(onTap: _handleDeleteTap),
          ),
        ],
      ),
    );

    _deleteOverlay = entry;
    overlay.insert(entry);
  }

  Future<void> _handleDeleteTap() async {
    _closeDeleteButton();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xFF1A1A1A).withValues(alpha: 0.18),
      builder: (_) => _ConfirmDeleteDialog(
        title: widget.title,
        message: widget.message,
        confirmLabel: widget.confirmLabel,
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: _showDeleteButton,
        child: widget.child,
      ),
    );
  }
}

class _DeleteCircleButton extends StatelessWidget {
  const _DeleteCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A80), Color(0xFFE5484D)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5484D).withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardStroke, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5484D),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
