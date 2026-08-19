// 资产仓储与 Store 单元测试：增删改、统计、卖出记录、copyWith。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/data/in_memory/in_memory_asset_repository.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';
import 'package:liaoran_app/state/asset_store.dart';

void main() {
  group('InMemoryAssetRepository', () {
    final repo = InMemoryAssetRepository.instance;

    setUp(repo.clear);

    test('新增置顶、更新、删除与清空', () {
      final a = _asset('A', 100, AssetLifecycleStatus.active);
      final b = _asset('B', 200, AssetLifecycleStatus.active);

      repo.add(a);
      repo.add(b);
      expect(repo.items, hasLength(2));
      expect(repo.items.first.id, 'id-B');

      repo.update(a.copyWith(status: AssetLifecycleStatus.retired));
      expect(
        repo.items.firstWhere((x) => x.id == 'id-A').status,
        AssetLifecycleStatus.retired,
      );

      repo.remove(b);
      expect(repo.items, hasLength(1));
      repo.clear();
      expect(repo.isEmpty, isTrue);
    });

    test('只读视图不可修改', () {
      repo.add(_asset('A', 100, AssetLifecycleStatus.active));
      expect(() => repo.items.add(_asset('B', 1, AssetLifecycleStatus.active)),
          throwsUnsupportedError);
    });
  });

  group('AssetStore 统计', () {
    setUp(AssetStore.instance.clear);

    test('总资产净值与状态计数', () {
      AssetStore.instance.add(
        _asset('手机', 1000, AssetLifecycleStatus.active),
      );
      AssetStore.instance.add(
        _asset('跑步机', 500, AssetLifecycleStatus.retired),
      );
      AssetStore.instance.add(
        _asset('相机', 300, AssetLifecycleStatus.sold),
      );

      expect(AssetStore.instance.totalValue, 1500);
      expect(AssetStore.instance.activeCount, 1);
      expect(AssetStore.instance.retiredCount, 1);
      expect(AssetStore.instance.soldCount, 1);
    });
  });

  group('Asset 模型', () {
    test('latestSale 取卖出日期最新的一条', () {
      final asset = _asset('相机', 1000, AssetLifecycleStatus.sold).copyWith(
        saleRecords: [
          SaleRecord(
            salePrice: 400,
            saleDate: DateTime(2026, 5, 1),
            createdAt: DateTime(2026, 5, 1),
          ),
          SaleRecord(
            salePrice: 500,
            saleDate: DateTime(2026, 6, 1),
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(asset.latestSale!.salePrice, 500);
    });

    test('copyWith 可显式清空目标日均成本', () {
      final asset = _asset('手机', 1000, AssetLifecycleStatus.active)
          .copyWith(targetCpd: 8.8);
      expect(asset.targetCpd, 8.8);

      final cleared = asset.copyWith(targetCpd: null);
      expect(cleared.targetCpd, isNull);
      // 不传 targetCpd 时保持原值
      expect(asset.copyWith(name: '改名').targetCpd, 8.8);
    });
  });
}

Asset _asset(String name, double price, AssetLifecycleStatus status) {
  return Asset(
    id: 'id-$name',
    name: name,
    category: '数码设备',
    currency: 'CNY',
    purchasePrice: price,
    purchaseDate: DateTime(2026, 1, 1),
    status: status,
    createdAt: DateTime(2026, 8, 18),
  );
}
