import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

/// 认证失败（账号或密码错误）
class NutstoreAuthException implements Exception {
  const NutstoreAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 坚果云 WebDAV 同步服务。
///
/// 账号密码（应用密码）保存在手机本地，仅用于向坚果云请求。
class NutstoreService {
  NutstoreService._();

  static const _serverKey = 'nutstore_server';
  static const _userKey = 'nutstore_user';
  static const _passKey = 'nutstore_pass';

  static const defaultServer = 'https://dav.jianguoyun.com/dav/';
  static const remoteDir = 'liaoran-backups/';
  static const _propfindBody =
      '<?xml version="1.0" encoding="utf-8"?>'
      '<d:propfind xmlns:d="DAV:"><d:allprop/></d:propfind>';

  static String _server = defaultServer;
  static String _user = '';
  static String _pass = '';

  static bool get isConfigured => _user.isNotEmpty && _pass.isNotEmpty;

  static String get server => _server;

  static String get user => _user;

  static bool get hasPass => _pass.isNotEmpty;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _server = prefs.getString(_serverKey) ?? defaultServer;
      _user = prefs.getString(_userKey) ?? '';
      _pass = prefs.getString(_passKey) ?? '';
    } catch (_) {
      // 保持默认
    }
  }

  static Future<void> save({
    required String server,
    required String user,
    required String pass,
  }) async {
    _server = server.trim().isEmpty ? defaultServer : server.trim();
    _user = user.trim();
    // 密码留空表示沿用已保存的密码
    _pass = pass.trim().isEmpty ? _pass : pass.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverKey, _server);
      await prefs.setString(_userKey, _user);
      await prefs.setString(_passKey, _pass);
    } catch (_) {
      // 至少保留内存值
    }
  }

  static Future<void> clear() async {
    _user = '';
    _pass = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_passKey);
    } catch (_) {}
  }

  static String _serverBase() {
    var s = _server;
    if (!s.endsWith('/')) s = '$s/';
    return s;
  }

  static Map<String, String> _authHeaders() => {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_user:$_pass'))}',
      };

  static Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final request = http.Request(method, uri);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;
    final streamed = await http.Client().send(request);
    return http.Response.fromStream(streamed);
  }

  static Uri _dirUri() => Uri.parse('${_serverBase()}$remoteDir');

  static Uri _fileUri(String name) => Uri.parse('${_serverBase()}$remoteDir$name');

  static void _checkStatus(http.Response resp) {
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw const NutstoreAuthException('账号或密码错误，请重新输入');
    }
  }

  static Exception _httpException(http.Response resp, String action) {
    if (resp.statusCode == 503 || resp.statusCode == 429) {
      return Exception('$action：云端同步过于频繁，请稍候几分钟再试（${resp.statusCode}）');
    }
    return Exception('$action（${resp.statusCode}）');
  }

  /// 测试连接：对服务器根目录做一次深度 0 的 PROPFIND。
  static Future<void> testConnection() async {
    final resp = await _send(
      'PROPFIND',
      Uri.parse(_serverBase()),
      headers: {
        ..._authHeaders(),
        'Depth': '0',
        'Content-Type': 'application/xml; charset=utf-8',
      },
      body: _propfindBody,
    ).timeout(const Duration(seconds: 20));
    _checkStatus(resp);
    if (resp.statusCode != 200 && resp.statusCode != 207) {
      throw _httpException(resp, '连接失败');
    }
  }

  /// 列出云端备份文件名（backup_xxx.json），按名称降序（新的在前）。
  static Future<List<String>> listBackups() async {
    await _ensureDir();
    // 坚果云偶发空响应或 503，最多自动重试一次
    List<String> names = const [];
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final resp = await _send(
        'PROPFIND',
        _dirUri(),
        headers: {
          ..._authHeaders(),
          'Depth': '1',
          'Content-Type': 'application/xml; charset=utf-8',
        },
        body: _propfindBody,
      ).timeout(const Duration(seconds: 30));
      _checkStatus(resp);
      // 目录还不存在视为“暂无备份”
      if (resp.statusCode == 404) return const [];
      if (resp.statusCode != 200 && resp.statusCode != 207) {
        throw _httpException(resp, '获取备份列表失败');
      }
      names = parseBackupNames(utf8.decode(resp.bodyBytes));
      if (names.isNotEmpty) break;
    }
    final list = names.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  /// 从 WebDAV PROPFIND 的 207 响应体中解析备份文件名。
  ///
  /// 兼容不同前缀（d:/D: 或空前缀）、完整 URL 与百分号编码的文件名。
  static List<String> parseBackupNames(String xmlBody) {
    final names = <String>{};
    try {
      final doc = XmlDocument.parse(xmlBody);
      for (final el in doc.descendants.whereType<XmlElement>()) {
        if (el.name.local.toLowerCase() != 'href') continue;
        final href = el.innerText.trim();
        final raw =
            href.split('/').where((s) => s.isNotEmpty).lastOrNull ?? '';
        final name = _decodeName(raw);
        if (name.endsWith('.json')) {
          names.add(name);
        }
      }
    } catch (_) {
      // 解析失败时返回空列表
    }
    return names.toList();
  }

  static String _decodeName(String name) {
    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  }

  static Future<void> uploadBackup(String name, String content) async {
    await _ensureDir();
    final resp = await http
        .put(
          _fileUri(name),
          headers: {
            ..._authHeaders(),
            'Content-Type': 'application/json',
          },
          body: content,
        )
        .timeout(const Duration(seconds: 60));
    _checkStatus(resp);
    if (resp.statusCode != 200 && resp.statusCode != 201 && resp.statusCode != 204) {
      throw _httpException(resp, '上传失败');
    }
  }

  static Future<String?> downloadBackup(String name) async {
    final resp = await http
        .get(_fileUri(name), headers: _authHeaders())
        .timeout(const Duration(seconds: 60));
    _checkStatus(resp);
    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) {
      throw _httpException(resp, '下载失败');
    }
    return utf8.decode(resp.bodyBytes);
  }

  static Future<void> deleteBackup(String name) async {
    final resp = await http
        .delete(_fileUri(name), headers: _authHeaders())
        .timeout(const Duration(seconds: 30));
    _checkStatus(resp);
    if (resp.statusCode != 200 && resp.statusCode != 204 && resp.statusCode != 404) {
      throw _httpException(resp, '删除失败');
    }
  }

  /// 确保远端目录存在（不存在则创建）。
  static Future<void> _ensureDir() async {
    final resp = await _send(
      'MKCOL',
      _dirUri(),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 20));
    // 201 创建成功 / 405 已存在，均视为正常
    if (resp.statusCode != 201 && resp.statusCode != 405) {
      _checkStatus(resp);
      throw Exception('无法访问云端目录（${resp.statusCode}）');
    }
  }

  /// 生成云端备份文件名：了然backup_YYYYMMDD_HHmmss.json
  static String backupName(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '了然backup_${time.year}${two(time.month)}${two(time.day)}'
        '_${two(time.hour)}${two(time.minute)}${two(time.second)}.json';
  }
}
