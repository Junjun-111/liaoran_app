import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/asset.dart';

/// 回收站条目：被删除的资产 + 删除时间。
class TrashEntry {
  const TrashEntry({required this.asset, required this.deletedAt});

  final Asset asset;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => {
        'asset': asset.toJson(),
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory TrashEntry.fromJson(Map<String, dynamic> json) => TrashEntry(
        asset: Asset.fromJson(json['asset'] as Map<String, dynamic>),
        deletedAt: DateTime.parse(json['deletedAt'] as String),
      );
}

/// 回收站的本地持久化实现（SharedPreferences）。
class LocalTrashRepository {
  LocalTrashRepository._();

  static final LocalTrashRepository instance = LocalTrashRepository._();

  static const _storageKey = 'liaoran_trash_v1';

  final List<TrashEntry> _entries = [];
  bool _loaded = false;

  List<TrashEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(
            decoded.map(
              (item) => TrashEntry.fromJson(item as Map<String, dynamic>),
            ),
          );
      }
    } catch (_) {
      // 读取失败时保留空回收站，不影响启动。
    }
    _loaded = true;
  }

  void add(TrashEntry entry) {
    _entries.insert(0, entry);
    unawaited(_persist());
  }

  void remove(TrashEntry entry) {
    _entries.remove(entry);
    unawaited(_persist());
  }

  void clear() {
    _entries.clear();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode([
        for (final entry in _entries) entry.toJson(),
      ]);
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // 写入失败静默处理。
    }
  }
}
