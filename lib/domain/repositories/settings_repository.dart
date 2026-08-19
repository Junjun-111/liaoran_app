/// 设置仓储接口：数据读写与未来持久化方案的隔离层。
///
/// 当前阶段按用户要求不引入数据库，由 [InMemorySettingsRepository]
/// 提供内存实现；后续接入 Hive 时，新增一个 Hive 实现并替换
/// Store 的注入即可，UI 与 Store 完全不需要改动。
abstract class SettingsRepository {
  // ── 数值与单位 ──
  String get currency;
  int get decimalPlaces;

  // ── 显示与外观 ──
  String get viewStyle;
  String get nickname;
  String? get avatarPath;

  // ── 数据管理 ──
  List<String> get categories;
  List<String> get tags;

  // ── 应用锁定 ──
  bool get lockEnabled;
  String get passcode;

  void updateCurrency(String value);
  void updateDecimalPlaces(int value);
  void updateViewStyle(String value);
  void updateNickname(String value);
  void updateAvatarPath(String? value);

  void addCategory(String name);
  void renameCategory(String oldName, String newName);
  void removeCategory(String name);

  void addTag(String name);
  void renameTag(String oldName, String newName);
  void removeTag(String name);

  void enableLock(String passcode);
  void disableLock();
}
