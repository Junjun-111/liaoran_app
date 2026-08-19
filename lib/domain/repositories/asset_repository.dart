import '../models/asset.dart';

/// 资产仓储接口：资产数据的读写隔离层。
///
/// 当前阶段为内存实现，后续接入 Hive 时替换实现即可，
/// Store 对外接口保持不变。
abstract class AssetRepository {
  /// 从本地存储恢复资产数据。
  Future<void> load();

  /// 只读资产列表（新添加的排在前面）
  List<Asset> get items;

  bool get isEmpty;

  void add(Asset asset);

  /// 用给定列表整体替换现有数据，保持传入顺序不变。
  void replaceAll(List<Asset> assets);

  /// 按 [Asset.id] 整体替换（更新）
  void update(Asset asset);

  void remove(Asset asset);
  void clear();
}
