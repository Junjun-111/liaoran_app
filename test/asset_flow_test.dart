// 资产添加流程测试：表单校验、保存与列表展示。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/pages/my_assets_page.dart';
import 'package:liaoran_app/state/asset_store.dart';

void main() {
  setUp(AssetStore.instance.clear);

  testWidgets('资产表单校验：空表单提交提示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 0)));
    await tester.pump();

    // 关键字段
    expect(find.text('资产名称'), findsOneWidget);
    expect(find.text('购买价格'), findsOneWidget);
    expect(find.text('购买日期'), findsOneWidget);

    // 空表单提交（顶部绿色对勾）→ 校验失败
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(find.text('请输入资产名称'), findsOneWidget);
  });

  testWidgets('填写并保存资产', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 0)));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'MacBook');
    await tester.enterText(find.byType(TextField).at(1), '12000');

    // 选择购买日期
    await tester.tap(find.text('2026年8月17日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 提交并保存（顶部绿色对勾）
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('已添加资产「MacBook」'), findsOneWidget);
    expect(AssetStore.instance.items, hasLength(1));
    expect(AssetStore.instance.items.first.name, 'MacBook');
    expect(AssetStore.instance.items.first.purchasePrice, 12000);
  });

  testWidgets('我的资产页空状态', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _zhApp(const Scaffold(body: MyAssetsPage())),
    );
    await tester.pump();

    expect(find.text('资产空空'), findsOneWidget);
    expect(find.text('添加资产'), findsOneWidget);
  });

  testWidgets('我的资产页展示已保存的资产', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(_TestAsset());

    await tester.pumpWidget(
      _zhApp(const Scaffold(body: MyAssetsPage())),
    );
    await tester.pump();

    expect(find.text('共 1 件资产'), findsOneWidget);
    expect(find.text('MacBook'), findsOneWidget);
    expect(find.text('数码设备 · 服役中'), findsOneWidget);
  });
}

class _TestAsset extends Asset {
  _TestAsset()
      : super(
          id: 'test-asset',
          name: 'MacBook',
          category: '数码设备',
          currency: 'CNY',
          purchasePrice: 12000,
          purchaseDate: DateTime(2026, 1, 1),
          status: AssetLifecycleStatus.active,
          createdAt: DateTime(2026, 8, 18),
        );
}

Widget _zhApp(Widget home) => MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
