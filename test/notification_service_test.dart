// 本地提醒：到期前 7/3/1 天当天 9 点，忽略已过期。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/models/subscription.dart';
import 'package:liaoran_app/services/notification_service.dart';

void main() {
  test('到期前 7/3/1 天当天 9 点提醒', () {
    final target = DateTime(2026, 8, 31, 20, 0);
    final now = DateTime(2026, 8, 1);
    final dates = NotificationService.reminderDates(target, now: now);
    expect(dates, [
      DateTime(2026, 8, 24, 9, 0),
      DateTime(2026, 8, 28, 9, 0),
      DateTime(2026, 8, 30, 9, 0),
    ]);
  });

  test('距到期不足 7 天时只保留未来的提醒', () {
    final target = DateTime(2026, 8, 31, 20, 0);
    final now = DateTime(2026, 8, 29, 10, 0);
    final dates = NotificationService.reminderDates(target, now: now);
    expect(dates, [DateTime(2026, 8, 30, 9, 0)]);
  });

  test('已过期的目标不再排提醒', () {
    final target = DateTime(2026, 8, 1, 20, 0);
    final now = DateTime(2026, 8, 10);
    expect(NotificationService.reminderDates(target, now: now), isEmpty);
  });

  test('单条提醒：按自定义天数和小时计算', () {
    final target = DateTime(2026, 8, 31, 20, 0);
    final now = DateTime(2026, 8, 1);
    final at = NotificationService.reminderDate(target, 3, 18, now: now);
    expect(at, DateTime(2026, 8, 28, 18, 0));
  });

  test('单条提醒：已过期的返回 null', () {
    final target = DateTime(2026, 8, 31, 20, 0);
    final now = DateTime(2026, 8, 30, 10, 0);
    expect(NotificationService.reminderDate(target, 3, 9, now: now), isNull);
  });

  test('订阅模型通知设置序列化往返', () {
    final sub = Subscription(
      id: 's1',
      name: 'Netflix',
      platform: 'Netflix',
      type: '自动续费',
      amount: 45,
      currency: 'CNY',
      cycle: '包月',
      firstDate: DateTime(2026, 1, 1),
      expiryDate: DateTime(2026, 12, 31),
      status: '生效中',
      createdAt: DateTime(2026, 1, 1),
      notifyEnabled: false,
      notifyDaysBefore: 1,
      notifyHour: 20,
    );
    final restored = Subscription.fromJson(sub.toJson());
    expect(restored.notifyEnabled, isFalse);
    expect(restored.notifyDaysBefore, 1);
    expect(restored.notifyHour, 20);
  });
}
