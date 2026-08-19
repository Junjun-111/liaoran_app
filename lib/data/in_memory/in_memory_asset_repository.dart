import '../../domain/models/asset.dart';
import '../../domain/repositories/asset_repository.dart';

/// 资产仓储的内存实现（当前阶段默认）。
///
/// 数据仅保存在内存中，应用重启后清空；
/// 用户后续要求接入持久化时，用 Hive 实现替换本类。
class InMemoryAssetRepository implements AssetRepository {
  InMemoryAssetRepository._();

  static final InMemoryAssetRepository instance =
      InMemoryAssetRepository._();

  final List<Asset> _items = [];

  @override
  Future<void> load() async {
    // 内存实现无需读取本地数据。
  }

  @override
  List<Asset> get items => List.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  void add(Asset asset) {
    _items.insert(0, asset);
  }

  @override
  void replaceAll(List<Asset> assets) {
    _items
      ..clear()
      ..addAll(assets);
  }

  @override
  void update(Asset asset) {
    final index = _items.indexWhere((a) => a.id == asset.id);
    if (index >= 0) _items[index] = asset;
  }

  @override
  void remove(Asset asset) {
    _items.remove(asset);
  }

  @override
  void clear() {
    _items.clear();
  }
}
