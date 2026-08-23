import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../../models/subscription.dart';

/// 订阅仓储的本地持久化实现：数据保存在手机本地，重启后自动恢复。
class LocalSubscriptionRepository implements SubscriptionRepository {
  LocalSubscriptionRepository._();

  static final LocalSubscriptionRepository instance =
      LocalSubscriptionRepository._();

  static const _storageKey = 'liaoran_subscriptions_v1';

  final List<Subscription> _items = [];
  bool _loaded = false;

  @override
  List<Subscription> get items => List.unmodifiable(_items);

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
              (item) => Subscription.fromJson(item as Map<String, dynamic>),
            ),
          );
      }
    } catch (_) {
      // 读取失败时保留空内存数据
    }
    _loaded = true;
  }

  @override
  void add(Subscription subscription) {
    _items.insert(0, subscription);
    unawaited(_persist());
  }

  @override
  void replaceAll(List<Subscription> subscriptions) {
    _items
      ..clear()
      ..addAll(subscriptions);
    unawaited(_persist());
  }

  @override
  void update(Subscription subscription) {
    final index = _items.indexWhere((s) => s.id == subscription.id);
    if (index >= 0) {
      _items[index] = subscription;
      unawaited(_persist());
    }
  }

  @override
  void remove(Subscription subscription) {
    _items.remove(subscription);
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
      final raw = jsonEncode([for (final s in _items) s.toJson()]);
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // 写入失败时静默处理
    }
  }
}
