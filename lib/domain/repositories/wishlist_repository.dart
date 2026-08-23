import '../models/wishlist_item.dart';

/// 心愿仓储接口：数据读写隔离层（当前为内存实现，后续可换 Hive）。
abstract class WishlistRepository {
  List<WishlistItem> get items;
  bool get isEmpty;

  /// 启动时从本地恢复心愿数据。
  Future<void> load();

  void add(WishlistItem item);

  /// 用给定列表整体替换现有数据，保持传入顺序不变。
  void replaceAll(List<WishlistItem> items);

  void update(WishlistItem item);
  void remove(WishlistItem item);
  void clear();
}
