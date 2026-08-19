import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/analytics/asset_analytics.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/background_blobs.dart';

/// 资产分析页。
///
/// 从「我的资产」页右上角进入；使用真实资产、标签数据，
/// 按 全部 / 最近一周 / 最近90天 / 最近180天 / 最近一年 动态计算。
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsRange _range = AnalyticsRange.all;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AssetStore.instance,
        SettingsStore.instance,
      ]),
      builder: (context, _) {
        final allAssets = AssetStore.instance.items;
        final selectedAssets = AssetAnalytics.selectAssets(allAssets, _range);
        final hasRecentChanges = _range.days == null
            ? true
            : AssetAnalytics.hasNewAssetsInRange(allAssets, _range.days!);

        final summary = AssetAnalytics.summarize(selectedAssets);
        final categorySlices = AssetAnalytics.categoryDistribution(
          selectedAssets,
        );
        final tagStats = AssetAnalytics.tagDistribution(
          selectedAssets,
          SettingsStore.instance.tags,
        );
        final trendPoints = AssetAnalytics.valueTrend(selectedAssets);
        final overallAverage = AssetAnalytics.overallAverageHoldingDays(
          selectedAssets,
          SettingsStore.instance.tags,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: BackgroundBlobs()),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AnalyticsHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 16),
                    _RangeTabs(
                      selected: _range,
                      onSelected: (range) => setState(() => _range = range),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_range.days != null && !hasRecentChanges)
                              _NoRecentChangesNotice(range: _range),
                            _AssetTotalCard(summary: summary),
                            const SizedBox(height: 14),
                            _TrendCard(
                              points: trendPoints,
                              currentValue: summary.total,
                            ),
                            const SizedBox(height: 14),
                            _CategoryDistributionCard(slices: categorySlices),
                            const SizedBox(height: 14),
                            _TagDistributionCard(stats: tagStats),
                            const SizedBox(height: 14),
                            _HoldingDurationCard(
                              stats: tagStats,
                              overallAverage: overallAverage,
                            ),
                          ],
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
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.onBack});

  final VoidCallback onBack;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('分析', style: AppTextStyles.brandTitle),
              const SizedBox(height: 2),
              Text('资产数据洞察', style: AppTextStyles.pageSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.selected, required this.onSelected});

  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: AnalyticsRange.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = AnalyticsRange.values[index];
          final active = range == selected;
          return GestureDetector(
            onTap: () => onSelected(range),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.cardWhite.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.cardStroke,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadowBlack,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

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

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.manrope,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _NoRecentChangesNotice extends StatelessWidget {
  const _NoRecentChangesNotice({required this.range});

  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    final message = switch (range) {
      AnalyticsRange.week => '您近期一周没有新的资产',
      AnalyticsRange.days90 => '您近期90天没有新的资产',
      AnalyticsRange.days180 => '您近期 180 天没有新的资产',
      AnalyticsRange.year => '最近一年没有新的资产',
      AnalyticsRange.all => '',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTotalCard extends StatelessWidget {
  const _AssetTotalCard({required this.summary});

  final AssetValueSummary summary;

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = SettingsStore.instance.currency;
    final totalText = summary.total <= 0
        ? '暂无资产'
        : MoneyFormatter.format(
            summary.total,
            decimals: decimals,
            currency: currency,
          );

    return _AnalyticsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('资产总值'),
          const SizedBox(height: 6),
          Text(
            totalText,
            style: const TextStyle(
              fontFamily: AppFonts.brand,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusStatRow(
                      color: AppColors.dotActive,
                      label: AssetLifecycleStatus.active.label,
                      amount: summary.active,
                      ratio: summary.ratioOf(summary.active),
                    ),
                    const SizedBox(height: 14),
                    _StatusStatRow(
                      color: AppColors.dotRetired,
                      label: AssetLifecycleStatus.retired.label,
                      amount: summary.retired,
                      ratio: summary.ratioOf(summary.retired),
                    ),
                    const SizedBox(height: 14),
                    _StatusStatRow(
                      color: AppColors.dotSold,
                      label: AssetLifecycleStatus.sold.label,
                      amount: summary.sold,
                      ratio: summary.ratioOf(summary.sold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _AssetValueBar(summary: summary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusStatRow extends StatelessWidget {
  const _StatusStatRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.ratio,
  });

  final Color color;
  final String label;
  final double amount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = SettingsStore.instance.currency;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const SizedBox(width: 6),
                  Text(
                    '${(ratio * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                MoneyFormatter.format(
                  amount,
                  decimals: decimals,
                  currency: currency,
                ),
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetValueBar extends StatelessWidget {
  const _AssetValueBar({required this.summary});

  final AssetValueSummary summary;

  int _flex(double value) {
    final flex = (summary.ratioOf(value) * 100).round();
    return flex < 1 ? 1 : flex;
  }

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 54,
        height: 158,
        child: total <= 0
            ? Container(color: AppColors.cardStroke)
            : Column(
                children: [
                  Expanded(
                    flex: _flex(summary.active),
                    child: Container(color: AppColors.dotActive),
                  ),
                  Expanded(
                    flex: _flex(summary.retired),
                    child: Container(color: AppColors.dotRetired),
                  ),
                  Expanded(
                    flex: _flex(summary.sold),
                    child: Container(color: AppColors.dotSold),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points, required this.currentValue});

  final List<TrendPoint> points;
  final double currentValue;

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = SettingsStore.instance.currency;
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('资产价值趋势'),
          const SizedBox(height: 6),
          Text(
            MoneyFormatter.format(
              currentValue,
              decimals: decimals,
              currency: currency,
            ),
            style: const TextStyle(
              fontFamily: AppFonts.brand,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          if (points.isEmpty)
            const SizedBox(
              height: 210,
              child: Center(
                child: Text(
                  '暂无趋势数据',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: CustomPaint(
                size: const Size(double.infinity, 220),
                painter: _TrendPainter(points: points),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points});

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const yLabelWidth = 54.0;
    const xLabelHeight = 22.0;
    const chartLeft = 0.0;
    final chartRight = size.width - yLabelWidth;
    final chartTop = 2.0;
    final chartBottom = size.height - xLabelHeight;
    final chartH = chartBottom - chartTop;
    final chartW = chartRight - chartLeft;

    final gridPaint = Paint()
      ..color = AppColors.cardStroke
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 4; i++) {
      final y = chartTop + chartH * i / 4;
      _drawDashed(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );
    }

    final start = AssetAnalytics.normalizeDate(points.first.date);
    final end = DateTime.now();
    final normalizedEnd = AssetAnalytics.normalizeDate(end);
    final totalMs = math
        .max(1, normalizedEnd.difference(start).inMilliseconds)
        .toDouble();

    var maxValue = 0.0;
    for (final point in points) {
      if (point.value > maxValue) maxValue = point.value;
    }
    if (maxValue <= 0) maxValue = 1;
    final yMax = maxValue * 1.12;

    final pts = [
      for (final point in points)
        Offset(
          chartLeft +
              chartW *
                  (AssetAnalytics.normalizeDate(point.date)
                          .difference(start)
                          .inMilliseconds /
                      totalMs),
          chartTop + chartH * (1 - point.value / yMax),
        ),
    ];

    final linePts = [...pts];
    if (linePts.isNotEmpty) {
      final last = linePts.last;
      if ((chartRight - last.dx).abs() > 0.5) {
        linePts.add(Offset(chartRight, last.dy));
      }
    }

    if (linePts.length == 1) {
      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(chartLeft, linePts.first.dy),
        Offset(chartRight, linePts.first.dy),
        linePaint,
      );
    } else {
      final smoothPath = _smoothPath(linePts);
      final areaPath = Path.from(smoothPath)
        ..lineTo(linePts.last.dx, chartBottom)
        ..lineTo(linePts.first.dx, chartBottom)
        ..close();

      final fillShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.24),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(chartLeft, chartTop, chartW, chartH));
      canvas.drawPath(
        areaPath,
        Paint()
          ..shader = fillShader
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        smoothPath,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final labelStyle = const TextStyle(
      fontFamily: AppFonts.manrope,
      fontSize: 11,
      color: AppColors.textHint,
    );
    for (var i = 0; i <= 4; i++) {
      final value = yMax * (4 - i) / 4;
      final y = chartTop + chartH * i / 4;
      _paintText(
        canvas,
        _formatAxis(value),
        Offset(chartRight + 5, y - 7),
        labelStyle,
        yLabelWidth,
      );
    }

    _paintText(
      canvas,
      _formatDate(start),
      Offset(chartLeft, chartBottom + 4),
      labelStyle,
      90,
    );
    _paintText(
      canvas,
      '今天',
      Offset(chartRight - 26, chartBottom + 4),
      labelStyle,
      30,
    );
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final previous = pts[i - 1];
      final current = pts[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    return path;
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    final delta = b - a;
    final length = delta.distance;
    if (length <= 0) return;
    final unit = delta / length;
    var t = 0.0;
    var draw = true;
    while (t < length) {
      final segment = draw ? dash : gap;
      final end = (t + segment < length ? t + segment : length);
      if (draw) {
        canvas.drawLine(a + unit * t, a + unit * end, paint);
      }
      t += segment;
      draw = !draw;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({required this.slices});

  final List<CategorySlice> slices;

  static const _palette = [
    AppColors.primary,
    Color(0xFF38BDF8),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
    Color(0xFFF87171),
    Color(0xFF94A3B8),
  ];

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    final hasAmount = total > 0;
    final chartValues = [
      for (final slice in slices) hasAmount ? slice.value : 1.0,
    ];
    final chartTotal = chartValues.fold<double>(0, (sum, value) => sum + value);
    final chartSlices = [
      for (var i = 0; i < slices.length; i++)
        _PieChartSlice(
          color: _palette[i % _palette.length],
          value: chartValues[i],
        ),
    ];
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('类型分布'),
          const SizedBox(height: 18),
          if (slices.isEmpty)
            const SizedBox(
              height: 170,
              child: Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 160,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(160),
                      painter: _PieChartPainter(slices: chartSlices),
                    ),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (var i = 0; i < slices.length; i++)
                  _CategoryLegend(
                    color: _palette[i % _palette.length],
                    label: slices[i].category,
                    ratio: chartTotal <= 0 ? 0 : chartValues[i] / chartTotal,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PieChartSlice {
  const _PieChartSlice({required this.color, required this.value});

  final Color color;
  final double value;
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.slices});

  final List<_PieChartSlice> slices;

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
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.color,
    required this.label,
    required this.ratio,
  });

  final Color color;
  final String label;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '${(ratio * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TagDistributionCard extends StatelessWidget {
  const _TagDistributionCard({required this.stats});

  final List<TagStat> stats;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('标签分布'),
          const SizedBox(height: 14),
          if (stats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '暂无标签',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in stats)
                  _TagChip(name: stat.tag, count: stat.count),
              ],
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardStroke),
      ),
      child: Text(
        '$name  $count',
        style: const TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _HoldingDurationCard extends StatelessWidget {
  const _HoldingDurationCard({
    required this.stats,
    required this.overallAverage,
  });

  final List<TagStat> stats;
  final double overallAverage;

  static const _barColors = [
    Color(0xFFA6F44C),
    Color(0xFF6CE8A9),
    Color(0xFF5FD1ED),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
  ];

  @override
  Widget build(BuildContext context) {
    final activeStats = stats.where((s) => s.count > 0).toList();
    var maxDays = 0.0;
    for (final stat in activeStats) {
      if (stat.averageHoldingDays > maxDays) {
        maxDays = stat.averageHoldingDays;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 23, 23, 23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.33),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1.15),
            blurRadius: 2.29,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1.15),
            blurRadius: 1.15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '各标签平均服役时长',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              height: 23 / 12,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDays(overallAverage),
            style: const TextStyle(
              fontFamily: AppFonts.brand,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 23 / 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          if (activeStats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '暂无服役时长数据',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < activeStats.length; i++) ...[
              _HoldingRow(
                color: _barColors[i % _barColors.length],
                label: activeStats[i].tag,
                days: activeStats[i].averageHoldingDays,
                maxDays: maxDays,
              ),
              if (i < activeStats.length - 1) const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.color,
    required this.label,
    required this.days,
    required this.maxDays,
  });

  final Color color;
  final String label;
  final double days;
  final double maxDays;

  @override
  Widget build(BuildContext context) {
    final width = maxDays <= 0
        ? 24.0
        : math.max(24.0, 84 * days / maxDays).toDouble();
    return Row(
      children: [
        Container(
          width: width,
          height: 41,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 23 / 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDays(days),
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 23 / 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDays(double days) {
  if (days <= 0) return '0天';
  final text = days.toStringAsFixed(2);
  return '$text天';
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}

String _formatAxis(double value) {
  final rounded = value.round();
  if (rounded >= 10000) {
    final wan = value / 10000;
    return '${wan.toStringAsFixed(wan >= 100 ? 0 : 1)}万';
  }
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    buffer.write(text[i]);
    final remaining = text.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write(',');
  }
  return buffer.toString();
}
