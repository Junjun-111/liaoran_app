/// 金额格式化工具（纯函数）。
///
/// 小数位数取自全局设置（默认 2 位），后续设置页可调。
class MoneyFormatter {
  MoneyFormatter._();

  /// 币种 → 符号映射
  static String currencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'HKD':
        return r'HK$';
      case 'GBP':
        return '£';
      default:
        return '¥';
    }
  }

  /// 格式化金额，如 ¥12000.00
  static String format(
    double value, {
    int decimals = 2,
    String currency = 'CNY',
  }) {
    return '${currencySymbol(currency)}${value.toStringAsFixed(decimals)}';
  }

  /// 带正负号的盈亏文案，如 +¥200.00 / -¥600.00
  static String signed(
    double value, {
    int decimals = 2,
    String currency = 'CNY',
  }) {
    final abs = format(value.abs(), decimals: decimals, currency: currency);
    return value < 0 ? '-$abs' : '+$abs';
  }
}
