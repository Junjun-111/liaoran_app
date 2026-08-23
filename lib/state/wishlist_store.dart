import 'package:flutter/foundation.dart';

import '../data/local/local_wishlist_repository.dart';
import '../domain/models/wishlist_item.dart';
import '../domain/repositories/wishlist_repository.dart';

/// 心愿数据的全局内存存储（ChangeNotifier）。
class WishlistStore extends ChangeNotifier {
  WishlistStore._(this._repo);

  static final WishlistStore instance =
      WishlistStore._(LocalWishlistRepository.instance);

  final WishlistRepository _repo;

  /// 启动时从手机本地恢复心愿数据。
  Future<void> load() async {
    await _repo.load();
    notifyListeners();
  }

  List<WishlistItem> get items => _repo.items;
  bool get isEmpty => _repo.isEmpty;

  /// 进行中心愿数量
  int get activeCount => _repo.items.where((w) => !w.completed).length;

  /// 已完成心愿数量
  int get completedCount => _repo.items.where((w) => w.completed).length;

  void add(WishlistItem item) {
    _repo.add(item);
    notifyListeners();
  }

  /// 用给定列表整体替换现有数据，保持传入顺序不变（备份恢复用）。
  void replaceAll(List<WishlistItem> items) {
    _repo.replaceAll(items);
    notifyListeners();
  }

  void update(WishlistItem item) {
    _repo.update(item);
    notifyListeners();
  }

  void remove(WishlistItem item) {
    _repo.remove(item);
    notifyListeners();
  }

  void clear() {
    _repo.clear();
    notifyListeners();
  }
}
