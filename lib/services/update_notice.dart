import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_version.dart';

/// 版本更新提示：仅在每次更新后的第一次打开时展示一次。
class UpdateNotice {
  UpdateNotice._();

  static const _key = 'last_seen_update_version';
  static String? _lastSeen;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSeen = prefs.getString(_key);
    } catch (_) {
      // 读取失败时视为从未记录
    }
  }

  /// 版本号与本地记录不一致即提示（覆盖从旧版本升级的用户）；
  /// 全新安装会在首次引导完成时自动标记为已看，不重复提示。
  static bool get shouldShow => _lastSeen != kAppVersion;

  /// 用户看完本次更新后记录当前版本，下次不再提示。
  static Future<void> markSeen() async {
    _lastSeen = kAppVersion;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, kAppVersion);
    } catch (_) {}
  }
}
