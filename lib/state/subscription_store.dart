import 'package:flutter/foundation.dart';

import '../data/local/local_subscription_repository.dart';
import '../domain/repositories/subscription_repository.dart';
import '../models/subscription.dart';

/// 订阅数据的全局内存存储（ChangeNotifier）。
///
/// 「添加订阅」表单写入，订阅管理页监听并渲染列表。
/// 数据读写委托给 [SubscriptionRepository]，当前为内存实现，
/// 后续接入持久化时替换仓储实现即可，本类对外接口不变。
class SubscriptionStore extends ChangeNotifier {
  SubscriptionStore._(this._repo);

  static final SubscriptionStore instance =
      SubscriptionStore._(LocalSubscriptionRepository.instance);

  final SubscriptionRepository _repo;

  /// 启动时从手机本地恢复订阅数据。
  Future<void> load() async {
    await _repo.load();
    notifyListeners();
  }

  /// 只读订阅列表（新添加的排在前面）
  List<Subscription> get items => _repo.items;

  bool get isEmpty => _repo.isEmpty;

  /// 全部订阅的月均合计
  double get totalMonthly =>
      _repo.items.fold(0, (sum, s) => sum + s.monthlyAmount);

  void add(Subscription subscription) {
    _repo.add(subscription);
    notifyListeners();
  }

  /// 用给定列表整体替换现有数据，保持传入顺序不变（备份恢复用）。
  void replaceAll(List<Subscription> subscriptions) {
    _repo.replaceAll(subscriptions);
    notifyListeners();
  }

  /// 编辑保存：按 id 替换
  void update(Subscription subscription) {
    _repo.update(subscription);
    notifyListeners();
  }

  void remove(Subscription subscription) {
    _repo.remove(subscription);
    notifyListeners();
  }

  /// 清空全部订阅（测试隔离 / 数据管理用）。
  void clear() {
    _repo.clear();
    notifyListeners();
  }
}
