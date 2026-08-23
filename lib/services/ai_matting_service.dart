import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'aliyun_client.dart';

/// AI 抠图服务（App 层封装）。
///
/// 流程：读图 → 压缩 → 交给 [AliyunClient] 走阿里云商品分割 →
/// 把透明底 PNG 保存到 App 文档目录（重启不丢失）。
class AiMattingService {
  AiMattingService._();

  /// 抠图后把结果保存到手机本地，返回 PNG 文件的绝对路径。
  static Future<String> matte({required String sourcePath}) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const AiMattingException('图片文件不存在，请重新选择');
    }

    final bytes = await compress(source);
    return matteBytes(bytes);
  }

  /// 直接对图片字节抠图并保存到手机本地，返回 PNG 文件绝对路径。
  static Future<String> matteBytes(Uint8List jpegBytes) async {
    final png = await AliyunClient.matteJpeg(jpegBytes);
    final isPng = png.length >= 8 &&
        png[0] == 0x89 &&
        png[1] == 0x50 &&
        png[2] == 0x4E &&
        png[3] == 0x47;
    if (!isPng) {
      throw const AiMattingException('抠图结果异常，请重试');
    }

    return savePng(png, prefix: 'ai_matte');
  }

  /// 把 PNG 字节保存到 App 文档目录，返回文件绝对路径。
  static Future<String> savePng(Uint8List bytes, {String prefix = 'icon'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final outFile = File(
      '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile.path;
  }

  /// 抠图失败时的兜底：把原图压缩后存为图标，避免流程中断。
  static Future<String> savePhotoAsIcon(String sourcePath) async {
    final bytes = await compress(File(sourcePath));
    final dir = await getApplicationDocumentsDirectory();
    final outFile = File(
      '${dir.path}/icon_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile.path;
  }

  /// 把图片压缩到最长边 1280px、JPG 质量 88（商品分割要求 <2000px、<3MB）。
  static Future<Uint8List> compress(File source) async {
    final bytes = await source.readAsBytes();
    // 解码/缩放/编码全部在后台 isolate 执行，避免界面卡顿
    return compute(_compressSync, bytes);
  }
}

/// 后台 isolate 执行的压缩流程。
Uint8List _compressSync(Uint8List bytes) {
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw const AiMattingException('无法读取图片，请换一张试试');
    }
    var image = original;
    const maxDim = 1280;
    if (image.width > maxDim || image.height > maxDim) {
      final longer = image.width > image.height ? image.width : image.height;
      final scale = maxDim / longer;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}
