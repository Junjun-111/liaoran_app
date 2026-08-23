import 'package:flutter/foundation.dart';

import '../data/local/local_trash_repository.dart';
import '../domain/models/asset.dart';

/// 回收站：删除的资产先进这里，30 天内可恢复，超期自动清除。
class TrashStore extends ChangeNotifier {
  TrashStore._(this._repo);

  static final TrashStore instance = TrashStore._(LocalTrashRepository.instance);

  static const _retention = Duration(days: 30);

  final LocalTrashRepository _repo;

  Future<void> load() async {
    await _repo.load();
    _purgeExpired();
    notifyListeners();
  }

  /// 回收站条目（新的在前）
  List<TrashEntry> get entries => _repo.entries;

  bool get isEmpty => _repo.entries.isEmpty;

  int get count => _repo.entries.length;

  /// 资产移入回收站
  void addToTrash(Asset asset) {
    _repo.add(TrashEntry(asset: asset, deletedAt: DateTime.now()));
    _purgeExpired();
    notifyListeners();
  }

  /// 恢复指定条目（从回收站移除，返回资产）
  Asset? restore(TrashEntry entry) {
    _repo.remove(entry);
    notifyListeners();
    return entry.asset;
  }

  /// 永久删除
  void deleteForever(TrashEntry entry) {
    _repo.remove(entry);
    notifyListeners();
  }

  /// 清空回收站
  void clear() {
    _repo.clear();
    notifyListeners();
  }

  /// 清理超过 30 天的条目
  void _purgeExpired() {
    final now = DateTime.now();
    for (final entry in _repo.entries.toList()) {
      if (now.difference(entry.deletedAt) > _retention) {
        _repo.remove(entry);
      }
    }
  }
}
