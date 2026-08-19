import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(
  FutureOr<void> Function() testMain,
) async {
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
