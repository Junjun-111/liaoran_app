// 首次启动引导 + 指纹锁 + 后台 30 分钟自动锁定。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/main.dart';
import 'package:liaoran_app/pages/lock_screen.dart';
import 'package:liaoran_app/pages/welcome_page.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/widgets/confetti_burst.dart';

void main() {
  testWidgets('首次启动：显示启用指纹保护弹窗', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': false,
      'lock_enabled': false,
    });
    await LockGate.load();

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('欢迎使用了然'), findsOneWidget);
    expect(find.text('启用指纹保护'), findsOneWidget);

    // 点击后进入系统认证；测试环境没有真实系统认证，
    // 弹窗保留且处于加载中或失败提示状态（不会直接放行）
    await tester.tap(find.text('启用指纹保护'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('欢迎使用了然'), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('设备不支持指纹/面容识别，无法启用').evaluate().isNotEmpty ||
          find.text('无法启动系统识别，请重试').evaluate().isNotEmpty,
      isTrue,
      reason: '点击启用指纹保护后应进入系统认证（加载中或失败提示）',
    );
  });

  testWidgets('首次启动弹窗无法通过系统返回键退出', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': false,
      'lock_enabled': false,
    });
    await LockGate.load();

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('欢迎使用了然'), findsOneWidget);

    // 模拟系统返回键：弹窗必须还在
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('欢迎使用了然'), findsOneWidget);
    expect(find.text('启用指纹保护'), findsOneWidget);
  });

  testWidgets('欢迎页：欢迎使用 + 立即进入，无副标题，带纸屑动画', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('欢迎使用'), findsOneWidget);
    expect(find.text('立即进入'), findsOneWidget);
    expect(find.text('您的资产已准备就绪'), findsNothing);
    expect(find.byType(ConfettiBurst), findsOneWidget);
  });

  testWidgets('已启用指纹锁：冷启动直接验证指纹，无欢迎页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': true,
      'lock_enabled': true,
    });
    await LockGate.load();

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('已锁定'), findsOneWidget);
    expect(find.text('欢迎使用'), findsNothing);
  });

  testWidgets('后台超过 30 分钟回到前台需要指纹验证', (tester) async {
    SharedPreferences.setMockInitialValues({
      'first_run_done': true,
      'lock_enabled': false,
    });
    await LockGate.load();

    await tester.pumpWidget(const LiaoranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('已锁定'), findsNothing);

    // 用户启用指纹锁
    SettingsStore.instance.enableLock('');

    // 退到后台，把后台时间改成 31 分钟前，再回到前台
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_background_at',
      DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch,
    );
    await LockGate.load();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('已锁定'), findsOneWidget);
    expect(find.text('欢迎使用'), findsNothing);
  });

  testWidgets('锁定页无法通过系统返回键退出', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LockScreen()),
                ),
                child: const Text('进入锁定'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('进入锁定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('已锁定'), findsOneWidget);

    // 模拟系统返回键：锁定页必须还在，不能退进应用
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('已锁定'), findsOneWidget);
    expect(find.text('进入锁定'), findsNothing);
  });

  test('LockGate 30 分钟判定', () async {
    SharedPreferences.setMockInitialValues({});
    await LockGate.load();
    expect(LockGate.backgroundedLong, isFalse);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_background_at',
      DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch,
    );
    await LockGate.load();
    expect(LockGate.backgroundedLong, isTrue);

    await prefs.setInt(
      'last_background_at',
      DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    );
    await LockGate.load();
    expect(LockGate.backgroundedLong, isFalse);
  });

  test('LockGate.lockNow 强制下次进入验证指纹', () async {
    SharedPreferences.setMockInitialValues({});
    await LockGate.load();
    expect(LockGate.backgroundedLong, isFalse);

    await LockGate.lockNow();
    expect(LockGate.backgroundedLong, isTrue);
  });
}
