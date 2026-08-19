import '../models/asset.dart';
import '../models/asset_lifecycle_status.dart';

/// 分析页时间范围。
enum AnalyticsRange {
  all('全部', null),
  week('最近一周', 7),
  days90('最近90天', 90),
  days180('最近180天', 180),
  year('最近一年', 365);

  const AnalyticsRange(this.label, this.days);

  final String label;
  final int? days;
}

/// 资产总值摘要。
class AssetValueSummary {
  const AssetValueSummary({
    required this.total,
    required this.active,
    required this.retired,
    required this.sold,
  });

  final double total;
  final double active;
  final double retired;
  final double sold;

  double ratioOf(double value) => total <= 0 ? 0 : value / total;
}

/// 类型分布切片。
class CategorySlice {
  const CategorySlice({required this.category, required this.value});

  final String category;
  final double value;
}

/// 标签统计。
class TagStat {
  const TagStat({
    required this.tag,
    required this.count,
    required this.averageHoldingDays,
  });

  final String tag;
  final int count;
  final double averageHoldingDays;
}

/// 趋势折线点。
class TrendPoint {
  const TrendPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class AssetAnalytics {
  AssetAnalytics._();

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 当前时间范围内是否至少有一笔新购入的资产。
  static bool hasNewAssetsInRange(
    List<Asset> assets,
    int days, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final start = current.subtract(Duration(days: days));
    for (final asset in assets) {
      if (_dateInRange(asset.purchaseDate, start, current)) {
        return true;
      }
    }
    return false;
  }

  /// 选择用于分析的数据。
  ///
  /// “全部”直接返回全部；时间范围没有变化时也返回全部，
  /// 因为产品要求：没有变化时仍展示全部资产。
  static List<Asset> selectAssets(
    List<Asset> assets,
    AnalyticsRange range, {
    DateTime? now,
  }) {
    final days = range.days;
    if (days == null) return List<Asset>.of(assets);

    final current = now ?? DateTime.now();
    final start = current.subtract(Duration(days: days));
    final changed = assets
        .where((asset) => _dateInRange(asset.purchaseDate, start, current))
        .toList();

    return changed.isEmpty ? List<Asset>.of(assets) : changed;
  }

  static bool _dateInRange(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    final value = normalizeDate(date);
    return !value.isBefore(normalizeDate(start)) &&
        !value.isAfter(normalizeDate(end));
  }

  /// 单个资产参与分析的金额：
  /// 未卖出按买入价，已卖出按最新卖出价（无卖出记录按买入价）。
  static double valueOf(Asset asset) {
    if (asset.status == AssetLifecycleStatus.sold) {
      return asset.latestSale?.salePrice ?? asset.purchasePrice;
    }
    return asset.purchasePrice;
  }

  static AssetValueSummary summarize(List<Asset> assets) {
    var active = 0.0;
    var retired = 0.0;
    var sold = 0.0;

    for (final asset in assets) {
      final value = valueOf(asset);
      switch (asset.status) {
        case AssetLifecycleStatus.active:
          active += value;
          break;
        case AssetLifecycleStatus.retired:
          retired += value;
          break;
        case AssetLifecycleStatus.sold:
          sold += value;
          break;
      }
    }

    return AssetValueSummary(
      total: active + retired + sold,
      active: active,
      retired: retired,
      sold: sold,
    );
  }

  static List<CategorySlice> categoryDistribution(List<Asset> assets) {
    final values = <String, double>{};
    for (final asset in assets) {
      final category = asset.category.isEmpty ? '其他' : asset.category;
      values[category] = (values[category] ?? 0) + valueOf(asset);
    }

    final result =
        values.entries
            .map((e) => CategorySlice(category: e.key, value: e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  /// 标签统计：以用户维护的标签字典为主，同时包含资产上实际使用但字典中还没有的标签。
  static List<TagStat> tagDistribution(
    List<Asset> assets,
    List<String> knownTags, {
    DateTime? now,
  }) {
    final orderedTags = <String>[];
    final seen = <String>{};
    for (final tag in [...knownTags, ...assets.expand((a) => a.tags)]) {
      if (seen.add(tag)) orderedTags.add(tag);
    }

    return [
      for (final tag in orderedTags)
        TagStat(
          tag: tag,
          count: assets.where((a) => a.tags.contains(tag)).length,
          averageHoldingDays: averageHoldingDaysForTag(assets, tag, now: now),
        ),
    ];
  }

  static double averageHoldingDaysForTag(
    List<Asset> assets,
    String tag, {
    DateTime? now,
  }) {
    final durations = [
      for (final asset in assets)
        if (asset.tags.contains(tag)) holdingDays(asset, now: now),
    ];
    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// 所有有资产的标签的平均服役时长；各标签先算平均，再取这些标签的平均。
  static double overallAverageHoldingDays(
    List<Asset> assets,
    List<String> knownTags, {
    DateTime? now,
  }) {
    final stats = tagDistribution(
      assets,
      knownTags,
      now: now,
    ).where((s) => s.count > 0).toList();
    if (stats.isEmpty) return 0;
    return stats.map((s) => s.averageHoldingDays).reduce((a, b) => a + b) /
        stats.length;
  }

  static double holdingDays(Asset asset, {DateTime? now}) {
    final start = normalizeDate(asset.purchaseDate);
    final end = switch (asset.status) {
      AssetLifecycleStatus.sold =>
        asset.latestSale?.saleDate ?? asset.purchaseDate,
      AssetLifecycleStatus.retired =>
        asset.retiredDate ?? (now ?? DateTime.now()),
      AssetLifecycleStatus.active => now ?? DateTime.now(),
    };

    final normalizedEnd = normalizeDate(end);
    if (normalizedEnd.isBefore(start)) return 0;
    return normalizedEnd.difference(start).inMilliseconds /
        Duration.millisecondsPerDay;
  }

  static List<TrendPoint> valueTrend(List<Asset> assets) {
    final events = <_ValueEvent>[];
    for (final asset in assets) {
      events.add(_ValueEvent(asset.purchaseDate, asset.purchasePrice));
      final latestSale = asset.latestSale;
      if (asset.status == AssetLifecycleStatus.sold && latestSale != null) {
        events.add(
          _ValueEvent(
            latestSale.saleDate,
            latestSale.salePrice - asset.purchasePrice,
          ),
        );
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    if (events.isEmpty) return const [];

    final byDate = <DateTime, double>{};
    for (final event in events) {
      final key = normalizeDate(event.date);
      byDate[key] = (byDate[key] ?? 0) + event.delta;
    }

    final dates = byDate.keys.toList()..sort();
    final result = <TrendPoint>[];
    var current = 0.0;
    for (final date in dates) {
      current += byDate[date]!;
      result.add(TrendPoint(date: date, value: current));
    }
    return result;
  }
}

class _ValueEvent {
  const _ValueEvent(this.date, this.delta);

  final DateTime date;
  final double delta;
}
