// 心愿清单流程测试：表单校验、保存、列表展示与攒钱进度。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/pages/wishlist_page.dart';
import 'package:liaoran_app/state/wishlist_store.dart';

void main() {
  setUp(WishlistStore.instance.clear);

  testWidgets('心愿表单校验：空表单提交提示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 2)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(find.text('请输入心愿名称'), findsOneWidget);
  });

  testWidgets('填写并保存心愿', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1629);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_zhApp(const AddFlowPage(initialTab: 2)));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '新款 MacBook Pro');
    await tester.enterText(find.byType(TextField).at(1), '20000');

    await tester.tap(find.text(_todayText()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('已添加心愿「新款 MacBook Pro」'), findsOneWidget);
    expect(WishlistStore.instance.items, hasLength(1));
    expect(WishlistStore.instance.items.first.targetAmount, 20000);
  });

  testWidgets('心愿页展示列表与进度', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    WishlistStore.instance.add(
      WishlistItem(
        id: 'w1',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 2500,
        addDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ),
    );

    await tester.pumpWidget(
      _zhApp(const Scaffold(body: WishlistPage())),
    );
    await tester.pump();

    expect(find.text('共 1 个心愿'), findsOneWidget);
    expect(find.text('相机'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('清单空空'), findsNothing);
  });
}

Widget _zhApp(Widget home) => MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );

String _todayText() {
  final now = DateTime.now();
  return '${now.year}年${now.month}月${now.day}日';
}
