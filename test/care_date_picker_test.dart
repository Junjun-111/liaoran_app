// Care 到期时间必须使用 App 自绘日期选择器（非系统日历）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/pages/add_flow_page.dart';

void main() {
  testWidgets('Care 到期时间打开的是 App 自绘日期选择器', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddFlowPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('care_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('care_switch')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('选择到期日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择到期日期'));
    await tester.pumpAndSettle();

    // 自绘选择器有「选择日期」标题和自定义 取消/确定 按钮
    expect(find.text('选择日期'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });
}
