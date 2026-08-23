// 年度/月度报告：汇总资产、订阅、心愿数据，支持月/年切换。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/pages/report_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/subscription_store.dart';
import 'package:liaoran_app/state/wishlist_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('报告页展示资产/订阅/心愿汇总并可切换月年', (tester) async {
    await SettingsStore.instance.load();
    await SubscriptionStore.instance.load();
    await WishlistStore.instance.load();

    final now = DateTime.now();
    AssetStore.instance.add(
      Asset(
        id: 'a1',
        name: 'iPhone',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 5000,
        purchaseDate: DateTime(now.year, now.month, 5),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(now.year, now.month, 5),
      ),
    );
    AssetStore.instance.add(
      Asset(
        id: 'a2',
        name: '旧手机',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 3000,
        purchaseDate: DateTime(now.year - 1, 1, 1),
        status: AssetLifecycleStatus.sold,
        createdAt: DateTime(now.year - 1, 1, 1),
        saleRecords: [
          SaleRecord(
            salePrice: 1500,
            saleDate: DateTime(now.year, now.month, 3),
            createdAt: DateTime(now.year, now.month, 3),
          ),
        ],
      ),
    );

    SubscriptionStore.instance.add(
      Subscription(
        id: 's1',
        name: 'Netflix',
        platform: 'Netflix',
        type: '自动续费',
        amount: 45,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(now.year, now.month, 1),
        expiryDate: DateTime(now.year, now.month, 28),
        status: '生效中',
        createdAt: DateTime(now.year, now.month, 1),
      ),
    );

    WishlistStore.instance.add(
      WishlistItem(
        id: 'w1',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 4000,
        addDate: DateTime(now.year, now.month, 1),
        createdAt: DateTime(now.year, now.month, 1),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ReportPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 三张汇总卡都在
    expect(find.text('资产变化'), findsOneWidget);
    expect(find.text('订阅支出'), findsOneWidget);
    expect(find.text('心愿进度'), findsOneWidget);

    // 本月新增 1 件，卖出 1 件
    expect(find.text('本月新增'), findsOneWidget);
    expect(find.text('1 件'), findsWidgets);
    expect(find.text('本月卖出'), findsOneWidget);

    // 切到年度
    await tester.tap(find.text('年度'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('本年新增'), findsOneWidget);
    expect(find.text('本年卖出'), findsOneWidget);
  });
}
