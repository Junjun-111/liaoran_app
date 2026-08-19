// 订阅添加流程测试：表单渲染、校验、保存与列表展示。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/pages/subscription_page.dart';
import 'package:liaoran_app/state/subscription_store.dart';

void main() {
  setUp(SubscriptionStore.instance.clear);

  testWidgets('订阅表单渲染与校验', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 1)));
    await tester.pump();

    // 订阅页关键字段
    expect(find.text('APP / 服务名称'), findsOneWidget);
    expect(find.text('订阅平台'), findsOneWidget);
    expect(find.text('订阅类型'), findsOneWidget);
    expect(find.text('当前状态'), findsOneWidget);
    // 顶部绿色对勾提交按钮
    expect(find.byIcon(Icons.check), findsOneWidget);

    // 空表单提交（顶部绿色对勾）→ 校验失败
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(find.text('请输入 APP / 服务名称'), findsOneWidget);
  });

  testWidgets('填写并保存订阅', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 1)));
    await tester.pump();

    // 填写名称与金额
    await tester.enterText(find.byType(TextField).first, 'iCloud+');
    await tester.enterText(find.byType(TextField).at(1), '6.00');

    // 选择两个必填日期
    await tester.tap(find.text('选择日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('选择到期日期').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 提交并保存（顶部绿色对勾）
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('已添加订阅「iCloud+」'), findsOneWidget);
    expect(SubscriptionStore.instance.items, hasLength(1));
    expect(SubscriptionStore.instance.items.first.name, 'iCloud+');
    expect(SubscriptionStore.instance.items.first.amount, 6.0);
  });

  testWidgets('订阅管理页展示已保存的订阅', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SubscriptionStore.instance.add(_TestSubscription());

    await tester.pumpWidget(_zhApp(const Scaffold(body: SubscriptionPage())));
    await tester.pump();

    expect(find.text('共 1 个订阅'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('苹果 · 包月'), findsOneWidget);
  });
}

class _TestSubscription extends Subscription {
  _TestSubscription()
      : super(
          id: 'netflix-test',
          name: 'Netflix',
          platform: '苹果',
          type: '自动续费',
          amount: 68,
          currency: 'CNY',
          cycle: '包月',
          firstDate: DateTime(2026, 8, 1),
          expiryDate: DateTime(2026, 8, 31),
          status: '生效中',
          createdAt: DateTime(2026, 8, 17),
        );
}

Widget _zhApp(Widget home) => MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
