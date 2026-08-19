// 端到端走查 · 第 2 部分：订阅管理 → 心愿清单 → 我的资产 → 个人中心。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/models/subscription.dart';
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
    for (final c in SettingsStore.instance.categories.toList()) {
      SettingsStore.instance.removeCategory(c);
    }
    for (final c in ['数码设备', '家电', '交通工具', '家居', '服装', '其他']) {
      SettingsStore.instance.addCategory(c);
    }
  });

  testWidgets('第14步 订阅空状态按钮进入添加页', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('还没有订阅'), findsOneWidget);
    await tester.tap(find.text('添加第一笔订阅'));
    await tester.pumpAndSettle();
    expect(find.text('APP / 服务名称'), findsOneWidget);
  });

  testWidgets('第15步 订阅表单：换图标、填写并保存，列表出现汇总卡', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加第一笔订阅'));
    await tester.pumpAndSettle();

    // 更换图标
    await tester.tap(find.text('⇋更换图标'));
    await tester.pumpAndSettle();
    expect(find.text('选择图标'), findsOneWidget);
    await tester.tap(find.text('账单'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'iCloud+');
    await tester.enterText(find.byType(TextField).at(1), '6');
    await tester.tap(find.text('选择日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择到期日期').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(SubscriptionStore.instance.items, hasLength(1));
    expect(find.text('月均合计'), findsOneWidget);
    expect(find.text('iCloud+'), findsOneWidget);
  });

  testWidgets('第16步 订阅详情可编辑并保存更新', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SubscriptionStore.instance.add(
      Subscription(
        id: 's1',
        name: 'Netflix',
        platform: '苹果',
        type: '自动续费',
        amount: 68,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 7, 1),
        expiryDate: DateTime(2026, 12, 31),
        status: '生效中',
        createdAt: DateTime(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Netflix'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Netflix 高级版');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(SubscriptionStore.instance.items.first.name, 'Netflix 高级版');
  });

  testWidgets('第17步 订阅长按删除', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SubscriptionStore.instance.add(
      Subscription(
        id: 's2',
        name: 'iCloud+',
        platform: '苹果',
        type: '自动续费',
        amount: 6,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 7, 1),
        expiryDate: DateTime(2026, 12, 31),
        status: '生效中',
        createdAt: DateTime(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_1')));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('iCloud+'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.isEmpty, isTrue);
    expect(find.text('还没有订阅'), findsOneWidget);
  });

  testWidgets('第18步 心愿空状态按钮进入添加页并保存', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_2')));
    await tester.pumpAndSettle();

    expect(find.text('清单空空'), findsOneWidget);
    await tester.tap(find.text('添加第一个心愿'));
    await tester.pumpAndSettle();

    // 更换图标
    await tester.tap(find.text('⇋更换图标'));
    await tester.pumpAndSettle();
    expect(find.text('选择图标'), findsOneWidget);
    await tester.tap(find.text('喜欢'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '相机');
    await tester.enterText(find.byType(TextField).at(1), '10000');
    await tester.tap(find.text('2026年8月17日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(WishlistStore.instance.items, hasLength(1));
    expect(find.text('共 1 个心愿'), findsOneWidget);
    expect(find.text('相机'), findsOneWidget);
  });

  testWidgets('第19步 心愿详情：攒一笔、完成心愿', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    WishlistStore.instance.add(
      WishlistItem(
        id: 'w1',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 0,
        addDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相机'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('攒一笔'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(WishlistStore.instance.items.first.savedAmount, 500);

    await tester.tap(find.text('完成心愿'));
    await tester.pumpAndSettle();
    expect(WishlistStore.instance.items.first.completed, isTrue);
    expect(find.text('重新开启'), findsOneWidget);
  });

  testWidgets('第20步 我的资产页：列表、长按删除、空状态', (WidgetTester tester) async {
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
    await tester.tap(find.byKey(const ValueKey('nav_3')));
    await tester.pumpAndSettle();

    expect(find.text('共 1 件资产'), findsOneWidget);
    await tester.longPress(find.text('MacBook'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(AssetStore.instance.isEmpty, isTrue);
    expect(find.text('资产空空'), findsOneWidget);

    await tester.tap(find.text('添加资产'));
    await tester.pumpAndSettle();
    expect(find.text('资产名称'), findsOneWidget);
  });

  testWidgets('第21步 个人中心：货币单位切换', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();

    expect(find.text('了然用户'), findsOneWidget);
    await tester.tap(find.text('货币单位'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    expect(SettingsStore.instance.currency, 'USD');
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets('第22步 个人中心：小数点设置与视图样式', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('小数点设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0 位'));
    await tester.pumpAndSettle();
    expect(SettingsStore.instance.decimalPlaces, 0);

    await tester.tap(find.text('功能视图样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('双列'));
    await tester.pumpAndSettle();
    expect(SettingsStore.instance.viewStyle, '双列');
  });

  testWidgets('第23步 分类管理：新增与删除', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('分类管理'));
    await tester.pumpAndSettle();
    expect(find.text('新增分类'), findsOneWidget);

    // 新增
    await tester.tap(find.text('新增分类').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '摄影');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(SettingsStore.instance.categories, contains('摄影'));
    expect(find.text('摄影'), findsOneWidget);

    // 删除
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(SettingsStore.instance.categories, isNot(contains('摄影')));
  });

  testWidgets('第24步 备份面板可打开', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('坚果云同步'));
    await tester.pumpAndSettle();
    expect(find.text('配置'), findsOneWidget);
    expect(find.text('备份'), findsOneWidget);

    await tester.tap(find.text('备份'));
    await tester.pumpAndSettle();
    expect(find.text('立即备份'), findsOneWidget);
  });

  testWidgets('第25步 应用锁定：设置密码、错误提示、解锁', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('立即锁定'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(SettingsStore.instance.lockEnabled, isTrue);
    expect(find.text('已锁定'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0000');
    await tester.tap(find.text('解锁'));
    await tester.pump();
    expect(find.text('密码错误，请重试'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.tap(find.text('解锁'));
    await tester.pumpAndSettle();
    expect(find.text('已锁定'), findsNothing);
  });
}
