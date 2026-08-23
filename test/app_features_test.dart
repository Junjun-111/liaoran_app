// 全功能走查测试：编辑订阅、锁定解锁、双列视图、边角容错。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/dictionaries.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/pages/lock_screen.dart';
import 'package:liaoran_app/pages/my_assets_page.dart';
import 'package:liaoran_app/pages/subscription_page.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/subscription_store.dart';

void main() {
  setUp(_resetAll);

  group('编辑订阅', () {
    testWidgets('表单回填并保存更新', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1629);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final sub = _sub('Netflix', expiry: DateTime(2026, 12, 31));
      SubscriptionStore.instance.add(sub);

      await tester.pumpWidget(
        MaterialApp(home: AddFlowPage(editingSubscription: sub)),
      );
      await tester.pump();

      // 表单已回填
      expect(find.widgetWithText(TextField, 'Netflix'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Netflix 高级版');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('已更新订阅「Netflix 高级版」'), findsOneWidget);
      expect(SubscriptionStore.instance.items, hasLength(1));
      expect(SubscriptionStore.instance.items.first.name, 'Netflix 高级版');
    });
  });

  group('应用锁定', () {
    testWidgets('锁定页使用系统指纹验证', (WidgetTester tester) async {
      SettingsStore.instance.enableLock('1234');

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('base'))),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('已锁定'), findsOneWidget);
      expect(find.text('使用手机系统指纹/面容解锁应用'), findsOneWidget);
      LockGate.lockScreenShowing = false;
      navigator.pop();
      await tester.pump();
      expect(find.text('base'), findsOneWidget);
    });
  });

  group('显示视图', () {
    testWidgets('双列视图渲染宫格卡片', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SettingsStore.instance.updateViewStyle('双列');
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

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MyAssetsPage())),
      );
      await tester.pump();

      expect(find.text('MacBook'), findsOneWidget);
      expect(find.text('服役中'), findsOneWidget);
      expect(find.text('¥12000.00'), findsOneWidget);
    });
  });

  group('边角容错', () {
    testWidgets('订阅无到期日不崩溃并显示占位', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SubscriptionStore.instance.add(
        Subscription(
          id: 's-null',
          name: '免费服务',
          platform: '其他',
          type: '一次性',
          amount: 0,
          currency: 'CNY',
          cycle: '无',
          firstDate: DateTime(2026, 8, 1),
          expiryDate: null,
          nextChargeDate: null,
          status: '生效中',
          createdAt: DateTime(2026, 8, 1),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SubscriptionPage())),
      );
      await tester.pump();

      expect(find.text('免费服务'), findsOneWidget);
      expect(find.text('未设置到期'), findsOneWidget);
    });

    testWidgets('分类删光后添加资产页仍正常', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440, 1629);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final settings = SettingsStore.instance;
      for (final c in settings.categories.toList()) {
        settings.removeCategory(c);
      }

      await tester.pumpWidget(
        const MaterialApp(home: AddFlowPage(initialTab: 0)),
      );
      await tester.pump();

      expect(find.text('自定义'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _resetAll() {
  AssetStore.instance.clear();
  SubscriptionStore.instance.clear();
  final settings = SettingsStore.instance;
  settings.updateCurrency('CNY');
  settings.updateDecimalPlaces(2);
  settings.updateViewStyle('单列');
  settings.disableLock();
  for (final c in settings.categories.toList()) {
    settings.removeCategory(c);
  }
  for (final c in Dictionaries.assetCategories) {
    settings.addCategory(c);
  }
  for (final t in settings.tags.toList()) {
    settings.removeTag(t);
  }
  for (final t in Dictionaries.defaultTags) {
    settings.addTag(t);
  }
}

Subscription _sub(String name, {DateTime? expiry}) => Subscription(
      id: 's-$name',
      name: name,
      platform: '苹果',
      type: '自动续费',
      amount: 68,
      currency: 'CNY',
      cycle: '包月',
      firstDate: DateTime(2026, 7, 1),
      expiryDate: expiry,
      status: '生效中',
      createdAt: DateTime(2026, 7, 1),
    );
