// 订阅状态自动判定 + 订阅页汇总/筛选测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/calculators/subscription_status_resolver.dart';
import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/pages/subscription_page.dart';
import 'package:liaoran_app/state/subscription_store.dart';

void main() {
  group('SubscriptionStatusResolver', () {
    test('到期日未过保持生效中（当天也算生效）', () {
      expect(
        SubscriptionStatusResolver.resolve(
          storedStatus: '生效中',
          expiryDate: DateTime(2026, 8, 18),
          now: DateTime(2026, 8, 18),
        ),
        '生效中',
      );
    });

    test('过了到期日自动变为已过期', () {
      expect(
        SubscriptionStatusResolver.resolve(
          storedStatus: '生效中',
          expiryDate: DateTime(2026, 8, 17),
          now: DateTime(2026, 8, 18),
        ),
        '已过期',
      );
    });

    test('已取消/暂停中不受到期影响', () {
      final now = DateTime(2026, 8, 18);
      expect(
        SubscriptionStatusResolver.resolve(
          storedStatus: '已取消',
          expiryDate: DateTime(2026, 8, 1),
          now: now,
        ),
        '已取消',
      );
      expect(
        SubscriptionStatusResolver.resolve(
          storedStatus: '暂停中',
          expiryDate: DateTime(2026, 8, 1),
          now: now,
        ),
        '暂停中',
      );
    });

    test('无到期日保持生效中', () {
      expect(
        SubscriptionStatusResolver.resolve(
          storedStatus: '生效中',
          expiryDate: null,
          now: DateTime(2026, 8, 18),
        ),
        '生效中',
      );
    });
  });

  group('订阅管理页', () {
    setUp(SubscriptionStore.instance.clear);

    testWidgets('过期订阅展示为已过期，且汇总卡出现', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SubscriptionStore.instance.add(
        Subscription(
          id: 's1',
          name: 'iCloud+',
          platform: '苹果',
          type: '自动续费',
          amount: 6,
          currency: 'CNY',
          cycle: '包月',
          firstDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 8, 1),
          status: '生效中',
          createdAt: DateTime(2026, 8, 1),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SubscriptionPage())),
      );
      await tester.pump();

      expect(find.text('月均合计'), findsOneWidget);
      expect(find.text('生效中'), findsNWidgets(2)); // 汇总卡 + 筛选胶囊
      expect(find.text('已过期'), findsNWidgets(2)); // 卡片状态 + 筛选胶囊
      expect(find.text('iCloud+'), findsOneWidget);
      expect(find.text('共 1 个订阅'), findsOneWidget);
    });

    testWidgets('状态筛选：切到生效中后过期订阅被过滤', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SubscriptionStore.instance.add(
        Subscription(
          id: 's2',
          name: 'Netflix',
          platform: '苹果',
          type: '自动续费',
          amount: 68,
          currency: 'CNY',
          cycle: '包月',
          firstDate: DateTime(2026, 7, 1),
          expiryDate: DateTime(2026, 8, 1),
          status: '生效中',
          createdAt: DateTime(2026, 7, 1),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SubscriptionPage())),
      );
      await tester.pump();

      // 默认“全部”可见
      expect(find.text('Netflix'), findsOneWidget);

      await tester.tap(find.text('生效中').last);
      await tester.pump();
      expect(find.text('该状态下暂无订阅'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    });
  });
}
