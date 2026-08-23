// 累计投入弹窗：备注输入框可以正常输入文字。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/pages/add_flow_page.dart';

void main() {
  testWidgets('累计投入弹窗备注可以输入文字', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddFlowPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('添加投入记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加投入记录'));
    await tester.pumpAndSettle();

    final remarkField = find.widgetWithText(TextField, '备注');
    expect(remarkField, findsOneWidget);

    await tester.enterText(remarkField, '换了屏幕');
    await tester.pump();
    expect(find.text('换了屏幕'), findsOneWidget);
  });
}
