import '../models/asset_lifecycle_status.dart';

/// 日均成本计算结果（纯数据对象，UI 层只负责展示）。
///
/// 规则（与「有数」理念一致）：
/// - 服役中：日均成本 = 买入价 ÷ 使用天数（买入日 → 今天）
/// - 已退役：日均成本 = 买入价 ÷ 使用天数（买入日 → 退役日）
/// - 已卖出：日均成本 = (买入价 − 卖出价) ÷ 使用天数（买入日 → 卖出日），
///   卖出价高于买入价时按 0 处理并标记为盈利
/// - 回本：日均成本 ≤ 目标日均成本；进度 = 目标 ÷ 实际（上限 100%）
class CostPerDayResult {
  const CostPerDayResult({
    required this.daysUsed,
    required this.costPerDay,
    required this.targetCpd,
    required this.isPaidBack,
    required this.paybackProgress,
    required this.daysToPayback,
    required this.profitLoss,
    required this.retentionRate,
    required this.isProfit,
  });

  /// 使用天数（买入日 → 状态结束日 / 今天；非法输入时为 0）
  final int daysUsed;

  /// 日均成本；无法计算（价格缺失、天数为 0、日期非法）时为 null
  final double? costPerDay;

  /// 目标日均成本（未设置或非法时为 null）
  final double? targetCpd;

  /// 是否已回本（未设置目标或无法计算时为 null）
  final bool? isPaidBack;

  /// 回本进度 0.0~1.0（未设置目标或无法计算时为 null）
  final double? paybackProgress;

  /// 距离回本还需的天数（仅服役中且未回本时 > 0，其余为 0）
  final int daysToPayback;

  /// 卖出盈亏 = 卖出价 − 买入价（未卖出 / 未记录卖出价时为 null）
  final double? profitLoss;

  /// 保值率 = 卖出价 ÷ 买入价（未卖出 / 未记录卖出价时为 null）
  final double? retentionRate;

  /// 是否盈利（卖出价 > 买入价）
  final bool isProfit;
}

/// 日均成本计算引擎（纯函数，无 Flutter 依赖，可单测）。
///
/// [referenceDate] 可注入固定日期用于测试；默认使用当前时间。
class CostPerDayCalculator {
  const CostPerDayCalculator({this.referenceDate});

  /// 可注入的“今天”；测试传固定日期保证结果可复现，默认 null 表示用当前时间。
  final DateTime? referenceDate;

  /// 计算日均成本与回本/盈亏指标。
  ///
  /// 参数约定：
  /// - [purchasePrice] 买入价（<= 0 视为未填写，不计算）
  /// - [purchaseDate] 买入日期
  /// - [status] 当前生命周期状态
  /// - [retiredDate] 退役日期（仅 [AssetLifecycleStatus.retired] 使用）
  /// - [salePrice] / [saleDate] 卖出价与卖出日期（仅 sold 使用；
  ///   卖出价未填时按“只算持有成本”处理，卖出日期未填时按今天截止）
  /// - [targetCpd] 目标日均成本（<= 0 视为未设置）
  CostPerDayResult calculate({
    required double purchasePrice,
    required DateTime purchaseDate,
    required AssetLifecycleStatus status,
    DateTime? retiredDate,
    double? salePrice,
    DateTime? saleDate,
    double? targetCpd,
  }) {
    final ref = _dateOnly(referenceDate ?? DateTime.now());
    final buy = _dateOnly(purchaseDate);

    // ── 使用天数 ──────────────────────────────────────────────────
    int? days;
    switch (status) {
      case AssetLifecycleStatus.active:
        days = buy.isAfter(ref) ? null : ref.difference(buy).inDays;
      case AssetLifecycleStatus.retired:
        days = retiredDate == null ? null : _daysBetween(buy, retiredDate);
      case AssetLifecycleStatus.sold:
        final end = saleDate == null ? ref : _dateOnly(saleDate);
        days = _daysBetween(buy, end);
    }

    // ── 日均成本 ──────────────────────────────────────────────────
    double? costPerDay;
    if (purchasePrice > 0 && days != null && days > 0) {
      if (status == AssetLifecycleStatus.sold &&
          salePrice != null &&
          salePrice >= 0) {
        final net = purchasePrice - salePrice;
        costPerDay = net <= 0 ? 0.0 : net / days;
      } else {
        costPerDay = purchasePrice / days;
      }
    }

    // ── 卖出盈亏 / 保值率 ────────────────────────────────────────
    double? profitLoss;
    double? retentionRate;
    var isProfit = false;
    if (status == AssetLifecycleStatus.sold &&
        salePrice != null &&
        salePrice >= 0 &&
        purchasePrice > 0) {
      profitLoss = salePrice - purchasePrice;
      retentionRate = salePrice / purchasePrice;
      isProfit = salePrice > purchasePrice;
    }

    // ── 回本判定与进度 ────────────────────────────────────────────
    bool? isPaidBack;
    double? paybackProgress;
    var daysToPayback = 0;
    final hasTarget = targetCpd != null && targetCpd > 0;
    if (hasTarget && costPerDay != null) {
      isPaidBack = costPerDay <= targetCpd;
      paybackProgress = costPerDay <= 0
          ? 1.0
          : (targetCpd / costPerDay).clamp(0.0, 1.0).toDouble();
      if (status == AssetLifecycleStatus.active && !isPaidBack && days != null) {
        final totalDaysNeeded = (purchasePrice / targetCpd).ceil();
        final remaining = totalDaysNeeded - days;
        daysToPayback = remaining < 0 ? 0 : remaining;
      }
    }

    return CostPerDayResult(
      daysUsed: days ?? 0,
      costPerDay: costPerDay,
      targetCpd: hasTarget ? targetCpd : null,
      isPaidBack: isPaidBack,
      paybackProgress: paybackProgress,
      daysToPayback: daysToPayback,
      profitLoss: profitLoss,
      retentionRate: retentionRate,
      isProfit: isProfit,
    );
  }

  /// 两个日期之间的整天天数；结束日早于开始日时返回 null。
  static int? _daysBetween(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    if (e.isBefore(s)) return null;
    return e.difference(s).inDays;
  }

  /// 归一化到当天 0 点，忽略时分秒，保证天数计算稳定。
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
