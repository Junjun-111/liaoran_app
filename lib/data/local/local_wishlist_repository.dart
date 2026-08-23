import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

/// 心愿仓储的本地持久化实现：数据保存在手机本地，重启后自动恢复。
class LocalWishlistRepository implements WishlistRepository {
  LocalWishlistRepository._();

  static final LocalWishlistRepository instance =
      LocalWishlistRepository._();

  static const _storageKey = 'liaoran_wishes_v1';

  final List<WishlistItem> _items = [];
  bool _loaded = false;

  @override
  List<WishlistItem> get items => List.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(
            decoded.map(
              (item) => WishlistItem.fromJson(item as Map<String, dynamic>),
            ),
          );
      }
    } catch (_) {
      // 读取失败时保留空内存数据
    }
    _loaded = true;
  }

  @override
  void add(WishlistItem item) {
    _items.insert(0, item);
    unawaited(_persist());
  }

  @override
  void replaceAll(List<WishlistItem> items) {
    _items
      ..clear()
      ..addAll(items);
    unawaited(_persist());
  }

  @override
  void update(WishlistItem item) {
    final index = _items.indexWhere((w) => w.id == item.id);
    if (index >= 0) {
      _items[index] = item;
      unawaited(_persist());
    }
  }

  @override
  void remove(WishlistItem item) {
    _items.remove(item);
    unawaited(_persist());
  }

  @override
  void clear() {
    _items.clear();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode([for (final w in _items) w.toJson()]);
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // 写入失败时静默处理
    }
  }
}
