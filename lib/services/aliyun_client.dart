import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/aliyun_secret.dart';
import '../config/app_config.dart';

/// 阿里云抠图客户端（纯 Dart，可独立测试）。
///
/// 流程：把图片上传到 OSS（私有桶 + 签名 URL）→ 调用商品分割
/// SegmentCommodity（RPC 签名）→ 下载透明底 PNG 返回。
class AliyunClient {
  AliyunClient._();

  static final Random _random = Random.secure();

  /// 完整抠图流程：输入 JPEG 字节，返回透明底 PNG 字节。
  static Future<Uint8List> matteJpeg(Uint8List jpegBytes) async {
    try {
      final key = await _uploadToOss(jpegBytes);
      final imageUrl = _signedGetUrl(key);
      final resultUrl = await _segmentCommodity(imageUrl);
      final resp = await http
          .get(Uri.parse(resultUrl))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) {
        throw AiMattingException('抠图结果下载失败（${resp.statusCode}）');
      }
      return resp.bodyBytes;
    } on AiMattingException {
      rethrow;
    } catch (_) {
      throw const AiMattingException('网络连接失败，请检查网络后重试');
    }
  }

  // ── OSS 上传 ──────────────────────────────────────────────

  /// 把图片上传到 OSS 私有桶，返回对象 key。
  static Future<String> _uploadToOss(Uint8List bytes) async {
    final key =
        'matte/${DateTime.now().millisecondsSinceEpoch}_${_nonce()}.jpg';
    final expires =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 3600;
    final stringToSign =
        'PUT\n\nimage/jpeg\n$expires\n/${AppConfig.ossBucket}/$key';
    final signature = _hmac(stringToSign);
    final url = Uri.parse(
      'https://${AppConfig.ossBucket}.${AppConfig.ossRegion}.aliyuncs.com/$key'
      '?Expires=$expires&OSSAccessKeyId=${AliyunSecret.accessKeyId}'
      '&Signature=${_pctEncode(signature)}',
    );
    final resp = await http.put(
      url,
      headers: {'Content-Type': 'image/jpeg'},
      body: bytes,
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw AiMattingException('图片上传失败（${resp.statusCode}），请稍后重试');
    }
    return key;
  }

  /// 生成 OSS 私有桶对象的临时公开读 URL（签名 GET）。
  static String _signedGetUrl(String key) {
    final expires =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 3600;
    final stringToSign = 'GET\n\n\n$expires\n/${AppConfig.ossBucket}/$key';
    final signature = _hmac(stringToSign);
    return 'https://${AppConfig.ossBucket}.${AppConfig.ossRegion}.aliyuncs.com/$key'
        '?Expires=$expires&OSSAccessKeyId=${AliyunSecret.accessKeyId}'
        '&Signature=${_pctEncode(signature)}';
  }

  // ── 商品分割 RPC 调用 ─────────────────────────────────────

  static Future<String> _segmentCommodity(String imageUrl) async {
    final params = <String, String>{
      'AccessKeyId': AliyunSecret.accessKeyId,
      'Action': 'SegmentCommodity',
      'Format': 'JSON',
      'RegionId': AppConfig.viapiRegion,
      'SignatureMethod': 'HMAC-SHA1',
      'SignatureNonce': '${DateTime.now().microsecondsSinceEpoch}${_nonce()}',
      'SignatureVersion': '1.0',
      'Timestamp': _utcTimestamp(),
      'Version': AppConfig.viapiVersion,
      'ImageURL': imageUrl,
    };

    final keys = params.keys.toList()..sort();
    final canonical = keys
        .map((k) => '${_pctEncode(k)}=${_pctEncode(params[k]!)}')
        .join('&');
    final stringToSign = 'POST&%2F&${_pctEncode(canonical)}';
    final signature = _hmac(stringToSign, withAmp: true);

    final resp = await http
        .post(
          Uri.parse('https://imageseg.cn-shanghai.aliyuncs.com/'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: '$canonical&Signature=${_pctEncode(signature)}',
        )
        .timeout(const Duration(seconds: 60));

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(resp.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw AiMattingException('抠图服务响应异常（${resp.statusCode}）');
    }

    final data = decoded['Data'] ?? decoded['data'];
    final resultUrl = data is Map
        ? (data['ImageURL'] ?? data['imageURL'])
        : null;
    if (resultUrl is String && resultUrl.isNotEmpty) {
      return resultUrl;
    }
    final message = decoded['Message'] ??
        decoded['message'] ??
        decoded['Code'] ??
        '未知错误';
    throw AiMattingException('抠图失败：$message');
  }

  // ── 签名工具 ──────────────────────────────────────────────

  /// OSS 签名密钥为 Secret；RPC 签名密钥为 Secret + '&'。
  static String _hmac(String stringToSign, {bool withAmp = false}) {
    final key = utf8.encode(AliyunSecret.accessKeySecret + (withAmp ? '&' : ''));
    final digest = Hmac(sha1, key).convert(utf8.encode(stringToSign));
    return base64Encode(digest.bytes);
  }

  /// 阿里云规定的百分号编码（大写十六进制，保留 -_.~）。
  static String _pctEncode(String s) {
    const unreserved =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~';
    final out = StringBuffer();
    for (final byte in utf8.encode(s)) {
      final c = String.fromCharCode(byte);
      if (unreserved.contains(c)) {
        out.write(c);
      } else {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }

  static String _utcTimestamp() {
    final t = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}T'
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}Z';
  }

  static String _nonce() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// 抠图过程中的业务异常，message 可直接展示给用户。
class AiMattingException implements Exception {
  const AiMattingException(this.message);

  final String message;

  @override
  String toString() => message;
}
