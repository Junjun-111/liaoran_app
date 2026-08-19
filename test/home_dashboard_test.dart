// 首页看板测试：有资产后总览与列表展示、状态筛选。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/pages/home_page.dart';
import 'package:liaoran_app/state/asset_store.dart';

void main() {
  setUp(AssetStore.instance.clear);

  testWidgets('有资产后首页展示总览与列表', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(_TestAsset());

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    // 总览状态计数与金额
    expect(find.text('服役中 1'), findsOneWidget);
    expect(find.text('已退役 0'), findsOneWidget);
    expect(find.text('已卖出 0'), findsOneWidget);
    expect(find.text('¥12000.00'), findsNWidgets(2));
    // 资产卡片出现，空状态消失
    expect(find.text('MacBook'), findsOneWidget);
    expect(find.text('还没有资产'), findsNothing);
  });

  testWidgets('状态筛选：切到无资产的状态显示空提示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(_TestAsset());

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    await tester.tap(find.text('已卖出'));
    await tester.pump();

    expect(find.text('该状态下暂无资产'), findsOneWidget);
    expect(find.text('MacBook'), findsNothing);
  });
}

class _TestAsset extends Asset {
  _TestAsset()
      : super(
          id: 'home-test-asset',
          name: 'MacBook',
          category: '数码设备',
          currency: 'CNY',
          purchasePrice: 12000,
          purchaseDate: DateTime(2026, 1, 1),
          status: AssetLifecycleStatus.active,
          createdAt: DateTime(2026, 8, 18),
        );
}
