// 日均成本计算引擎单元测试：覆盖全部状态与边界情况。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/domain/calculators/cost_per_day_calculator.dart';
import 'package:liaoran_app/domain/dictionaries.dart';
import 'package:liaoran_app/domain/models/asset.dart';
import 'package:liaoran_app/domain/models/asset_lifecycle_status.dart';

void main() {
  // 固定“今天”= 2026-04-11，保证结果可复现
  final calculator = CostPerDayCalculator(
    referenceDate: DateTime(2026, 4, 11),
  );

  group('服役中', () {
    test('基础日均成本：1000 元用 100 天 = 10 元/天', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
      );
      expect(r.daysUsed, 100);
      expect(r.costPerDay, 10.0);
    });

    test('回本判定与进度、还需天数', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        targetCpd: 8,
      );
      expect(r.isPaidBack, isFalse);
      expect(r.paybackProgress, closeTo(0.8, 0.001));
      expect(r.daysToPayback, 25); // 目标 8 元/天需要 125 天，已用 100 天
    });

    test('已回本时进度封顶 100% 且无需再等', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        targetCpd: 20,
      );
      expect(r.isPaidBack, isTrue);
      expect(r.paybackProgress, 1.0);
      expect(r.daysToPayback, 0);
    });

    test('今日刚入手：天数为 0，日均成本为 null', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 4, 11),
        status: AssetLifecycleStatus.active,
        targetCpd: 8,
      );
      expect(r.daysUsed, 0);
      expect(r.costPerDay, isNull);
      expect(r.isPaidBack, isNull);
      expect(r.paybackProgress, isNull);
    });

    test('买入日在未来（非法）：不计算', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 5, 1),
        status: AssetLifecycleStatus.active,
      );
      expect(r.daysUsed, 0);
      expect(r.costPerDay, isNull);
    });
  });

  group('已退役', () {
    test('退役结算：1000 元用 60 天 = 16.67 元/天', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.retired,
        retiredDate: DateTime(2026, 3, 2),
      );
      expect(r.daysUsed, 60);
      expect(r.costPerDay, closeTo(16.67, 0.01));
    });

    test('未填退役日期：不计算', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.retired,
      );
      expect(r.costPerDay, isNull);
    });

    test('退役日早于买入日（非法）：不计算', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 3, 2),
        status: AssetLifecycleStatus.retired,
        retiredDate: DateTime(2026, 1, 1),
      );
      expect(r.daysUsed, 0);
      expect(r.costPerDay, isNull);
    });
  });

  group('已卖出', () {
    test('卖出盈亏：买入 1000 / 卖出 400 / 用 60 天 → 净成本 10 元/天', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.sold,
        salePrice: 400,
        saleDate: DateTime(2026, 3, 2),
      );
      expect(r.daysUsed, 60);
      expect(r.costPerDay, 10.0);
      expect(r.profitLoss, -600);
      expect(r.retentionRate, 0.4);
      expect(r.isProfit, isFalse);
    });

    test('卖出盈利：日均成本归 0，进度 100%，标记盈利', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.sold,
        salePrice: 1200,
        saleDate: DateTime(2026, 3, 2),
        targetCpd: 8,
      );
      expect(r.costPerDay, 0.0);
      expect(r.profitLoss, 200);
      expect(r.retentionRate, 1.2);
      expect(r.isProfit, isTrue);
      expect(r.isPaidBack, isTrue);
      expect(r.paybackProgress, 1.0);
      expect(r.daysToPayback, 0);
    });

    test('未填卖出价：只算持有成本，盈亏与保值率为 null', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.sold,
        saleDate: DateTime(2026, 3, 2),
      );
      expect(r.costPerDay, closeTo(16.67, 0.01));
      expect(r.profitLoss, isNull);
      expect(r.retentionRate, isNull);
      expect(r.isProfit, isFalse);
    });
  });

  group('输入校验与边界', () {
    test('买入价为 0：不计算', () {
      final r = calculator.calculate(
        purchasePrice: 0,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
      );
      expect(r.costPerDay, isNull);
      expect(r.isPaidBack, isNull);
    });

    test('目标日均成本非法（0 / 负数）：视为未设置', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1),
        status: AssetLifecycleStatus.active,
        targetCpd: 0,
      );
      expect(r.targetCpd, isNull);
      expect(r.isPaidBack, isNull);
      expect(r.paybackProgress, isNull);
    });

    test('日期按整天归一化，忽略时分秒', () {
      final r = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 1, 1, 23, 59),
        status: AssetLifecycleStatus.active,
      );
      expect(r.daysUsed, 100);

      final same = calculator.calculate(
        purchasePrice: 1000,
        purchaseDate: DateTime(2026, 4, 11, 0, 1),
        status: AssetLifecycleStatus.active,
      );
      expect(same.daysUsed, 0);
    });
  });

  group('状态枚举与字典一致性', () {
    test('枚举文案与领域字典完全一致', () {
      expect(AssetLifecycleStatus.labels, Dictionaries.assetStatuses);
    });

    test('中文文案反查枚举', () {
      expect(AssetLifecycleStatus.fromLabel('已卖出'), AssetLifecycleStatus.sold);
      expect(AssetLifecycleStatus.fromLabel('未知状态'), AssetLifecycleStatus.active);
    });
  });

  test('开启累计价值后日均成本按累计价值计算', () {
    final calc = CostPerDayCalculator(referenceDate: DateTime(2026, 4, 11));
    // 买入价 10000，使用 100 天
    final purchaseDate = DateTime(2026, 1, 1);

    // 关闭：按买入价 10000 / 100 天 = 100
    final off = calc.calculate(
      purchasePrice: 10000,
      purchaseDate: purchaseDate,
      status: AssetLifecycleStatus.active,
      baseAmount: 10000,
    );
    expect(off.costPerDay, 100);

    // 开启：累计价值 = 10000 + 2000 = 12000，/ 100 天 = 120
    final on = calc.calculate(
      purchasePrice: 10000,
      purchaseDate: purchaseDate,
      status: AssetLifecycleStatus.active,
      baseAmount: 12000,
    );
    expect(on.costPerDay, 120);
  });

  test('资产 costBasis 随开关切换', () {
    final asset = Asset(
      id: 'a1',
      name: 'MacBook',
      category: '数码设备',
      currency: 'CNY',
      purchasePrice: 10000,
      purchaseDate: DateTime(2026, 1, 1),
      status: AssetLifecycleStatus.active,
      createdAt: DateTime(2026, 1, 1),
      investments: [
        InvestmentRecord(
          amount: 1500,
          date: DateTime(2026, 2, 1),
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
      maintenanceRecords: [
        MaintenanceRecord(
          cost: 500,
          date: DateTime(2026, 3, 1),
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
    );
    expect(asset.costBasis, 10000);
    expect(asset.costBasisIncludesInvestment, isFalse);

    final enabled = asset.copyWith(costBasisIncludesInvestment: true);
    expect(enabled.costBasis, 12000);

    // 序列化往返保留开关
    final restored = Asset.fromJson(enabled.toJson());
    expect(restored.costBasisIncludesInvestment, isTrue);
    expect(restored.costBasis, 12000);
  });
}
