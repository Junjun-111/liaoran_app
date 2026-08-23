import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/models/asset.dart';
import '../models/subscription.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../state/wishlist_store.dart';
import '../theme/app_theme.dart';
import '../widgets/background_blobs.dart';

/// 年度/月度报告页。
///
/// 从「我的资产」页分享按钮进入；汇总本期资产变化、订阅支出、
/// 心愿攒钱进度，支持一键生成图片分享。
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

enum _ReportRange { month, year }

class _ReportPageState extends State<ReportPage> {
  _ReportRange _range = _ReportRange.month;
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AssetStore.instance,
        SubscriptionStore.instance,
        WishlistStore.instance,
        SettingsStore.instance,
      ]),
      builder: (context, _) {
        final now = DateTime.now();
        final start = _range == _ReportRange.month
            ? DateTime(now.year, now.month, 1)
            : DateTime(now.year, 1, 1);

        final assets = AssetStore.instance.items;
        final newAssets = assets.where((a) => !a.createdAt.isBefore(start)).toList();
        final newValue =
            newAssets.fold<double>(0, (sum, a) => sum + a.purchasePrice);
        final soldInRange = <Asset>[];
        for (final asset in assets) {
          final sale = asset.latestSale;
          if (sale != null && !sale.saleDate.isBefore(start)) {
            soldInRange.add(asset);
          }
        }
        final soldValue = soldInRange.fold<double>(
          0,
          (sum, a) => sum + (a.latestSale?.salePrice ?? 0),
        );
        final totalValue = assets.fold<double>(
          0,
          (sum, a) => sum + a.purchasePrice,
        );

        final subs = SubscriptionStore.instance.items;
        final activeSubs =
            subs.where((s) => s.status == '生效中' || s.status == '自动续费').toList();
        final subscriptionCost = subs.fold<double>(
          0,
          (sum, s) => sum + _subscriptionCostInRange(s, start, now),
        );
        final monthlySubCost = activeSubs.fold<double>(
          0,
          (sum, s) => sum + s.monthlyAmount,
        );

        final wishes = WishlistStore.instance.items;
        final completedWishes =
            wishes.where((w) => w.completed).length;
        final savedTotal = wishes.fold<double>(
          0,
          (sum, w) => sum + w.savedAmount,
        );
        final targetTotal =
            wishes.fold<double>(0, (sum, w) => sum + w.targetAmount);

        final decimals = SettingsStore.instance.decimalPlaces;
        final currency = SettingsStore.instance.currency;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: BackgroundBlobs()),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReportHeader(
                      onBack: () => Navigator.of(context).pop(),
                      onShare: _sharing ? null : _share,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _RangeSwitch(
                        range: _range,
                        onChanged: (range) => setState(() => _range = range),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: RepaintBoundary(
                          key: _captureKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SummaryCard(
                                range: _range,
                                totalValue: totalValue,
                                newCount: newAssets.length,
                                newValue: newValue,
                                soldCount: soldInRange.length,
                                soldValue: soldValue,
                                decimals: decimals,
                                currency: currency,
                              ),
                              const SizedBox(height: 14),
                              _SubscriptionCard(
                                range: _range,
                                cost: subscriptionCost,
                                monthlyCost: monthlySubCost,
                                activeCount: activeSubs.length,
                                decimals: decimals,
                                currency: currency,
                              ),
                              const SizedBox(height: 14),
                              _WishlistCard(
                                range: _range,
                                total: wishes.length,
                                completed: completedWishes,
                                savedTotal: savedTotal,
                                targetTotal: targetTotal,
                                decimals: decimals,
                                currency: currency,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 统计订阅在本期产生的费用：
  /// 首次订阅在本期之前时，按本期起始后已发生的扣款估算；否则按开始时间估算。
  double _subscriptionCostInRange(Subscription s, DateTime start, DateTime now) {
    if (s.cycle == '无' || s.firstDate == null) {
      final f = s.firstDate;
      if (f == null) return 0;
      return !f.isBefore(start) && !f.isAfter(now) ? s.amount : 0;
    }
    final first = s.firstDate!;
    final effectiveStart = first.isAfter(start) ? first : start;
    if (effectiveStart.isAfter(now)) return 0;

    var months =
        (now.year - effectiveStart.year) * 12 + (now.month - effectiveStart.month) + 1;
    if (months < 1) months = 1;
    switch (s.cycle) {
      case '包季':
        return s.amount * ((months + 2) ~/ 3);
      case '包年':
        return s.amount * ((months + 11) ~/ 12);
      default:
        return s.amount * months;
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/liaoran_report_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      final rangeLabel = _range == _ReportRange.month ? '月度报告' : '年度报告';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '我的了然$rangeLabel',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// 顶部：返回 + 标题 + 分享按钮
class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardStroke),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadowBlack,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('报告', style: AppTextStyles.brandTitle),
                SizedBox(height: 2),
                Text('资产 订阅 心愿 一目了然', style: AppTextStyles.pageSubtitle),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardStroke),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadowBlack,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: onShare == null
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.ios_share_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 月度 / 年度切换
class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.range, required this.onChanged});

  final _ReportRange range;
  final ValueChanged<_ReportRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardStroke),
      ),
      child: Row(
        children: [
          for (final (value, label) in [
            (_ReportRange.month, '本月'),
            (_ReportRange.year, '年度'),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: AppMotion.easeOut,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: value == range ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == range
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 报告卡片容器
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardStroke),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowPrimary,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportCardTitle extends StatelessWidget {
  const _ReportCardTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }
}

/// 资产变化总结卡
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.range,
    required this.totalValue,
    required this.newCount,
    required this.newValue,
    required this.soldCount,
    required this.soldValue,
    required this.decimals,
    required this.currency,
  });

  final _ReportRange range;
  final double totalValue;
  final int newCount;
  final double newValue;
  final int soldCount;
  final double soldValue;
  final int decimals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final periodLabel = range == _ReportRange.month ? '本月' : '本年';
    return _ReportCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportCardTitle('资产变化', trailing: periodLabel),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(totalValue, decimals: decimals, currency: currency),
            style: const TextStyle(
              fontFamily: AppFonts.brand,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: '$periodLabel新增',
                  value: '$newCount 件',
                  sub: MoneyFormatter.format(
                    newValue,
                    decimals: decimals,
                    currency: currency,
                  ),
                  color: AppColors.dotActive,
                ),
              ),
              Container(
                width: 1,
                height: 46,
                color: AppColors.cardStroke,
              ),
              Expanded(
                child: _MiniStat(
                  label: '$periodLabel卖出',
                  value: '$soldCount 件',
                  sub: MoneyFormatter.format(
                    soldValue,
                    decimals: decimals,
                    currency: currency,
                  ),
                  color: AppColors.dotSold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 订阅支出卡
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.range,
    required this.cost,
    required this.monthlyCost,
    required this.activeCount,
    required this.decimals,
    required this.currency,
  });

  final _ReportRange range;
  final double cost;
  final double monthlyCost;
  final int activeCount;
  final int decimals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final periodLabel = range == _ReportRange.month ? '本月' : '本年';
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportCardTitle('订阅支出', trailing: periodLabel),
          const SizedBox(height: 10),
          Text(
            MoneyFormatter.format(cost, decimals: decimals, currency: currency),
            style: const TextStyle(
              fontFamily: AppFonts.brand,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: '生效订阅',
                  value: '$activeCount 项',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: '月均支出',
                  value: MoneyFormatter.format(
                    monthlyCost,
                    decimals: decimals,
                    currency: currency,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

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
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 心愿攒钱卡
class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.range,
    required this.total,
    required this.completed,
    required this.savedTotal,
    required this.targetTotal,
    required this.decimals,
    required this.currency,
  });

  final _ReportRange range;
  final int total;
  final int completed;
  final double savedTotal;
  final double targetTotal;
  final int decimals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final periodLabel = range == _ReportRange.month ? '本月' : '本年';
    final progress = targetTotal <= 0
        ? 0.0
        : (savedTotal / targetTotal).clamp(0.0, 1.0).toDouble();
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportCardTitle('心愿进度', trailing: periodLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: '心愿总数',
                  value: '$total 个',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: '已完成',
                  value: '$completed 个',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: '已攒金额',
                  value: MoneyFormatter.format(
                    savedTotal,
                    decimals: decimals,
                    currency: currency,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE6F0EC),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            targetTotal <= 0
                ? '还没有心愿目标，去添加一个吧'
                : '已完成 ${(progress * 100).toStringAsFixed(0)}% '
                    '（目标 ${MoneyFormatter.format(targetTotal, decimals: decimals, currency: currency)}）',
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
