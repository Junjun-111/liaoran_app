import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/services/lock_gate.dart';

Future<void> testExecutable(
  FutureOr<void> Function() testMain,
) async {
  // 默认按「已完成首次引导、未开启指纹锁」初始化，
  // 避免已有用例被首次启动弹窗打断。
  SharedPreferences.setMockInitialValues({
    'first_run_done': true,
    'lock_enabled': false,
  });
  await LockGate.load();
  await testMain();
}
