import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/config/app_version.dart';
import 'package:liaoran_app/services/lock_gate.dart';
import 'package:liaoran_app/services/update_notice.dart';

Future<void> testExecutable(
  FutureOr<void> Function() testMain,
) async {
  // 默认按「已完成首次引导、未开启指纹锁、已看过当前版本更新」初始化，
  // 避免已有用例被首次启动弹窗或更新提示页打断。
  SharedPreferences.setMockInitialValues({
    'first_run_done': true,
    'lock_enabled': false,
    'last_seen_update_version': kAppVersion,
  });
  await LockGate.load();
  await UpdateNotice.load();
  await testMain();
}
