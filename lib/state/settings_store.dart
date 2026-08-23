import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/in_memory/in_memory_settings_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../services/lock_gate.dart';

/// 全局设置（ChangeNotifier）+ 手机本地持久化。
///
/// 对应用户「个人中心」页的全部设置项：
/// - 数值与单位：货币单位、小数点位数
/// - 数据管理：分类、标签、坚果云同步
/// - 显示与外观：功能视图样式（双列/单列）
/// - 应用锁定：开关与密码
///
/// 分类 / 标签等修改会立即写入手机本地（SharedPreferences），
/// 下次启动自动恢复，不再因重启而丢失。
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._repo);

  static final SettingsStore instance =
      SettingsStore._(InMemorySettingsRepository.instance);

  static const _storageKey = 'liaoran_settings_v1';

  final SettingsRepository _repo;

  /// 串行写入队列：避免快速连续修改时并发覆盖
  Future<void> _writeQueue = Future.value();

  /// 启动时从手机本地恢复设置（货币、分类、标签等），失败则保留默认值。
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;

      final currency = map['currency'] as String?;
      if (currency != null) _repo.updateCurrency(currency);
      final decimals = map['decimalPlaces'] as num?;
      if (decimals != null) _repo.updateDecimalPlaces(decimals.toInt());
      final viewStyle = map['viewStyle'] as String?;
      if (viewStyle != null) _repo.updateViewStyle(viewStyle);
      final nickname = map['nickname'] as String?;
      if (nickname != null && nickname.trim().isNotEmpty) {
        _repo.updateNickname(nickname);
      }
      final avatarPath = map['avatarPath'] as String?;
      if (avatarPath != null) _repo.updateAvatarPath(avatarPath);
      final autoBackup = map['autoBackupEnabled'] as bool?;
      if (autoBackup != null) _repo.updateAutoBackupEnabled(autoBackup);
      final lastAutoBackup = map['lastAutoBackupAt'] as String?;
      if (lastAutoBackup != null) {
        _repo.updateLastAutoBackupAt(DateTime.tryParse(lastAutoBackup));
      }

      // 分类 / 标签：用本地保存的完整列表替换默认字典
      final categories = (map['categories'] as List?)?.whereType<String>().toList();
      if (categories != null) {
        for (final c in _repo.categories.toList()) {
          if (!categories.contains(c)) _repo.removeCategory(c);
        }
        for (final c in categories) {
          if (!_repo.categories.contains(c)) _repo.addCategory(c);
        }
      }
      final tags = (map['tags'] as List?)?.whereType<String>().toList();
      if (tags != null) {
        for (final t in _repo.tags.toList()) {
          if (!tags.contains(t)) _repo.removeTag(t);
        }
        for (final t in tags) {
          if (!_repo.tags.contains(t)) _repo.addTag(t);
        }
      }
    } catch (_) {
      // 读取失败时保留默认值，不影响启动
    }
    notifyListeners();
  }

  /// 把当前设置写入手机本地（串行执行）。
  void _persist() {
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _storageKey,
          jsonEncode({
            'currency': currency,
            'decimalPlaces': decimalPlaces,
            'viewStyle': viewStyle,
            'nickname': nickname,
            'avatarPath': avatarPath,
            'autoBackupEnabled': autoBackupEnabled,
            'lastAutoBackupAt': lastAutoBackupAt?.toIso8601String(),
            'categories': categories,
            'tags': tags,
          }),
        );
      } catch (_) {
        // 写入失败静默处理，下次变更会再次尝试
      }
    });
  }

  // ── 数值与单位 ────────────────────────────────────────────────

  /// 货币单位（默认 CNY）
  String get currency => _repo.currency;

  /// 小数点位数（0 / 1 / 2 / 3）
  int get decimalPlaces => _repo.decimalPlaces;

  // ── 显示与外观 ────────────────────────────────────────────────

  /// 功能视图样式：双列 / 单列
  String get viewStyle => _repo.viewStyle;

  /// 用户昵称（默认「了然用户」）
  String get nickname => _repo.nickname;

  /// 自定义头像本地路径；null 表示使用默认头像
  String? get avatarPath => _repo.avatarPath;

  // ── 数据管理：分类与标签字典 ──────────────────────────────────

  /// 资产分类字典（只读视图）
  List<String> get categories => _repo.categories;

  /// 标签字典（只读视图）
  List<String> get tags => _repo.tags;

  // ── 应用锁定 ──────────────────────────────────────────────────

  /// 是否开启应用锁定
  bool get lockEnabled => _repo.lockEnabled;

  /// 锁定密码
  String get passcode => _repo.passcode;

  // ── 备份 ──────────────────────────────────────────────────────

  /// 是否开启每周自动备份到坚果云
  bool get autoBackupEnabled => _repo.autoBackupEnabled;

  /// 上次自动备份成功时间；null 表示从未自动备份
  DateTime? get lastAutoBackupAt => _repo.lastAutoBackupAt;

  // ── 数值与单位 ────────────────────────────────────────────────

  void updateCurrency(String value) {
    _repo.updateCurrency(value);
    _persist();
    notifyListeners();
  }

  void updateDecimalPlaces(int value) {
    _repo.updateDecimalPlaces(value);
    _persist();
    notifyListeners();
  }

  // ── 显示与外观 ────────────────────────────────────────────────

  void updateViewStyle(String value) {
    _repo.updateViewStyle(value);
    _persist();
    notifyListeners();
  }

  void updateNickname(String value) {
    _repo.updateNickname(value);
    _persist();
    notifyListeners();
  }

  void updateAvatarPath(String? value) {
    _repo.updateAvatarPath(value);
    _persist();
    notifyListeners();
  }

  // ── 分类管理 ──────────────────────────────────────────────────

  void addCategory(String name) {
    _repo.addCategory(name);
    _persist();
    notifyListeners();
  }

  void renameCategory(String oldName, String newName) {
    _repo.renameCategory(oldName, newName);
    _persist();
    notifyListeners();
  }

  void removeCategory(String name) {
    _repo.removeCategory(name);
    _persist();
    notifyListeners();
  }

  // ── 标签管理 ──────────────────────────────────────────────────

  void addTag(String name) {
    _repo.addTag(name);
    _persist();
    notifyListeners();
  }

  void renameTag(String oldName, String newName) {
    _repo.renameTag(oldName, newName);
    _persist();
    notifyListeners();
  }

  void removeTag(String name) {
    _repo.removeTag(name);
    _persist();
    notifyListeners();
  }

  // ── 应用锁定 ──────────────────────────────────────────────────

  void enableLock(String passcode) {
    _repo.enableLock(passcode);
    // 同步持久化，冷启动/后台 30 分钟锁定依赖此状态
    LockGate.setEnabled(true);
    notifyListeners();
  }

  void disableLock() {
    _repo.disableLock();
    LockGate.setEnabled(false);
    notifyListeners();
  }

  // ── 备份设置 ─────────────────────────────────────────────────

  void updateAutoBackupEnabled(bool enabled) {
    _repo.updateAutoBackupEnabled(enabled);
    _persist();
    notifyListeners();
  }

  void updateLastAutoBackupAt(DateTime? time) {
    _repo.updateLastAutoBackupAt(time);
    _persist();
    notifyListeners();
  }
}
