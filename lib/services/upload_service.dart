import 'package:flutter/services.dart';

/// 通过原生相册选择器挑选一张图片，返回复制到应用缓存目录的本地路径。
///
/// 依赖 Android 端 `MainActivity` 注册的 `liaoran/upload` 通道。
class UploadService {
  UploadService._();

  static const MethodChannel _channel = MethodChannel('liaoran/upload');

  /// 打开系统相册；用户取消或失败时返回 null。
  static Future<String?> pickImage() async {
    try {
      final path = await _channel.invokeMethod<String>('pickImage');
      return (path == null || path.isEmpty) ? null : path;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
