// 编辑资产表单：日均成本按累计价值计算的开关。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.load();
    AssetStore.instance.clear();
  });

  testWidgets('编辑页展示日均成本开关并可切换', (tester) async {
    tester.view.physicalSize = const Size(440, 1800);
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
      createdAt: DateTime(2026, 1, 1),
    );
    AssetStore.instance.add(asset);

    await tester.pumpWidget(
      MaterialApp(home: AddFlowPage(editingAsset: asset)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 开关在「上传图片」与「累计投入」之间
    await tester.ensureVisible(find.text('累值计价'));
    await tester.pumpAndSettle();
    expect(find.text('累值计价'), findsOneWidget);
    expect(find.text('日均成本按累计价值计算'), findsOneWidget);

    // 打开开关
    await tester.tap(find.byKey(const ValueKey('cost_basis_switch')));
    await tester.pumpAndSettle();

    // 保存后开关状态写入资产
    final saveButton = find.byKey(const ValueKey('confirm_check_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(AssetStore.instance.items, hasLength(1));
    expect(
      AssetStore.instance.items.first.costBasisIncludesInvestment,
      isTrue,
    );
  });
}
