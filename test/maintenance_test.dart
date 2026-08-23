// 维修 / 保养记录：花费计入累计投入，支持增删改。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/pages/my_assets_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.load();
    AssetStore.instance.clear();
  });

  Asset makeAsset() => Asset(
        id: 'a1',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
        investments: [
          InvestmentRecord(
            amount: 500,
            date: DateTime(2026, 3, 1),
            createdAt: DateTime(2026, 3, 1),
          ),
        ],
      );

  test('维修保养花费计入累计投入', () {
    final asset = makeAsset().copyWith(
      maintenanceRecords: [
        MaintenanceRecord(
          cost: 300,
          date: DateTime(2026, 4, 1),
          description: '换电池',
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
    );
    // 累计投入 = 配件投入 500 + 维修保养 300
    expect(asset.cumulativeInvestment, 800);
    expect(asset.totalMaintenanceCost, 300);
  });

  test('维修保养记录可序列化往返', () {
    final asset = makeAsset().copyWith(
      maintenanceRecords: [
        MaintenanceRecord(
          cost: 120,
          date: DateTime(2026, 5, 1),
          description: '常规保养',
          createdAt: DateTime(2026, 5, 1),
        ),
      ],
    );
    final restored = Asset.fromJson(asset.toJson());
    expect(restored.maintenanceRecords, hasLength(1));
    expect(restored.maintenanceRecords.first.cost, 120);
    expect(restored.maintenanceRecords.first.description, '常规保养');
    expect(restored.cumulativeInvestment, 620);
  });

  testWidgets('详情页可打开维修保养记录页并添加记录', (tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(makeAsset());

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MyAssetsPage())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('MacBook'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('维修 / 保养'), findsWidgets);
    // 点添加入口打开编辑表单页
    await tester.tap(find.text('添加维修 / 保养记录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('添加维修 / 保养'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '300');
    await tester.enterText(find.byType(TextField).at(1), '换电池');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(AssetStore.instance.items.first.maintenanceRecords, hasLength(1));
    expect(AssetStore.instance.items.first.cumulativeInvestment, 800);
  });

  testWidgets('编辑资产表单含维修保养入口', (tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AddFlowPage(editingAsset: makeAsset())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('维修 / 保养').first);
    await tester.pumpAndSettle();
    expect(find.text('添加维修 / 保养记录'), findsOneWidget);
  });
}
