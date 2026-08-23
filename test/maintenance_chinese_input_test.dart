// 维修 / 保养弹窗：说明输入框可以正常输入中文。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/pages/my_assets_page.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.load();
    AssetStore.instance.clear();
  });

  testWidgets('维修保养弹窗说明可以输入中文', (tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(
      Asset(
        id: 'a1',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MyAssetsPage())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('MacBook'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('添加维修 / 保养记录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final descField = find.widgetWithText(TextField, '说明（如：换电池、常规保养）');
    expect(descField, findsOneWidget);

    await tester.enterText(descField, '换了电池');
    await tester.pump();
    expect(find.text('换了电池'), findsOneWidget);
  });
}
