import '../../domain/repositories/subscription_repository.dart';
import '../../models/subscription.dart';

/// 订阅仓储的内存实现（当前阶段默认）。
///
/// 数据仅保存在内存中，应用重启后清空；
/// 用户后续要求接入持久化时，用 Hive 实现替换本类。
class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository._();

  static final InMemorySubscriptionRepository instance =
      InMemorySubscriptionRepository._();

  final List<Subscription> _items = [];

  @override
  List<Subscription> get items => List.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  void add(Subscription subscription) {
    _items.insert(0, subscription);
  }

  @override
  void replaceAll(List<Subscription> subscriptions) {
    _items
      ..clear()
      ..addAll(subscriptions);
  }

  @override
  void update(Subscription subscription) {
    final index = _items.indexWhere((s) => s.id == subscription.id);
    if (index >= 0) _items[index] = subscription;
  }

  @override
  void remove(Subscription subscription) {
    _items.remove(subscription);
  }

  @override
  void clear() {
    _items.clear();
  }
}
