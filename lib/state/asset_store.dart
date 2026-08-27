import 'package:flutter/foundation.dart';

import '../data/local/local_asset_repository.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../domain/repositories/asset_repository.dart';
import 'trash_store.dart';

/// 资产数据的全局存储（ChangeNotifier）。
///
/// 「添加资产」表单写入，数据持久化到手机本地，
/// 我的资产页监听渲染，首页看板消费统计。
class AssetStore extends ChangeNotifier {
  AssetStore._(this._repo);

  static final AssetStore instance =
      AssetStore._(LocalAssetRepository.instance);

  final AssetRepository _repo;

  /// 启动时从手机本地恢复资产数据。
  Future<void> load() async {
    await _repo.load();
    notifyListeners();
  }

  /// 只读资产列表（新添加的排在前面）
  List<Asset> get items => _repo.items;

  bool get isEmpty => _repo.isEmpty;

  /// 总资产净值：服役中 + 已退役的买入价合计（已卖出的不再计入）
  double get totalValue => _repo.items
      .where((a) => a.status != AssetLifecycleStatus.sold)
      .fold(0, (sum, a) => sum + a.purchasePrice);

  /// 服役中数量
  int get activeCount => _count(AssetLifecycleStatus.active);

  /// 已退役数量
  int get retiredCount => _count(AssetLifecycleStatus.retired);

  /// 已卖出数量
  int get soldCount => _count(AssetLifecycleStatus.sold);

  double _cachedDailyCost = 0;
  bool _dailyDirty = true;

  /// 全部资产日均成本合计（缓存，数据变化时才重算）
  double get dailyCost {
    if (_dailyDirty) {
      _cachedDailyCost = _repo.items.fold<double>(0, (sum, a) {
        final r = const CostPerDayCalculator().calculate(
          purchasePrice: a.purchasePrice,
          baseAmount: a.costBasis,
          purchaseDate: a.purchaseDate,
          status: a.status,
          retiredDate: a.retiredDate,
          salePrice: a.latestSale?.salePrice,
          saleDate: a.latestSale?.saleDate,
        );
        return sum + (r.costPerDay ?? 0);
      });
      _dailyDirty = false;
    }
    return _cachedDailyCost;
  }

  int _count(AssetLifecycleStatus status) =>
      _repo.items.where((a) => a.status == status).length;

  void _markDailyDirty() => _dailyDirty = true;

  void add(Asset asset) {
    _repo.add(asset);
    _markDailyDirty();
    notifyListeners();
  }

  /// 用给定列表整体替换现有数据，保持传入顺序不变（备份恢复用）。
  void replaceAll(List<Asset> assets) {
    _repo.replaceAll(assets);
    _markDailyDirty();
    notifyListeners();
  }

  void update(Asset asset) {
    _repo.update(asset);
    _markDailyDirty();
    notifyListeners();
  }

  void remove(Asset asset) {
    _repo.remove(asset);
    _markDailyDirty();
    notifyListeners();
  }

  /// 删除资产：先移入回收站（30 天内可恢复），再从列表移除。
  void moveToTrash(Asset asset) {
    TrashStore.instance.addToTrash(asset);
    _repo.remove(asset);
    _markDailyDirty();
    notifyListeners();
  }

  /// 清空全部资产（测试隔离 / 数据管理用）。
  void clear() {
    _repo.clear();
    _markDailyDirty();
    notifyListeners();
  }
}
