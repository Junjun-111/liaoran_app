// emoji 图标：存储、识别与渲染。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/pages/add_flow_page.dart';
import 'package:liaoran_app/widgets/item_icon.dart';

void main() {
  test('emoji 图标值编码与识别', () {
    expect(emojiIcon('😀'), 'emoji:😀');
    expect(isEmojiIconPath('emoji:😀'), isTrue);
    expect(isEmojiIconPath('assets/icon.svg'), isFalse);
    expect(isEmojiIconPath(null), isFalse);
    expect(emojiFromIconPath('emoji:🐱'), '🐱');
    expect(emojiFromIconPath('assets/icon.svg'), isNull);
  });

  testWidgets('ItemIconBadge 把 emoji 渲染为文字而非图片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ItemIconBadge(iconPath: 'emoji:😀'),
        ),
      ),
    );
    expect(find.text('😀'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('ItemIcon 直接渲染 emoji', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ItemIcon(iconPath: 'emoji:🐱', size: 32),
        ),
      ),
    );
    expect(find.text('🐱'), findsOneWidget);
  });

  testWidgets('添加页：输入 emoji 后设为图标', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddFlowPage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('⇋更换图标'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('输入 emoji'));
    await tester.pumpAndSettle();

    // 混入文字和数字，只应保留 emoji
    await tester.enterText(find.byType(TextField).last, 'abc123😀xyz456');
    await tester.pumpAndSettle();
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('abc123😀xyz456'), findsNothing);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 弹窗关闭后，图标预览区以无背景方块显示该 emoji
    expect(find.text('😀'), findsOneWidget);
    expect(find.byType(EmojiIconSquare), findsOneWidget);
  });
}
