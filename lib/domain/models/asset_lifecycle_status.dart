/// 资产生命周期状态（领域模型）。
///
/// 与界面上的中文文案一一对应（见 `Dictionaries.assetStatuses`），
/// 计算引擎等纯逻辑一律使用枚举，避免魔法字符串。
enum AssetLifecycleStatus {
  active('服役中'),
  retired('已退役'),
  sold('已卖出');

  const AssetLifecycleStatus(this.label);

  /// 中文文案
  final String label;

  /// 根据中文文案反查枚举；未知文案回退为 [active]。
  static AssetLifecycleStatus fromLabel(String label) => values.firstWhere(
        (s) => s.label == label,
        orElse: () => AssetLifecycleStatus.active,
      );

  /// 全部中文文案（用于下拉 / 胶囊选项）。
  static List<String> get labels => values.map((s) => s.label).toList();
}
