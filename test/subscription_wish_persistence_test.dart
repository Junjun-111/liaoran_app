// 订阅与心愿本地持久化：写入手机本地，格式可恢复。
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/data/local/local_subscription_repository.dart';
import 'package:liaoran_app/data/local/local_wishlist_repository.dart';
import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/models/subscription.dart';

void main() {
  test('订阅与心愿写入本地并可恢复', () async {
    SharedPreferences.setMockInitialValues({});

    final subRepo = LocalSubscriptionRepository.instance;
    subRepo.add(
      Subscription(
        id: 's1',
        name: 'Netflix',
        platform: 'Netflix',
        type: '自动续费',
        amount: 45,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 12, 31),
        status: '生效中',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final wishRepo = LocalWishlistRepository.instance;
    wishRepo.add(
      WishlistItem(
        id: 'w1',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        addDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final prefs = await SharedPreferences.getInstance();

    final subRaw = prefs.getString('liaoran_subscriptions_v1');
    expect(subRaw, isNotNull);
    expect(subRaw, contains('Netflix'));
    final subDecoded =
        (jsonDecode(subRaw!) as List).first as Map<String, dynamic>;
    expect(Subscription.fromJson(subDecoded).name, 'Netflix');

    final wishRaw = prefs.getString('liaoran_wishes_v1');
    expect(wishRaw, isNotNull);
    expect(wishRaw, contains('相机'));
    final wishDecoded =
        (jsonDecode(wishRaw!) as List).first as Map<String, dynamic>;
    expect(WishlistItem.fromJson(wishDecoded).name, '相机');
  });
}
