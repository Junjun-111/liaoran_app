import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

/// 心愿仓储的内存实现。
class InMemoryWishlistRepository implements WishlistRepository {
  InMemoryWishlistRepository._();

  static final InMemoryWishlistRepository instance =
      InMemoryWishlistRepository._();

  final List<WishlistItem> _items = [];

  @override
  List<WishlistItem> get items => List.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  void add(WishlistItem item) {
    _items.insert(0, item);
  }

  @override
  void replaceAll(List<WishlistItem> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  void update(WishlistItem item) {
    final index = _items.indexWhere((w) => w.id == item.id);
    if (index >= 0) _items[index] = item;
  }

  @override
  void remove(WishlistItem item) {
    _items.remove(item);
  }

  @override
  void clear() {
    _items.clear();
  }
}
