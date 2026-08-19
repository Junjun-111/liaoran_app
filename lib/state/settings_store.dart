import 'package:flutter/foundation.dart';

import '../data/in_memory/in_memory_settings_repository.dart';
import '../domain/repositories/settings_repository.dart';

/// 全局设置的内存存储（ChangeNotifier）。
///
/// 对应用户「个人中心」页的全部设置项：
/// - 数值与单位：货币单位、小数点位数
/// - 数据管理：分类、标签、坚果云同步
/// - 显示与外观：功能视图样式（双列/单列）
/// - 应用锁定：开关与密码
///
/// 当前阶段按用户要求**不引入数据库**，数据保存在内存中；
/// 后续接入本地持久化时，仅替换本类内部读写实现，
/// 对外接口（字段 + notifyListeners）保持不变。
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._repo);

  static final SettingsStore instance =
      SettingsStore._(InMemorySettingsRepository.instance);

  final SettingsRepository _repo;

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

  // ── 数值与单位 ────────────────────────────────────────────────

  void updateCurrency(String value) {
    _repo.updateCurrency(value);
    notifyListeners();
  }

  void updateDecimalPlaces(int value) {
    _repo.updateDecimalPlaces(value);
    notifyListeners();
  }

  // ── 显示与外观 ────────────────────────────────────────────────

  void updateViewStyle(String value) {
    _repo.updateViewStyle(value);
    notifyListeners();
  }

  void updateNickname(String value) {
    _repo.updateNickname(value);
    notifyListeners();
  }

  void updateAvatarPath(String? value) {
    _repo.updateAvatarPath(value);
    notifyListeners();
  }

  // ── 分类管理 ──────────────────────────────────────────────────

  void addCategory(String name) {
    _repo.addCategory(name);
    notifyListeners();
  }

  void renameCategory(String oldName, String newName) {
    _repo.renameCategory(oldName, newName);
    notifyListeners();
  }

  void removeCategory(String name) {
    _repo.removeCategory(name);
    notifyListeners();
  }

  // ── 标签管理 ──────────────────────────────────────────────────

  void addTag(String name) {
    _repo.addTag(name);
    notifyListeners();
  }

  void renameTag(String oldName, String newName) {
    _repo.renameTag(oldName, newName);
    notifyListeners();
  }

  void removeTag(String name) {
    _repo.removeTag(name);
    notifyListeners();
  }

  // ── 应用锁定 ──────────────────────────────────────────────────

  void enableLock(String passcode) {
    _repo.enableLock(passcode);
    notifyListeners();
  }

  void disableLock() {
    _repo.disableLock();
    notifyListeners();
  }
}
