import 'dart:io';

import 'package:liaoran_app/services/aliyun_client.dart';

/// 阿里云抠图链路自测（本机运行，不入 App）：
///   dart run tool/test_aliyun.dart <输入图片> [输出PNG]
Future<void> main(List<String> args) async {
  final src = args.isNotEmpty ? args[0] : 'test.jpg';
  final out = args.length > 1 ? args[1] : 'matte_result.png';

  final srcFile = File(src);
  if (!await srcFile.exists()) {
    stdout.writeln('图片不存在: $src');
    exit(1);
  }

  final bytes = await srcFile.readAsBytes();
  final watch = Stopwatch()..start();
  try {
    final png = await AliyunClient.matteJpeg(bytes);
    watch.stop();
    await File(out).writeAsBytes(png);
    stdout.writeln(
      '抠图成功：${png.length} 字节，耗时 ${watch.elapsedMilliseconds}ms，'
      '结果已保存到 $out',
    );
  } catch (e) {
    watch.stop();
    stderr.writeln('抠图失败（${watch.elapsedMilliseconds}ms）：$e');
    exit(1);
  }
}
