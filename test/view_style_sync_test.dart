// 功能视图样式（双列/单列）统一控制订阅管理页。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/config/app_version.dart';
import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/pages/subscription_page.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/services/update_notice.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/subscription_store.dart';

void main() {
  testWidgets('切换视图样式同步控制订阅页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': true,
      'lock_enabled': false,
      'last_seen_update_version': kAppVersion,
    });
    await LockGate.load();
    await UpdateNotice.load();
    await SettingsStore.instance.load();

    SubscriptionStore.instance.add(
      Subscription(
        id: 's1',
        name: 'Netflix',
        platform: 'Netflix',
        type: '自动续费',
        amount: 45,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 12, 31),
        status: '生效中',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('nav_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Finder gridInSub() => find.descendant(
          of: find.byType(SubscriptionPage),
          matching: find.byType(Wrap),
        );

    expect(SettingsStore.instance.viewStyle, '双列');
    expect(gridInSub(), findsOneWidget, reason: '双列时订阅页显示宫格');

    SettingsStore.instance.updateViewStyle('单列');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(gridInSub(), findsNothing, reason: '单列时订阅页不显示宫格');
  });
}
