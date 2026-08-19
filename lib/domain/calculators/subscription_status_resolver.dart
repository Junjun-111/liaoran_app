/// 订阅状态自动判定（纯函数）。
///
/// 规则（用户确认）：只要过了设定日期（到期日），「生效中」自动变为「已过期」；
/// 未过期保持「生效中」；手动标记的「已取消 / 暂停中」不受影响。
class SubscriptionStatusResolver {
  SubscriptionStatusResolver._();

  static const active = '生效中';
  static const expired = '已过期';

  /// 计算展示用状态。
  ///
  /// [storedStatus] 表单中保存的状态；[expiryDate] 当前周期到期时间。
  /// [now] 可注入固定时间用于测试，默认当前时间。
  static String resolve({
    required String storedStatus,
    DateTime? expiryDate,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    if (storedStatus == active &&
        expiryDate != null &&
        _dateOnly(expiryDate).isBefore(_dateOnly(reference))) {
      return expired;
    }
    return storedStatus;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
