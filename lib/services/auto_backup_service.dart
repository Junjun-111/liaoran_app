import '../state/settings_store.dart';
import 'backup_service.dart';
import 'nutstore_service.dart';

/// 每周自动备份：开关开启 + 坚果云已配置时，
/// App 启动检查距上次自动备份是否超过 7 天，是则自动上传一次。
class AutoBackupService {
  AutoBackupService._();

  static const _interval = Duration(days: 7);

  static bool _running = false;

  /// 启动时检查并执行自动备份（失败静默，不影响下次再试）。
  static Future<void> maybeRun() async {
    if (_running) return;
    if (!SettingsStore.instance.autoBackupEnabled) return;
    if (!NutstoreService.isConfigured) return;

    final last = SettingsStore.instance.lastAutoBackupAt;
    if (last != null &&
        DateTime.now().difference(last).inDays < _interval.inDays) {
      return;
    }

    _running = true;
    try {
      final name = NutstoreService.backupName(DateTime.now());
      final content = await BackupManager.buildPayloadAsync();
      await NutstoreService.uploadBackup(name, content);
      SettingsStore.instance.updateLastAutoBackupAt(DateTime.now());
    } catch (_) {
      // 网络或云端异常时静默跳过，下次启动再试
    } finally {
      _running = false;
    }
  }
}
