// 心愿一键转资产：完成的心愿可转为资产并从心愿清单移除。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/pages/wishlist_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/wishlist_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.load();
    await WishlistStore.instance.load();
    AssetStore.instance.clear();
    WishlistStore.instance.clear();
  });

  testWidgets('已完成心愿可一键转为资产', (tester) async {
    WishlistStore.instance.add(
      WishlistItem(
        id: 'w1',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 10000,
        completed: true,
        addDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: WishlistPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('相机'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('转为资产'), findsWidgets);
    await tester.tap(find.text('转为资产').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 确认弹窗
    expect(find.textContaining('转为资产？'), findsOneWidget);
    await tester.tap(find.text('转为资产').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(AssetStore.instance.items, hasLength(1));
    expect(AssetStore.instance.items.first.name, '相机');
    expect(AssetStore.instance.items.first.purchasePrice, 10000);
    expect(WishlistStore.instance.items, isEmpty);
  });

  testWidgets('进度未满 100% 不显示转为资产按钮', (tester) async {
    WishlistStore.instance.add(
      WishlistItem(
        id: 'w2',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 6000,
        addDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: WishlistPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('相机'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 进度 60%：只有完成心愿按钮，没有转为资产
    expect(find.text('完成心愿'), findsOneWidget);
    expect(find.text('转为资产'), findsNothing);
  });
}
