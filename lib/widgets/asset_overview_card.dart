import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';

/// 资产总览卡片（严格按 Figma「asset-glass-card」模块复刻）。
///
/// 结构：标题行（资产总览 + 玻璃徽标）→ 统计行（总资产 / 日均成本）
/// → 分隔线 → 状态行（圆点 + 服役中/已退役/已卖出）。
/// 数值实时来自 [AssetStore]；徽标 = 服役中数/总数。
class AssetOverviewCard extends StatelessWidget {
  const AssetOverviewCard({super.key});

  static const _statusColors = <AssetLifecycleStatus, Color>{
    AssetLifecycleStatus.active: Color(0xFF34D399),
    AssetLifecycleStatus.retired: Color(0xFF94A3B8),
    AssetLifecycleStatus.sold: Color(0xFFF87171),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AssetStore.instance,
      builder: (context, _) {
        final store = AssetStore.instance;
        final decimals = SettingsStore.instance.decimalPlaces;
        final totalCount = store.items.length;

        final totalValue = MoneyFormatter.format(
          store.totalValue,
          decimals: decimals,
        );
        final dailyCost = store.items.fold<double>(0, (sum, a) {
          final r = const CostPerDayCalculator().calculate(
            purchasePrice: a.purchasePrice,
            purchaseDate: a.purchaseDate,
            status: a.status,
            retiredDate: a.retiredDate,
            salePrice: a.latestSale?.salePrice,
            saleDate: a.latestSale?.saleDate,
          );
          return sum + (r.costPerDay ?? 0);
        });
        final dailyText =
            MoneyFormatter.format(dailyCost, decimals: decimals);

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardMint,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardStroke, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadowPrimary,
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题行：资产总览 + 玻璃徽标（服役中数/总数）
                  SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('资产总览', style: AppTextStyles.sectionTitle),
                        ),
                        const Spacer(),
                        Container(
                          width: 41,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                            ),
                          ),
                          child: Text(
                            '${store.activeCount}/$totalCount',
                            style: AppTextStyles.badge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  // 统计行：总资产 / 日均成本
                  SizedBox(
                    height: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MetricItem(label: '总资产', value: totalValue),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MetricItem(label: '日均成本', value: dailyText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  Container(height: 1, color: AppColors.cardStroke),
                  const SizedBox(height: 18),
                  // 状态行：圆点 + 数量
                  SizedBox(
                    height: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final status in AssetLifecycleStatus.values)
                          _StatusItem(
                            label: '${status.label} ${_countFor(store, status)}',
                            color: _statusColors[status]!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  static int _countFor(AssetStore store, AssetLifecycleStatus status) {
    switch (status) {
      case AssetLifecycleStatus.active:
        return store.activeCount;
      case AssetLifecycleStatus.retired:
        return store.retiredCount;
      case AssetLifecycleStatus.sold:
        return store.soldCount;
    }
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 30 / 22,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 18 / 13,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
