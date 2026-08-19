// 端到端走查 · 第 1 部分：启动首页 → 添加资产 → 首页看板 → 资产详情全交互。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/subscription_store.dart';
import 'package:liaoran_app/state/wishlist_store.dart';

void main() {
  setUp(() {
    AssetStore.instance.clear();
    SubscriptionStore.instance.clear();
    WishlistStore.instance.clear();
    SettingsStore.instance.updateCurrency('CNY');
    SettingsStore.instance.updateDecimalPlaces(2);
    SettingsStore.instance.updateViewStyle('单列');
    SettingsStore.instance.disableLock();
  });

  testWidgets('第1步 启动：首页、总览卡、空状态与导航栏齐全', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();

    expect(find.text('了然'), findsOneWidget);
    expect(find.text('资产总览'), findsOneWidget);
    expect(find.text('还没有资产'), findsOneWidget);
    expect(find.text('添加资产'), findsOneWidget);
    for (var i = 0; i <= 4; i++) {
      expect(find.byKey(ValueKey('nav_$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('nav_add')), findsOneWidget);
  });

  testWidgets('第2步 首页空状态「添加资产」按钮跳转添加页', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();

    await tester.tap(find.text('添加资产'));
    await tester.pumpAndSettle();

    expect(find.text('资产名称'), findsOneWidget);
    expect(find.text('购买价格'), findsOneWidget);
  });

  testWidgets('第3步 添加页三 Tab 切换正常', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    // 默认资产页
    expect(find.text('资产名称'), findsOneWidget);
    // 切到订阅
    await tester.tap(find.text('订阅'));
    await tester.pumpAndSettle();
    expect(find.text('APP / 服务名称'), findsOneWidget);
    // 切到心愿
    await tester.tap(find.text('心愿'));
    await tester.pumpAndSettle();
    expect(find.text('心愿名称'), findsOneWidget);
    // 切回资产
    await tester.tap(find.text('资产'));
    await tester.pumpAndSettle();
    expect(find.text('资产名称'), findsOneWidget);
  });

  testWidgets('第4步 资产页「更换图标」可打开面板并选择', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('⇋更换图标'));
    await tester.pumpAndSettle();
    expect(find.text('选择图标'), findsOneWidget);

    await tester.tap(find.text('账单'));
    await tester.pumpAndSettle();
    expect(find.text('选择图标'), findsNothing);
  });

  testWidgets('第5步 Care 开关展开到期时间字段', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    expect(find.text('Care到期时间'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('care_switch')));
    await tester.pumpAndSettle();
    expect(find.text('Care到期时间'), findsOneWidget);
  });

  testWidgets('第6步 资产分类下拉可选择', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('数码设备').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('家电').last);
    await tester.pumpAndSettle();
    // 下拉已切换（下拉菜单关闭）
    expect(find.text('家电'), findsOneWidget);
  });

  testWidgets('第7步 资产空表单提交给出校验提示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(find.text('请输入资产名称'), findsOneWidget);
  });

  testWidgets('第8步 填写资产并保存，返回首页显示看板与列表', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'iPhone 15 Pro');
    await tester.enterText(find.byType(TextField).at(1), '8799');
    await tester.tap(find.text('2026年8月17日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(AssetStore.instance.items, hasLength(1));
    expect(find.text('已添加资产「iPhone 15 Pro」'), findsOneWidget);
    await tester.pumpAndSettle();

    // 已返回首页：总览与列表出现
    expect(find.text('服役中 1'), findsOneWidget);
    expect(find.text('iPhone 15 Pro'), findsOneWidget);
  });

  testWidgets('第9步 首页筛选胶囊过滤资产', (WidgetTester tester) async {
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
        createdAt: DateTime(2026, 8, 18),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();

    expect(find.text('MacBook'), findsOneWidget);
    await tester.tap(find.text('已卖出'));
    await tester.pump();
    expect(find.text('该状态下暂无资产'), findsOneWidget);
    expect(find.text('MacBook'), findsNothing);
    await tester.tap(find.text('全部'));
    await tester.pump();
    expect(find.text('MacBook'), findsOneWidget);
  });

  testWidgets('第10步 资产详情：设置目标日均成本后显示回本进度', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(
      Asset(
        id: 'a2',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 8, 18),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.text('MacBook'));
    await tester.pumpAndSettle();

    expect(find.text('买入价'), findsOneWidget);
    expect(find.text('使用天数'), findsOneWidget);
    expect(find.text('日均成本'), findsWidgets);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '8.8');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('¥8.80/天'), findsOneWidget);
    expect(find.textContaining('距回本还需'), findsOneWidget);
  });

  testWidgets('第11步 资产详情：标记已退役并选择日期', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(
      Asset(
        id: 'a3',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 8, 18),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.text('MacBook'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('已退役').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(AssetStore.instance.items.first.status, AssetLifecycleStatus.retired);
    expect(find.text('数码设备 · 已退役'), findsOneWidget);
  });

  testWidgets('第12步 资产详情：记录卖出并显示盈亏', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(
      Asset(
        id: 'a4',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 8, 18),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.text('MacBook'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录卖出'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '4000');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(AssetStore.instance.items.first.status, AssetLifecycleStatus.sold);
    expect(AssetStore.instance.items.first.saleRecords, hasLength(1));
    expect(find.text('卖出盈亏'), findsOneWidget);
    expect(find.text('保值率'), findsOneWidget);
  });

  testWidgets('第13步 资产详情：删除资产（确认后生效）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AssetStore.instance.add(
      Asset(
        id: 'a5',
        name: 'MacBook',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 12000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 8, 18),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.text('MacBook'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();

    expect(AssetStore.instance.isEmpty, isTrue);
  });
}
