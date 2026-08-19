/// 领域常量字典：集中管理全 App 的选项列表。
///
/// 取值与现有页面（添加流程页 / 个人中心）完全一致，
/// 避免同一份选项散落在多个页面硬编码，后续接入数据库时
/// 也只需替换数据来源，选项本身不变。
class Dictionaries {
  Dictionaries._();

  // ── 资产 ──────────────────────────────────────────────────────

  /// 资产分类（添加资产表单 + 分类管理共用）
  static const List<String> assetCategories = [
    '数码设备',
    '家电',
    '交通工具',
    '家居',
    '服装',
    '其他',
  ];

  /// 资产生命周期状态
  static const List<String> assetStatuses = ['服役中', '已退役', '已卖出'];

  // ── 订阅 ──────────────────────────────────────────────────────

  /// 订阅类型
  static const List<String> subscriptionTypes = ['自动续费', '买断', '一次性'];

  /// 扣款周期
  static const List<String> subscriptionCycles = ['包月', '包季', '包年', '无'];

  /// 订阅状态
  static const List<String> subscriptionStatuses = [
    '生效中',
    '已过期',
    '已取消',
    '暂停中',
  ];

  /// 订阅平台
  static const List<String> subscriptionPlatforms = ['苹果', '自定义'];

  // ── 数值与单位 ────────────────────────────────────────────────

  /// 币种
  static const List<String> currencies = [
    'CNY',
    'USD',
    'EUR',
    'JPY',
    'HKD',
    'GBP',
    '其他',
  ];

  /// 小数点位数选项
  static const List<int> decimalPlaces = [0, 1, 2];

  // ── 显示与外观 ────────────────────────────────────────────────

  /// 功能视图样式
  static const List<String> viewStyles = ['双列', '单列'];

  // ── 数据管理 ──────────────────────────────────────────────────

  /// 默认标签字典（由用户自行定义，默认留空）
  static const List<String> defaultTags = [];
}
