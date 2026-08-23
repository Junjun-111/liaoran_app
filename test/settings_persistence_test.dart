// 设置持久化：分类 / 标签等修改写入本地，重启后 load 可恢复。
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/domain/dictionaries.dart';
import 'package:liaoran_app/state/settings_store.dart';

void main() {
  Future<void> flushAsync(WidgetTester tester) => tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

  testWidgets('设置修改会写入本地，重启后可恢复', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SettingsStore.instance;

    // 恢复到默认字典，保证用例独立
    for (final c in store.categories.toList()) {
      store.removeCategory(c);
    }
    for (final c in Dictionaries.assetCategories) {
      store.addCategory(c);
    }
    for (final t in store.tags.toList()) {
      store.removeTag(t);
    }
    for (final t in Dictionaries.defaultTags) {
      store.addTag(t);
    }

    store.updateCurrency('USD');
    store.addTag('自定义标签A');
    store.addCategory('自定义分类B');
    store.updateAutoBackupEnabled(true);
    store.updateLastAutoBackupAt(DateTime(2026, 8, 23, 9, 30));
    await flushAsync(tester);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('liaoran_settings_v1');
    expect(raw, isNotNull);
    final map = jsonDecode(raw!) as Map<String, dynamic>;
    expect(map['currency'], 'USD');
    expect((map['tags'] as List).contains('自定义标签A'), isTrue);
    expect((map['categories'] as List).contains('自定义分类B'), isTrue);
    expect(map['autoBackupEnabled'], isTrue);
    expect(map['lastAutoBackupAt'], isNotNull);
  });

  testWidgets('load 从本地恢复标签与分类字典', (tester) async {
    SharedPreferences.setMockInitialValues({
      'liaoran_settings_v1': jsonEncode({
        'currency': 'USD',
        'decimalPlaces': 2,
        'viewStyle': '双列',
        'nickname': '测试昵称',
        'avatarPath': null,
        'autoBackupEnabled': true,
        'lastAutoBackupAt': '2026-08-20T09:00:00.000',
        'categories': ['我的分类'],
        'tags': ['我的标签'],
      }),
    });

    final store = SettingsStore.instance;
    await store.load();

    expect(store.currency, 'USD');
    expect(store.tags, contains('我的标签'));
    expect(store.categories, contains('我的分类'));
    expect(store.autoBackupEnabled, isTrue);
    expect(store.lastAutoBackupAt, DateTime(2026, 8, 20, 9, 0));
  });
}
