import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dart:math' as math;

import '../core/formatters/money_formatter.dart';
import '../domain/models/asset.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_grid_card.dart';
import '../widgets/asset_detail_sheet.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/primary_cta_button.dart';
import 'analytics_page.dart';
import 'add_flow_page.dart';

/// 我的资产页：资产列表（复用共享卡片）+ 详情面板。
///
/// 空状态沿用 Figma 27_193；有资产后展示卡片列表，左滑删除，点击看详情。
class MyAssetsPage extends StatelessWidget {
  const MyAssetsPage({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AssetStore.instance,
      builder: (context, _) {
        final store = AssetStore.instance;
        void openAnalytics() {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AnalyticsPage()),
          );
        }

        return PageScaffold(
          title: '我的资产',
          subtitle: '攒钱 未来更好的相遇',
          currentIndex: 3,
          onNavTap: onNavTap,
          header: _MyAssetsHeader(onAnalyticsTap: openAnalytics),
          body: store.isEmpty
              ? const _EmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AssetPieChart(store: store),
                    const SizedBox(height: 20),
                    ListenableBuilder(
                      listenable: SettingsStore.instance,
                      builder: (context, _) {
                        return SettingsStore.instance.viewStyle == '双列'
                            ? _AssetGrid(store: store)
                            : _AssetList(store: store);
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _MyAssetsHeader extends StatelessWidget {
  const _MyAssetsHeader({required this.onAnalyticsTap});

  final VoidCallback onAnalyticsTap;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final headerTop = PageHeader.headerTopFor(topInset);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, headerTop, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我的资产', style: AppTextStyles.brandTitle),
                const SizedBox(height: 4),
                Text('攒钱 未来更好的相遇', style: AppTextStyles.pageSubtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAnalyticsTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3310B981),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    '分析',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetPieChart extends StatefulWidget {
  const _AssetPieChart({required this.store});

  final AssetStore store;

  @override
  State<_AssetPieChart> createState() => _AssetPieChartState();
}

class _AssetPieChartState extends State<_AssetPieChart> {
  static const _colors = [
    Color(0xFF10B981),
    Color(0xFF38BDF8),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  bool _byAmount = false;

  List<_PieSlice> _buildSlices() {
    final values = <String, double>{};
    for (final asset in widget.store.items) {
      final value = _byAmount ? asset.purchasePrice : 1.0;
      values[asset.category] = (values[asset.category] ?? 0) + value;
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < entries.length; i++)
        _PieSlice(
          category: entries[i].key,
          value: entries[i].value,
          color: _colors[i % _colors.length],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slices = _buildSlices();
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = SettingsStore.instance.currency;
    final centerText = _byAmount
        ? MoneyFormatter.format(total, decimals: decimals, currency: currency)
        : '${total.toInt()}件';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _byAmount ? '按金额分布' : '按数量分布',
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _byAmount = !_byAmount),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE3E8E6)),
                  ),
                  child: Icon(
                    Icons.repeat,
                    size: 18,
                    color: _byAmount ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (slices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无资产数据',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(160),
                    painter: _PiePainter(slices: slices),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            centerText,
                            style: const TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (final slice in slices)
                  _LegendItem(
                    color: slice.color,
                    label: slice.category,
                    value: _byAmount
                        ? MoneyFormatter.format(
                            slice.value,
                            decimals: decimals,
                            currency: currency,
                          )
                        : '${slice.value.toInt()}件',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PieSlice {
  const _PieSlice({
    required this.category,
    required this.value,
    required this.color,
  });

  final String category;
  final double value;
  final Color color;
}

class _PiePainter extends CustomPainter {
  const _PiePainter({required this.slices});

  final List<_PieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.value / total * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $value',
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

/// 双列宫格视图（功能视图样式 = 双列）
class _AssetGrid extends StatelessWidget {
  const _AssetGrid({required this.store});

  final AssetStore store;

  void _showDetail(BuildContext context, Asset asset) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetDetailSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = store.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '共 ${items.length} 件资产',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final asset in items)
                  SizedBox(
                    width: cardWidth,
                    child: LongPressDeleteCard(
                      key: ValueKey(asset.id),
                      onTap: () => _showDetail(context, asset),
                      onDelete: () => store.remove(asset),
                      child: AssetGridCard(asset: asset),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 空状态（Figma 27_193）
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  void _openAdd(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddFlowPage(initialTab: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 92),
        SvgPicture.asset(
          'assets/CodeBuddyAssets/27_193/7.svg',
          width: 58,
          height: 79,
        ),
        const SizedBox(height: 21),
        const Text('资产空空', style: AppTextStyles.emptyTitleLg),
        const SizedBox(height: 12),
        const Text(
          '添加第一笔资产后 这里会展示资产构成饼图和详细记录',
          style: AppTextStyles.emptySubtitleLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryCtaButton(
          label: '添加资产',
          width: 130,
          height: 39,
          onTap: () => _openAdd(context),
        ),
      ],
    );
  }
}

/// 已添加资产列表
class _AssetList extends StatelessWidget {
  const _AssetList({required this.store});

  final AssetStore store;

  void _showDetail(BuildContext context, Asset asset) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetDetailSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = store.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '共 ${items.length} 件资产',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          AssetCard(
            asset: items[i],
            onTap: () => _showDetail(context, items[i]),
            onDelete: () => store.remove(items[i]),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
