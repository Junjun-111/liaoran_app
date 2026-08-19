import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import 'item_icon.dart';

/// 资产卡片（首页 / 我的资产页共用）。
///
/// [onTap] 点击查看详情；[onDelete] 非空时支持左滑删除。
class AssetCard extends StatelessWidget {
  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.onDelete,
  });

  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  static const _defaultIcon = 'assets/CodeBuddyAssets/42_951/6.svg';

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final price = asset.purchasePrice <= 0
        ? '无价之宝'
        : MoneyFormatter.format(
            asset.purchasePrice,
            decimals: decimals,
            currency: asset.currency,
          );
    final calc = const CostPerDayCalculator().calculate(
      purchasePrice: asset.purchasePrice,
      purchaseDate: asset.purchaseDate,
      status: asset.status,
      retiredDate: asset.retiredDate,
      salePrice: asset.latestSale?.salePrice,
      saleDate: asset.latestSale?.saleDate,
      targetCpd: asset.targetCpd,
    );
    final cpd = calc.costPerDay;
    final showPaidBack =
        asset.status == AssetLifecycleStatus.active && calc.isPaidBack == true;
    final cpdText = cpd == null
        ? '—'
        : '${MoneyFormatter.format(cpd, decimals: decimals, currency: asset.currency)}/天';

    final cardContent = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardStroke, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowPrimary,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ItemIconBadge(
            iconPath: asset.icon,
            fallbackSvg: _defaultIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  asset.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '• ',
                            style: TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          TextSpan(
                            text: asset.status.label,
                            style: const TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF61758B),
                            ),
                          ),
                          if (showPaidBack)
                            TextSpan(
                              text: ' • 已回本',
                              style: const TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cpdText,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF61758B),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final card = onDelete == null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: cardContent,
          )
        : cardContent;

    if (onDelete == null) return card;
    return LongPressDeleteCard(
      key: ValueKey(asset.id),
      onTap: onTap,
      onDelete: onDelete!,
      child: card,
    );
  }
}

/// 长按资产卡片：在卡片中间显示红色垃圾桶按钮，点击后二次确认再删除。
class LongPressDeleteCard extends StatefulWidget {
  const LongPressDeleteCard({
    super.key,
    required this.child,
    this.onTap,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

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
      builder: (_) => const _ConfirmDeleteDialog(),
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
  const _ConfirmDeleteDialog();

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
            const Text(
              '删除资产',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '删除后不可恢复，确认要删除该资产吗？',
              style: TextStyle(
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
                  child: const Text(
                    '确认删除',
                    style: TextStyle(
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
