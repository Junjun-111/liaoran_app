import '../../models/subscription.dart';

/// 订阅仓储接口：订阅数据的读写隔离层。
///
/// 当前阶段为内存实现，后续接入 Hive 时替换实现即可，
/// Store 对外接口保持不变。
abstract class SubscriptionRepository {
  /// 只读订阅列表（新添加的排在前面）
  List<Subscription> get items;

  /// 启动时从本地恢复订阅数据。
  Future<void> load();

  bool get isEmpty;

  void add(Subscription subscription);

  /// 用给定列表整体替换现有数据，保持传入顺序不变。
  void replaceAll(List<Subscription> subscriptions);

  /// 按 [Subscription.id] 整体替换（编辑保存）
  void update(Subscription subscription);

  void remove(Subscription subscription);
  void clear();
}
