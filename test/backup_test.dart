// 备份序列化测试：模型往返一致 + 备份内容完整性。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/domain/models/wishlist_item.dart';
import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/services/backup_service.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/settings_store.dart';
import 'package:liaoran_app/state/subscription_store.dart';
import 'package:liaoran_app/state/wishlist_store.dart';

void main() {
  setUp(() {
    AssetStore.instance.clear();
    SubscriptionStore.instance.clear();
    WishlistStore.instance.clear();
    SettingsStore.instance.disableLock();
    SettingsStore.instance.updateCurrency('CNY');
    SettingsStore.instance.updateDecimalPlaces(2);
    SettingsStore.instance.updateViewStyle('双列');
  });

  test('Asset 序列化往返一致（含卖出记录）', () {
    final asset = Asset(
      id: 'a1',
      name: 'iPhone',
      category: '数码设备',
      currency: 'CNY',
      purchasePrice: 8799,
      purchaseDate: DateTime(2026, 1, 1),
      status: AssetLifecycleStatus.active,
      targetCpd: 8.8,
      createdAt: DateTime(2026, 1, 1),
      saleRecords: [
        SaleRecord(
          salePrice: 3000,
          saleDate: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 6, 1),
        ),
      ],
    );

    final restored = Asset.fromJson(asset.toJson());
    expect(restored.id, 'a1');
    expect(restored.purchasePrice, 8799);
    expect(restored.targetCpd, 8.8);
    expect(restored.latestSale!.salePrice, 3000);
    expect(restored.status, AssetLifecycleStatus.active);
  });

  test('Subscription 序列化往返一致', () {
    final sub = Subscription(
      id: 's1',
      name: 'iCloud+',
      platform: '苹果',
      type: '自动续费',
      amount: 6,
      currency: 'CNY',
      cycle: '包月',
      firstDate: DateTime(2026, 1, 1),
      expiryDate: DateTime(2026, 8, 1),
      status: '生效中',
      createdAt: DateTime(2026, 1, 1),
    );
    final restored = Subscription.fromJson(sub.toJson());
    expect(restored.id, 's1');
    expect(restored.amount, 6);
    expect(restored.cycle, '包月');
  });

  test('WishlistItem 序列化往返一致', () {
    final wish = WishlistItem(
      id: 'w1',
      name: '相机',
      category: '数码设备',
      targetAmount: 10000,
      savedAmount: 2500,
      addDate: DateTime(2026, 8, 1),
      createdAt: DateTime(2026, 8, 1),
    );
    final restored = WishlistItem.fromJson(wish.toJson());
    expect(restored.name, '相机');
    expect(restored.savedAmount, 2500);
    expect(restored.progress, 0.25);
  });

  test('备份内容包含资产/订阅/心愿/设置', () {
    AssetStore.instance.add(
      Asset(
        id: 'a2',
        name: 'iPhone',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 8799,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    SubscriptionStore.instance.add(
      Subscription(
        id: 's2',
        name: 'iCloud+',
        platform: '苹果',
        type: '自动续费',
        amount: 6,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 8, 1),
        status: '生效中',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    WishlistStore.instance.add(
      WishlistItem(
        id: 'w2',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        addDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ),
    );
    SettingsStore.instance.updateCurrency('USD');

    final payload = BackupManager.buildPayload();
    expect(payload, contains('iPhone'));
    expect(payload, contains('iCloud+'));
    expect(payload, contains('相机'));
    expect(payload, contains('USD'));
  });

  test('恢复后保持原有顺序，不反转', () async {
    // 依次添加三个资产：新添加的排在前面
    for (final name in ['第一个', '第二个', '第三个']) {
      AssetStore.instance.add(
        Asset(
          id: 'id-$name',
          name: name,
          category: '数码设备',
          currency: 'CNY',
          purchasePrice: 100,
          purchaseDate: DateTime(2026, 1, 1),
          status: AssetLifecycleStatus.active,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
    }
    expect(
      AssetStore.instance.items.map((a) => a.name).toList(),
      ['第三个', '第二个', '第一个'],
    );

    final payload = BackupManager.buildPayload();
    AssetStore.instance.clear();

    final result = await BackupManager.restoreFromContent(payload);
    expect(result, contains('恢复成功'));
    expect(
      AssetStore.instance.items.map((a) => a.name).toList(),
      ['第三个', '第二个', '第一个'],
    );
  });

  testWidgets('恢复：从备份还原资产/订阅/心愿/设置', (WidgetTester tester) async {
    // 造一份包含各类数据的备份
    AssetStore.instance.add(
      Asset(
        id: 'a9',
        name: 'iPhone',
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 8799,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    SubscriptionStore.instance.add(
      Subscription(
        id: 's9',
        name: 'iCloud+',
        platform: '苹果',
        type: '自动续费',
        amount: 6,
        currency: 'CNY',
        cycle: '包月',
        firstDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 8, 1),
        status: '生效中',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    WishlistStore.instance.add(
      WishlistItem(
        id: 'w9',
        name: '相机',
        category: '数码设备',
        targetAmount: 10000,
        savedAmount: 2500,
        addDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ),
    );
    SettingsStore.instance.updateCurrency('USD');
    final payload = BackupManager.buildPayload();

    // 清空当前数据，模拟“换了一台设备/数据丢失”
    AssetStore.instance.clear();
    SubscriptionStore.instance.clear();
    WishlistStore.instance.clear();
    SettingsStore.instance.updateCurrency('CNY');

    final result = await BackupManager.restoreFromContent(payload);

    expect(result, contains('恢复成功'));
    expect(AssetStore.instance.items, hasLength(1));
    expect(AssetStore.instance.items.first.name, 'iPhone');
    expect(SubscriptionStore.instance.items, hasLength(1));
    expect(SubscriptionStore.instance.items.first.name, 'iCloud+');
    expect(WishlistStore.instance.items, hasLength(1));
    expect(WishlistStore.instance.items.first.savedAmount, 2500);
    expect(SettingsStore.instance.currency, 'USD');
  });
}
