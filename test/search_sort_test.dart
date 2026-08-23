// 首页：搜索过滤 + 排序面板。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/config/app_version.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/services/update_notice.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'first_run_done': true,
      'lock_enabled': false,
      'last_seen_update_version': kAppVersion,
    });
  });

  testWidgets('首页搜索过滤并打开排序面板', (tester) async {
    await LockGate.load();
    await UpdateNotice.load();
    await SettingsStore.instance.load();

    AssetStore.instance.add(
      Asset(
        id: 'a1',
        name: 'iPhone',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 5000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    AssetStore.instance.add(
      Asset(
        id: 'a2',
        name: '跑步机',
        category: '家电',
        currency: 'CNY',
        purchasePrice: 2000,
        purchaseDate: DateTime(2026, 2, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 2, 1),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 默认停在首页：先打开搜索框
    final searchIcon = find.byKey(const ValueKey('home_search_icon'));
    await tester.tap(searchIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final searchField = find.byType(TextField);
    await tester.enterText(searchField.first, 'iPhone');
    await tester.pump();
    // 搜索框里的文字 + 卡片名称各一处
    expect(find.text('iPhone'), findsNWidgets(2));
    expect(find.text('跑步机'), findsNothing);

    await tester.enterText(searchField.first, '');
    await tester.pump();
    expect(find.text('跑步机'), findsOneWidget);

    // 打开排序面板，默认「添加时间 + 正序」
    await tester.tap(find.byKey(const ValueKey('home_sort_icon')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('排序方式'), findsOneWidget);
    expect(find.text('购买时间'), findsOneWidget);
    expect(find.text('按日均成本'), findsOneWidget);
    expect(find.text('服役时长'), findsOneWidget);
    expect(find.text('物品价值'), findsOneWidget);
    expect(find.text('自定义'), findsNothing);
    expect(find.text('物品状态'), findsNothing);

    // 默认「正序」= 最新的排前面（当前倒序规则），点选即生效
    final iphonePos = tester.getTopLeft(find.text('iPhone'));
    final paobuPos = tester.getTopLeft(find.text('跑步机'));
    // 正序 = 最新（跑步机，2 月添加）在前
    expect(paobuPos.dx, lessThan(iphonePos.dx));

    // 面板还开着，直接点「倒序」= 旧的排前面（当前正序规则），列表立即变化
    await tester.tap(find.text('倒序'));
    await tester.pump();
    final iphonePos2 = tester.getTopLeft(find.text('iPhone'));
    final paobuPos2 = tester.getTopLeft(find.text('跑步机'));
    // 倒序 = 最旧（iPhone，1 月添加）在前
    expect(iphonePos2.dx, lessThan(paobuPos2.dx));

    // 面板仍在展示中
    expect(find.text('排序方式'), findsOneWidget);
  });
}
