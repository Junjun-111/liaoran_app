// 了然 App 首页冒烟测试：验证页面关键元素可渲染。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/state/asset_store.dart';

void main() {
  setUp(AssetStore.instance.clear);

  testWidgets('Home page renders smoke test', (WidgetTester tester) async {
    // 模拟手机尺寸画布（440×956 设计基准 1x）
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();

    // 品牌标题与副标语
    expect(find.text('了然'), findsOneWidget);
    expect(find.text('理清资产订阅 全局一目了然'), findsOneWidget);

    // 资产总览卡片
    expect(find.text('资产总览'), findsOneWidget);
    expect(find.text('总资产'), findsOneWidget);
    expect(find.text('日均成本'), findsOneWidget);
    expect(find.text('服役中 0'), findsOneWidget);
    expect(find.text('已退役 0'), findsOneWidget);
    expect(find.text('已卖出 0'), findsOneWidget);

    // 空状态
    expect(find.text('还没有资产'), findsOneWidget);
    expect(find.text('添加资产'), findsOneWidget);
  });
}
