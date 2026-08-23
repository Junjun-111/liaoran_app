// 版本更新提示：仅在版本变化后的第一次打开时展示。
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/services/update_notice.dart';

void main() {
  test('UpdateNotice 仅在版本变化后首次显示', () async {
    SharedPreferences.setMockInitialValues({});
    await UpdateNotice.load();
    expect(UpdateNotice.shouldShow, isTrue, reason: '从旧版本升级（无记录）需要提示');

    SharedPreferences.setMockInitialValues({
      'last_seen_update_version': 'v2.2.2',
    });
    await UpdateNotice.load();
    expect(UpdateNotice.shouldShow, isTrue, reason: '版本变化后提示');

    await UpdateNotice.markSeen();
    expect(UpdateNotice.shouldShow, isFalse, reason: '看过后不再提示');
  });

  testWidgets('更新后首次打开显示更新内容，看完进入首页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': true,
      'lock_enabled': false,
      'last_seen_update_version': 'v2.2.2',
    });
    await LockGate.load();
    await UpdateNotice.load();

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('更新内容'), findsOneWidget);
    expect(find.text('知道了，开始使用'), findsOneWidget);

    await tester.tap(find.text('知道了，开始使用'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(UpdateNotice.shouldShow, isFalse);
    expect(find.text('更新内容'), findsNothing);
  });
}
