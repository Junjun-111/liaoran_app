import '../../domain/dictionaries.dart';
import '../../domain/repositories/settings_repository.dart';

/// 设置仓储的内存实现（当前阶段默认）。
///
/// 所有写操作带输入校验：无效值直接忽略（空字符串、重复分类、
/// 越界小数位数等），保证 Store 拿到的始终是合法状态。
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository._();

  static final InMemorySettingsRepository instance =
      InMemorySettingsRepository._();

  String _currency = 'CNY';
  int _decimalPlaces = 2;
  // 默认单列列表（与 Figma 原始列表样式一致；双列可在设置中切换）
  String _viewStyle = '双列';
  String _nickname = '了然用户';
  String? _avatarPath;
  final List<String> _categories = [...Dictionaries.assetCategories];
  final List<String> _tags = [...Dictionaries.defaultTags];
  bool _lockEnabled = false;
  String _passcode = '';

  @override
  String get currency => _currency;

  @override
  int get decimalPlaces => _decimalPlaces;

  @override
  String get viewStyle => _viewStyle;

  @override
  String get nickname => _nickname;

  @override
  String? get avatarPath => _avatarPath;

  @override
  List<String> get categories => List.unmodifiable(_categories);

  @override
  List<String> get tags => List.unmodifiable(_tags);

  @override
  bool get lockEnabled => _lockEnabled;

  @override
  String get passcode => _passcode;

  @override
  void updateCurrency(String value) {
    if (value.isEmpty || !Dictionaries.currencies.contains(value)) return;
    _currency = value;
  }

  @override
  void updateDecimalPlaces(int value) {
    if (!Dictionaries.decimalPlaces.contains(value)) return;
    _decimalPlaces = value;
  }

  @override
  void updateViewStyle(String value) {
    if (!Dictionaries.viewStyles.contains(value)) return;
    _viewStyle = value;
  }

  @override
  void updateNickname(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _nickname = trimmed;
  }

  @override
  void updateAvatarPath(String? value) {
    _avatarPath = value;
  }

  @override
  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _categories.contains(trimmed)) return;
    _categories.add(trimmed);
  }

  @override
  void renameCategory(String oldName, String newName) {
    final trimmed = newName.trim();
    final index = _categories.indexOf(oldName);
    if (index < 0 || trimmed.isEmpty || _categories.contains(trimmed)) return;
    _categories[index] = trimmed;
  }

  @override
  void removeCategory(String name) {
    _categories.remove(name);
  }

  @override
  void addTag(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    _tags.add(trimmed);
  }

  @override
  void renameTag(String oldName, String newName) {
    final trimmed = newName.trim();
    final index = _tags.indexOf(oldName);
    if (index < 0 || trimmed.isEmpty || _tags.contains(trimmed)) return;
    _tags[index] = trimmed;
  }

  @override
  void removeTag(String name) {
    _tags.remove(name);
  }

  @override
  void enableLock(String passcode) {
    _passcode = passcode;
    _lockEnabled = true;
  }

  @override
  void disableLock() {
    _passcode = '';
    _lockEnabled = false;
  }
}
