import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import 'item_icon.dart';
import 'long_press_delete_card.dart';
import 'motion_widgets.dart';

export 'long_press_delete_card.dart';

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
      baseAmount: asset.costBasis,
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
        ? PressScale(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: cardContent,
            ),
          )
        : cardContent;

    // 每张卡片独立成层：图片加载/重绘只影响本卡
    return RepaintBoundary(
      child: onDelete == null
          ? card
          : LongPressDeleteCard(
              key: ValueKey(asset.id),
              onTap: onTap,
              onDelete: onDelete!,
              child: card,
            ),
    );
  }
}
