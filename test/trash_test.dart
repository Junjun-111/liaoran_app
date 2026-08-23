// 回收站：删除进回收站、30 天内可恢复、永久删除。
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/state/asset_store.dart';
import 'package:liaoran_app/state/trash_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TrashStore.instance.load();
    TrashStore.instance.clear();
    AssetStore.instance.clear();
  });

  Asset makeAsset(String id, String name) => Asset(
        id: id,
        name: name,
        category: '数码设备',
        currency: 'CNY',
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

  test('删除资产后进入回收站，可恢复', () async {
    final asset = makeAsset('a1', 'iPhone');
    AssetStore.instance.add(asset);
    expect(AssetStore.instance.items, hasLength(1));

    AssetStore.instance.moveToTrash(asset);
    expect(AssetStore.instance.items, isEmpty);
    expect(TrashStore.instance.count, 1);
    expect(TrashStore.instance.entries.first.asset.id, 'a1');

    final restored = TrashStore.instance.restore(TrashStore.instance.entries.first);
    expect(restored?.id, 'a1');
    expect(TrashStore.instance.isEmpty, isTrue);
  });

  test('永久删除后不可恢复', () async {
    final asset = makeAsset('a2', '跑步机');
    AssetStore.instance.add(asset);
    AssetStore.instance.moveToTrash(asset);

    TrashStore.instance.deleteForever(TrashStore.instance.entries.first);
    expect(TrashStore.instance.isEmpty, isTrue);
    expect(AssetStore.instance.items, isEmpty);
  });
}
