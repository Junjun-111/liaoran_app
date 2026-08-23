import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/formatters/money_formatter.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import 'item_icon.dart';
/// 双列宫格卡片（按用户 Figma 重绘）：
/// 照片 + 状态/已回本胶囊；名称行带 Care 文件图标；价格 | 天数；日均成本。
class AssetGridCard extends StatelessWidget {
  const AssetGridCard({super.key, required this.asset});
  final Asset asset;
  static const _defaultIcon = 'assets/CodeBuddyAssets/42_951/6.svg';
  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = asset.currency;
    final price = asset.purchasePrice <= 0
        ? '无价之宝'
        : MoneyFormatter.format(
            asset.purchasePrice,
            decimals: decimals,
            currency: currency,
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
    final cpdText = calc.costPerDay == null
        ? '—'
        : '${MoneyFormatter.format(calc.costPerDay!, decimals: decimals, currency: currency)}/天';
    final showPaidBack =
        asset.status == AssetLifecycleStatus.active && calc.isPaidBack == true;
    final statusColor = asset.status == AssetLifecycleStatus.active
        ? const Color(0xFF46D09D)
        : asset.status == AssetLifecycleStatus.retired
            ? const Color(0xFF94A3B8)
            : const Color(0xFFF87171);
    final isPhoto = asset.icon != null &&
        asset.icon!.isNotEmpty &&
        !asset.icon!.endsWith('.svg') &&
        !isEmojiIconPath(asset.icon);
    return RepaintBoundary(
      child: Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: isPhoto
                      ? Image.file(
                          File(asset.icon!),
                          fit: BoxFit.contain,
                          cacheWidth: (80 *
                              MediaQuery.of(context).devicePixelRatio)
                              .round(),
                          errorBuilder: (_, _, _) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Pill(
                    label: asset.status.label,
                    dotColor: statusColor,
                    textColor: statusColor,
                  ),
                  if (showPaidBack) ...[
                    const SizedBox(height: 6),
                    const _Pill(
                      label: '已回本',
                      dotColor: Color(0xFF0BB981),
                      textColor: Color(0xFF46D09D),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0E1627),
                        ),
                      ),
                    ),
                    if (asset.careExpiryDate != null) ...[
                      const SizedBox(width: 8),
                      const _CareFileIcon(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA3A3A3),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: const Color(0xFFA3A3A3),
              ),
              Text(
                '${calc.daysUsed}天',
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA3A3A3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            cpdText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E1627),
            ),
          ),
        ],
      ),
      ),
    );
  }
  Widget _photoFallback() {
    final emoji = emojiFromIconPath(asset.icon);
    if (emoji != null) {
      return EmojiIconSquare(emoji: emoji, size: 80);
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: ItemIcon(
          iconPath: asset.icon,
          fallbackSvg: _defaultIcon,
          size: 28,
        ),
      ),
    );
  }
}
/// 胶囊状态标签：小圆点 + 文字
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.dotColor,
    required this.textColor,
  });
  final String label;
  final Color dotColor;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDAF4E9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
/// Care 文件图标：浅绿底 + 绿色文档
class _CareFileIcon extends StatelessWidget {
  const _CareFileIcon();
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/care.svg',
      width: 12,
      height: 14,
    );
  }
}
