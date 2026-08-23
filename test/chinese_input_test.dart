// 中文输入回归：订阅表单服务名称可输入中文。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/pages/add_flow_page.dart';

void main() {
  testWidgets('订阅表单服务名称可输入中文', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddFlowPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('订阅'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField).first;
    await tester.enterText(field, '网易云音乐');
    await tester.pump();
    expect(find.text('网易云音乐'), findsOneWidget);
  });
}
