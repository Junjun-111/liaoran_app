import 'package:shared_preferences/shared_preferences.dart';

/// 应用锁状态（持久化到手机本地）：
/// - 是否已启用指纹锁；
/// - 首次安装引导是否已完成；
/// - 最近一次退到后台的时间（用于 30 分钟自动锁定）。
class LockGate {
  LockGate._();

  static const _enabledKey = 'lock_enabled';
  static const _firstRunKey = 'first_run_done';
  static const _backgroundKey = 'last_background_at';

  static bool _enabled = false;
  static bool _firstRunDone = false;
  static int _lastBackgroundAt = 0;

  /// 锁定页当前是否正显示在屏幕上（避免重复弹出锁定页）。
  static bool lockScreenShowing = false;

  static bool get enabled => _enabled;

  static bool get firstRunDone => _firstRunDone;

  /// 是否退到后台超过 30 分钟。
  static bool get backgroundedLong {
    if (_lastBackgroundAt <= 0) return false;
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(_lastBackgroundAt));
    return diff.inMinutes >= 30;
  }

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? false;
      _firstRunDone = prefs.getBool(_firstRunKey) ?? false;
      _lastBackgroundAt = prefs.getInt(_backgroundKey) ?? 0;
    } catch (_) {
      // 读取失败时保持默认值
    }
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
  }

  static Future<void> setFirstRunDone(bool value) async {
    _firstRunDone = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstRunKey, value);
    } catch (_) {}
  }

  /// 记录本次退到后台的时间。
  static Future<void> markBackground() async {
    _lastBackgroundAt = DateTime.now().millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backgroundKey, _lastBackgroundAt);
    } catch (_) {}
  }

  /// 回到前台后清除后台计时（避免下次短时间退后台再次触发）。
  static Future<void> clearBackground() async {
    _lastBackgroundAt = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backgroundKey, 0);
    } catch (_) {}
  }

  /// 立即锁定：把后台计时改成已超过 30 分钟，
  /// 无论用户多久回来，回前台时都会先要求指纹。
  static Future<void> lockNow() async {
    _lastBackgroundAt = DateTime.now()
        .subtract(const Duration(minutes: 31))
        .millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backgroundKey, _lastBackgroundAt);
    } catch (_) {}
  }
}
