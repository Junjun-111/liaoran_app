// 仓储层单元测试：内存实现的增删改查与输入校验。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/data/in_memory/in_memory_settings_repository.dart';
import 'package:liaoran_app/data/in_memory/in_memory_subscription_repository.dart';
import 'package:liaoran_app/domain/dictionaries.dart';
import 'package:liaoran_app/models/subscription.dart';

void main() {
  group('InMemorySettingsRepository', () {
    final repo = InMemorySettingsRepository.instance;

    setUp(() {
      // 每次用例从默认状态开始
      repo.updateCurrency('CNY');
      repo.updateDecimalPlaces(2);
      repo.updateViewStyle(Dictionaries.viewStyles.first);
      for (final c in repo.categories.toList()) {
        repo.removeCategory(c);
      }
      for (final c in Dictionaries.assetCategories) {
        repo.addCategory(c);
      }
      for (final t in repo.tags.toList()) {
        repo.removeTag(t);
      }
      for (final t in Dictionaries.defaultTags) {
        repo.addTag(t);
      }
      repo.disableLock();
    });

    test('默认值与字典一致', () {
      expect(repo.currency, 'CNY');
      expect(repo.decimalPlaces, 2);
      expect(repo.categories, Dictionaries.assetCategories);
      expect(repo.tags, Dictionaries.defaultTags);
      expect(repo.lockEnabled, isFalse);
    });

    test('货币/小数位/视图样式更新与校验', () {
      repo.updateCurrency('USD');
      expect(repo.currency, 'USD');
      // 无效币种被忽略
      repo.updateCurrency('BTC');
      expect(repo.currency, 'USD');

      repo.updateDecimalPlaces(0);
      expect(repo.decimalPlaces, 0);
      // 越界值被忽略
      repo.updateDecimalPlaces(9);
      expect(repo.decimalPlaces, 0);

      repo.updateViewStyle('单列');
      expect(repo.viewStyle, '单列');
      repo.updateViewStyle('三列');
      expect(repo.viewStyle, '单列');
    });

    test('分类增删改与去重', () {
      repo.addCategory(' 摄影器材 ');
      expect(repo.categories, contains('摄影器材'));
      // 重复/空白被忽略
      repo.addCategory('摄影器材');
      repo.addCategory('   ');
      expect(repo.categories.where((c) => c == '摄影器材'), hasLength(1));

      repo.renameCategory('摄影器材', '相机');
      expect(repo.categories, contains('相机'));
      expect(repo.categories, isNot(contains('摄影器材')));

      repo.removeCategory('相机');
      expect(repo.categories, isNot(contains('相机')));
    });

    test('标签增删改', () {
      repo.addTag('数码');
      expect(repo.tags, contains('数码'));
      repo.renameTag('数码', '电子产品');
      expect(repo.tags, contains('电子产品'));
      repo.removeTag('电子产品');
      expect(repo.tags, isNot(contains('电子产品')));
    });

    test('应用锁定开关', () {
      repo.enableLock('1234');
      expect(repo.lockEnabled, isTrue);
      expect(repo.passcode, '1234');
      // 锁定开关与密码独立：启用后即为开
      repo.disableLock();
      repo.enableLock('');
      expect(repo.lockEnabled, isTrue);
      repo.disableLock();
      expect(repo.lockEnabled, isFalse);
      expect(repo.passcode, isEmpty);
    });
  });

  group('InMemorySubscriptionRepository', () {
    final repo = InMemorySubscriptionRepository.instance;

    setUp(repo.clear);

    test('新增置顶、删除与清空', () {
      final a = _Sub(name: 'A');
      final b = _Sub(name: 'B');

      repo.add(a);
      repo.add(b);
      expect(repo.items, hasLength(2));
      expect(repo.items.first.name, 'B');
      expect(repo.isEmpty, isFalse);

      repo.remove(b);
      expect(repo.items, hasLength(1));
      expect(repo.items.first.name, 'A');

      repo.clear();
      expect(repo.isEmpty, isTrue);
    });

    test('只读视图不可修改', () {
      repo.add(_Sub(name: 'A'));
      expect(() => repo.items.add(_Sub(name: 'B')), throwsUnsupportedError);
    });
  });
}

class _Sub extends Subscription {
  _Sub({required super.name})
      : super(
          id: 'sub-${name.hashCode}',
          platform: '苹果',
          type: '自动续费',
          amount: 10,
          currency: 'CNY',
          cycle: '包月',
          firstDate: DateTime(2026, 8, 1),
          expiryDate: DateTime(2026, 8, 31),
          status: '生效中',
          createdAt: DateTime(2026, 8, 18),
        );
}
