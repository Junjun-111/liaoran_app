import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/asset_store.dart';
import '../state/subscription_store.dart';

/// 本地通知：订阅到期 / Care 到期提醒（到期前 7 / 3 / 1 天当天上午 9 点）。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 提醒触发小时 / 分钟。
  static const _reminderHour = 9;
  static const _reminderMinute = 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
    } catch (_) {
      // 通知不可用时不阻塞 App
    }
  }

  Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// 计算提醒时刻：到期前 7/3/1 天当天 9 点，已过期的忽略。
  @visibleForTesting
  static List<DateTime> reminderDates(DateTime target, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final results = <DateTime>[];
    for (final days in const [7, 3, 1]) {
      final day = DateTime(target.year, target.month, target.day)
          .subtract(Duration(days: days));
      final remind = DateTime(
        day.year,
        day.month,
        day.day,
        _reminderHour,
        _reminderMinute,
      );
      if (!remind.isBefore(current)) results.add(remind);
    }
    return results;
  }

  /// 计算单条提醒时刻：到期前 [daysBefore] 天 [hour] 点，已过期返回 null。
  @visibleForTesting
  static DateTime? reminderDate(
    DateTime target,
    int daysBefore,
    int hour, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final day = DateTime(target.year, target.month, target.day)
        .subtract(Duration(days: daysBefore));
    final remind = DateTime(day.year, day.month, day.day, hour, 0);
    return remind.isBefore(current) ? null : remind;
  }

  /// 取消全部已排程提醒。
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// 根据当前订阅与资产重新排程全部提醒。
  Future<void> rescheduleAll() async {
    await cancelAll();
    var id = 1;
    for (final sub in SubscriptionStore.instance.items) {
      final target = sub.nextChargeDate ?? sub.expiryDate;
      if (target == null || !sub.notifyEnabled) continue;
      final at = reminderDate(
        target,
        sub.notifyDaysBefore,
        sub.notifyHour,
      );
      if (at == null) continue;
      await _schedule(
        id++,
        at,
        '订阅到期提醒',
        '「${sub.name}」将在 ${sub.notifyDaysBefore} 天后扣款'
            '（${_fmt(target)}），记得处理自动续费',
      );
    }
    for (final asset in AssetStore.instance.items) {
      final care = asset.careExpiryDate;
      if (care == null) continue;
      for (final at in reminderDates(care)) {
        await _schedule(
          id++,
          at,
          'Care 到期提醒',
          '「${asset.name}」的关注将在 ${_daysBefore(care, at)} 天后到期'
              '（${_fmt(care)}）',
        );
      }
    }
  }

  static int _daysBefore(DateTime target, DateTime at) {
    final diff = DateTime(target.year, target.month, target.day)
        .difference(DateTime(at.year, at.month, at.day))
        .inDays;
    return diff > 0 ? diff : 1;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _schedule(
    int id,
    DateTime when,
    String title,
    String body,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          when.year,
          when.month,
          when.day,
          when.hour,
          when.minute,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'liaoran_reminders',
            '到期提醒',
            channelDescription: '订阅到期与 Care 关注到期提醒',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // 单条排程失败不影响其它提醒
    }
  }
}
