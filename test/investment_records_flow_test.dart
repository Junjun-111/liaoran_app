// 累计投入折叠卡片 + 记录页：明细不展开、点击可编辑、金额回填。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/widgets/asset_detail_sheet.dart';

void main() {
  setUp(AssetStore.instance.clear);

  testWidgets('累计投入折叠卡片不展示明细，记录页可点击重新编辑', (tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final asset = Asset(
      id: 'a1',
      name: 'MacBook',
      category: '数码设备',
      currency: 'CNY',
      purchasePrice: 12000,
      purchaseDate: DateTime(2026, 1, 1),
      status: AssetLifecycleStatus.active,
      createdAt: DateTime(2026, 8, 18),
      investments: [
        InvestmentRecord(
          amount: 500,
          date: DateTime(2026, 3, 1),
          remark: '换电池',
          createdAt: DateTime(2026, 3, 1),
        ),
        InvestmentRecord(
          amount: 300,
          date: DateTime(2026, 5, 2),
          remark: '换屏幕',
          createdAt: DateTime(2026, 5, 2),
        ),
      ],
    );

    await tester.pumpWidget(_zhApp(AddFlowPage(editingAsset: asset)));
    await tester.pump();

    // 卡片折叠：明细不再逐条平铺
    expect(find.text('累计投入'), findsNWidgets(2)); // 字段标签 + 卡片标题
    expect(find.text('换电池'), findsNothing);
    expect(find.text('换屏幕'), findsNothing);
    expect(find.text('共 2 笔记录'), findsOneWidget);

    // 点击卡片进入记录页
    await tester.ensureVisible(find.text('共 2 笔记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共 2 笔记录'));
    await tester.pumpAndSettle();

    expect(find.text('投入记录'), findsOneWidget);
    expect(find.text('换电池'), findsOneWidget);
    expect(find.text('换屏幕'), findsOneWidget);
    // 序号
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // 整张卡片可点：点金额也能打开编辑弹窗
    await tester.tap(find.text('¥300.00'));
    await tester.pumpAndSettle();
    expect(find.text('编辑投入记录'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 单击记录 → 编辑弹窗，金额回填
    await tester.tap(find.text('换电池'));
    await tester.pumpAndSettle();
    expect(find.text('编辑投入记录'), findsOneWidget);
    final amountField = find.widgetWithText(TextField, '投入金额');
    expect(amountField, findsOneWidget);
    expect(
      tester.widget<TextField>(amountField).controller?.text,
      '500.00',
    );

    // 修改金额并保存，列表与累计总额同步
    await tester.enterText(amountField, '888');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('¥888.00'), findsOneWidget);

    // 返回表单：卡片总额已更新
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('¥1188.00'), findsOneWidget);
  });

  testWidgets('记录页底部可继续添加投入', (tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 0)));
    await tester.pump();

    // 卡片上直接添加一条
    await tester.ensureVisible(find.text('添加投入记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加投入记录'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '投入金额'),
      '199',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 进入记录页：能看到这条记录，也能在页内再添加
    await tester.ensureVisible(find.text('共 1 笔记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共 1 笔记录'));
    await tester.pumpAndSettle();
    expect(find.text('¥199.00'), findsOneWidget);
    expect(find.text('添加投入记录'), findsOneWidget);
  });

  testWidgets('资产详情页打开的投入记录可编辑并写回', (tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final asset = Asset(
      id: 'a2',
      name: 'MacBook',
      category: '数码设备',
      currency: 'CNY',
      purchasePrice: 12000,
      purchaseDate: DateTime(2026, 1, 1),
      status: AssetLifecycleStatus.active,
      createdAt: DateTime(2026, 8, 18),
      investments: [
        InvestmentRecord(
          amount: 500,
          date: DateTime(2026, 3, 1),
          remark: '换电池',
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
    );
    AssetStore.instance.add(asset);

    await tester.pumpWidget(
      _zhApp(Scaffold(body: AssetDetailSheet(asset: asset))),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('共 1 笔记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共 1 笔记录'));
    await tester.pumpAndSettle();

    expect(find.text('投入记录'), findsOneWidget);
    await tester.tap(find.text('换电池'));
    await tester.pumpAndSettle();
    expect(find.text('编辑投入记录'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '投入金额'), '999');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 修改已写回资产存储
    expect(AssetStore.instance.items.first.investments, hasLength(1));
    expect(AssetStore.instance.items.first.investments.first.amount, 999);
  });
}

Widget _zhApp(Widget home) => MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
