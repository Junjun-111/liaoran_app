import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/models/asset.dart';
import '../domain/models/wishlist_item.dart';
import '../models/subscription.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../state/trash_store.dart';
import '../state/wishlist_store.dart';

/// 备份文件的原生写入通道（Android 端 `liaoran/backup`）。
///
/// 仅用于坚果云还原前，把当前数据自动存档到应用私有目录 `files/backups/`。
class BackupService {
  BackupService._();

  static const MethodChannel _channel = MethodChannel('liaoran/backup');

  static Future<String> write(String name, String content) async =>
      await _channel.invokeMethod<String>('writeFile', {
        'name': name,
        'content': content,
      }) ??
      '';
}

/// 备份内容组装与恢复（纯 Dart，可在测试中直接调用）。
class BackupManager {
  BackupManager._();

  static const _version = 1;

  /// 导出全部数据为 JSON 字符串
  static String buildPayload() {
    return jsonEncode(_buildPayloadCore());
  }

  /// 构建 JSON 数据主体（不含照片内容）。
  static Map<String, dynamic> _buildPayloadCore() {
    final settings = SettingsStore.instance;
    final payload = <String, dynamic>{
      'version': _version,
      'createdAt': DateTime.now().toIso8601String(),
      'assets': [
        for (final a in AssetStore.instance.items) a.toJson(),
      ],
      'subscriptions': [
        for (final s in SubscriptionStore.instance.items) s.toJson(),
      ],
      'wishes': [
        for (final w in WishlistStore.instance.items) w.toJson(),
      ],
      'settings': <String, dynamic>{
        'currency': settings.currency,
        'decimalPlaces': settings.decimalPlaces,
        'viewStyle': settings.viewStyle,
        'categories': settings.categories,
        'tags': settings.tags,
        'lockEnabled': settings.lockEnabled,
        'passcode': settings.passcode,
        'nickname': settings.nickname,
        'avatarPath': settings.avatarPath,
      },
    };
    payload['files'] = <String, String>{};
    return payload;
  }

  /// 异步收集本地照片（图标/附件/头像）并生成完整备份内容。
  /// 用异步读取避免界面线程卡顿。
  static Future<String> buildPayloadAsync() async {
    final payload = _buildPayloadCore();
    final files = <String, String>{};
    var seq = 0;
    Future<String?> collect(String? path) async {
      if (path == null || path.isEmpty || path.endsWith('.svg')) return path;
      final file = File(path);
      if (!file.existsSync()) return path;
      seq++;
      final id = 'f$seq';
      try {
        files[id] = base64Encode(await file.readAsBytes());
        return 'backup://$id';
      } catch (_) {
        return path;
      }
    }

    for (final a in payload['assets'] as List) {
      final m = a as Map<String, dynamic>;
      m['icon'] = await collect(m['icon'] as String?);
      m['attachmentPath'] = await collect(m['attachmentPath'] as String?);
    }
    for (final s in payload['subscriptions'] as List) {
      final m = s as Map<String, dynamic>;
      m['icon'] = await collect(m['icon'] as String?);
      m['attachmentPath'] = await collect(m['attachmentPath'] as String?);
    }
    for (final w in payload['wishes'] as List) {
      final m = w as Map<String, dynamic>;
      m['icon'] = await collect(m['icon'] as String?);
    }
    final settingsMap = payload['settings'] as Map<String, dynamic>;
    settingsMap['avatarPath'] =
        await collect(settingsMap['avatarPath'] as String?);

    payload['files'] = files;
    return jsonEncode(payload);
  }

  /// 把当前数据自动存档到应用私有目录（坚果云还原前的安全网）。
  static Future<String> createBackup() async {
    final name = '了然backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final content = await buildPayloadAsync();
    await BackupService.write(name, content);
    return name;
  }

  /// 从备份内容恢复（私有备份与外部导入共用）。
  static Future<String> restoreFromContent(String content) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return '备份文件已损坏，无法恢复';
    }

    // 先把备份里的照片写回手机本地，再把占位路径替换成真实路径
    final files = data['files'] as Map<String, dynamic>? ?? const {};
    final pathMap = <String, String>{};
    if (files.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        for (final entry in files.entries) {
          try {
            final bytes = base64Decode(entry.value as String);
            final out = File(
              '${dir.path}/restore_${entry.key}_'
              '${DateTime.now().millisecondsSinceEpoch}.png',
            );
            await out.writeAsBytes(bytes, flush: true);
            pathMap[entry.key] = out.path;
          } catch (_) {
            // 单个文件失败不影响整体恢复
          }
        }
      } catch (_) {
        // 无法写入时忽略照片，其他数据照常恢复
      }
    }
    _replacePlaceholders(data, pathMap);

    // 资产
    final assets = <Asset>[
      for (final a in (data['assets'] as List? ?? const []))
        Asset.fromJson(a as Map<String, dynamic>),
    ];
    AssetStore.instance.replaceAll(assets);

    // 订阅
    final subscriptions = <Subscription>[
      for (final s in (data['subscriptions'] as List? ?? const []))
        Subscription.fromJson(s as Map<String, dynamic>),
    ];
    SubscriptionStore.instance.replaceAll(subscriptions);

    // 心愿
    final wishes = <WishlistItem>[
      for (final w in (data['wishes'] as List? ?? const []))
        WishlistItem.fromJson(w as Map<String, dynamic>),
    ];
    WishlistStore.instance.replaceAll(wishes);

    // 回收站与备份状态保持一致（备份内容不含回收站）
    TrashStore.instance.clear();

    // 设置
    final settingsJson = data['settings'] as Map<String, dynamic>?;
    if (settingsJson != null) {
      final settings = SettingsStore.instance;
      settings.updateCurrency(settingsJson['currency'] as String? ?? 'CNY');
      settings.updateDecimalPlaces(
        (settingsJson['decimalPlaces'] as num?)?.toInt() ?? 2,
      );
      settings.updateViewStyle(settingsJson['viewStyle'] as String? ?? '双列');
      for (final c in settings.categories.toList()) {
        settings.removeCategory(c);
      }
      for (final c in (settingsJson['categories'] as List? ?? const [])) {
        settings.addCategory(c as String);
      }
      for (final t in settings.tags.toList()) {
        settings.removeTag(t);
      }
      for (final t in (settingsJson['tags'] as List? ?? const [])) {
        settings.addTag(t as String);
      }
      if (settingsJson['lockEnabled'] == true) {
        settings.enableLock(settingsJson['passcode'] as String? ?? '');
      } else {
        settings.disableLock();
      }
      final nickname = settingsJson['nickname'] as String?;
      if (nickname != null && nickname.isNotEmpty) {
        settings.updateNickname(nickname);
      }
      settings.updateAvatarPath(settingsJson['avatarPath'] as String?);
    }

    return '恢复成功：资产 ${assets.length}、订阅 ${subscriptions.length}、心愿 ${wishes.length}';
  }

  /// 深度替换备份中的占位路径（backup://xxx）为恢复后的真实路径。
  static void _replacePlaceholders(Object? node, Map<String, String> pathMap) {
    if (node is Map) {
      for (final key in node.keys.toList()) {
        final value = node[key];
        if (value is String && value.startsWith('backup://')) {
          final id = value.substring('backup://'.length);
          final real = pathMap[id];
          if (real != null) node[key] = real;
        } else {
          _replacePlaceholders(value, pathMap);
        }
      }
    } else if (node is List) {
      for (final item in node) {
        _replacePlaceholders(item, pathMap);
      }
    }
  }
}
