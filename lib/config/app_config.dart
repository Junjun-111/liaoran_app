/// 编译期配置：阿里云 AI 抠图。
///
/// AccessKey 放在 lib/config/aliyun_secret.dart（已被 gitignore），
/// 这里只放非敏感的项目配置。
class AppConfig {
  AppConfig._();

  /// OSS 存储桶名称（华东2上海）。
  static const ossBucket = 'liaoran-matte-2026';

  /// OSS 地域节点。
  static const ossRegion = 'oss-cn-shanghai';

  /// 视觉智能 API 地域。
  static const viapiRegion = 'cn-shanghai';

  /// 分割抠图 API 版本。
  static const viapiVersion = '2019-12-30';
}
