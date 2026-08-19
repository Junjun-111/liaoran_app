import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../services/nutstore_service.dart';
import '../theme/app_theme.dart';

/// 坚果云同步弹层：配置 / 备份 / 还原 / 管理 四个标签页。
class NutstoreSyncSheet extends StatefulWidget {
  const NutstoreSyncSheet({super.key});

  @override
  State<NutstoreSyncSheet> createState() => _NutstoreSyncSheetState();
}

class _NutstoreSyncSheetState extends State<NutstoreSyncSheet> {
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF2F80ED);

  int _tab = 0;
  String? _error;
  String? _success;
  bool _loading = false;

  late final TextEditingController _serverCtrl = TextEditingController(
    text: NutstoreService.server,
  );
  late final TextEditingController _userCtrl = TextEditingController(
    text: NutstoreService.user,
  );
  final TextEditingController _passCtrl = TextEditingController();

  List<String> _backups = const [];
  bool _manageLoading = false;

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// 卡片内反馈条：成功绿色、失败红色，始终显示在最上层。
  void _feedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      if (isError) {
        _error = message;
        _success = null;
      } else {
        _success = message;
        _error = null;
      }
    });
  }

  void _showError(Object e) {
    if (!mounted) return;
    if (e is NutstoreAuthException) {
      _feedback(e.message, isError: true);
    } else {
      _feedback(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _setTab(int i) {
    setState(() {
      _tab = i;
      _error = null;
      _success = null;
    });
    if (i == 3) _refreshManage();
  }

  // ── 配置 ────────────────────────────────────────────────

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NutstoreService.save(
        server: _serverCtrl.text,
        user: _userCtrl.text,
        pass: _passCtrl.text,
      );
      await NutstoreService.testConnection();
      if (mounted) {
        setState(() => _loading = false);
        _feedback('连接成功');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NutstoreService.save(
        server: _serverCtrl.text,
        user: _userCtrl.text,
        pass: _passCtrl.text,
      );
      await NutstoreService.testConnection();
      if (mounted) {
        setState(() => _loading = false);
        _feedback('配置已保存，连接成功');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(e);
    }
  }

  // ── 备份 ────────────────────────────────────────────────

  Future<void> _backupNow() async {
    if (!NutstoreService.isConfigured) {
      _feedback('请先在“配置”里填写坚果云账号');
      _setTab(0);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = NutstoreService.backupName(DateTime.now());
      final content = BackupManager.buildPayload();
      await NutstoreService.uploadBackup(name, content);
      if (mounted) {
        setState(() => _loading = false);
        _feedback('已备份到云端：$name');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(e);
    }
  }

  // ── 还原 ────────────────────────────────────────────────

  Future<void> _restoreLatest() async {
    if (!NutstoreService.isConfigured) {
      _feedback('请先在“配置”里填写坚果云账号');
      _setTab(0);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 还原前先把当前数据自动保存到本地临时存储
      await BackupManager.createBackup();
      final list = await NutstoreService.listBackups();
      if (list.isEmpty) {
        if (mounted) {
          setState(() => _loading = false);
          _feedback('云端暂无备份');
        }
        return;
      }
      final content = await NutstoreService.downloadBackup(list.first);
      if (content == null) {
        if (mounted) {
          setState(() => _loading = false);
          _feedback('备份文件不存在');
        }
        return;
      }
      final result = await BackupManager.restoreFromContent(content);
      if (mounted) {
        setState(() => _loading = false);
        _feedback(result);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(e);
    }
  }

  // ── 管理 ────────────────────────────────────────────────

  Future<void> _refreshManage() async {
    setState(() {
      _manageLoading = true;
      _error = null;
    });
    try {
      final list = await NutstoreService.listBackups();
      if (mounted) {
        setState(() {
          _backups = list;
          _manageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _manageLoading = false);
      _showError(e);
    }
  }

  Future<void> _restoreOne(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '确认还原',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text('确定从「$name」还原吗？当前数据会先自动备份到本地。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '还原',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await BackupManager.createBackup();
      final content = await NutstoreService.downloadBackup(name);
      if (content == null) {
        if (mounted) {
          setState(() => _loading = false);
          _feedback('备份文件不存在');
        }
        return;
      }
      final result = await BackupManager.restoreFromContent(content);
      if (mounted) {
        setState(() => _loading = false);
        _feedback(result);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<void> _deleteOne(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '删除备份',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text('确定删除云端备份「$name」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE5484D),
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await NutstoreService.deleteBackup(name);
      _feedback('已删除云端备份');
      await _refreshManage();
    } catch (e) {
      _showError(e);
    }
  }

  // ── 界面 ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Material(
      // 居中弹窗需要 Material 祖先，输入框才能正常工作
      color: Colors.transparent,
      child: Padding(
        // 键盘弹起时整体上移，保证输入框可见
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenH * 0.85,
            maxWidth: 380,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                if (_error != null) _errorBanner(),
                if (_success != null) _successBanner(),
                _tabBar(),
                const SizedBox(height: 16),
                Flexible(child: _tabContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '坚果云同步',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF9AA0A6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: Color(0xFFE5484D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB42318),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFFB42318),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Color(0xFF0A7C4E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _success!,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A7C4E),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _success = null),
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF0A7C4E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    const labels = ['配置', '备份', '还原', '管理'];
    const icons = [
      Icons.cloud_outlined,
      Icons.upload_outlined,
      Icons.download_outlined,
      Icons.folder_outlined,
    ];
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 16,
                      color: active ? _green : const Color(0xFF9AA0A6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? _green : const Color(0xFF9AA0A6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    switch (_tab) {
      case 0:
        return _configTab();
      case 1:
        return _backupTab();
      case 2:
        return _restoreTab();
      default:
        return _manageTab();
    }
  }

  // ── 配置页 ──────────────────────────────────────────────

  Widget _configTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('服务器地址'),
          const SizedBox(height: 6),
          _field(_serverCtrl, hint: 'https://dav.jianguoyun.com/dav/'),
          const SizedBox(height: 12),
          _fieldLabel('用户名'),
          const SizedBox(height: 6),
          _field(_userCtrl, hint: '输入用户名'),
          const SizedBox(height: 12),
          _fieldLabel('密码'),
          const SizedBox(height: 6),
          _field(
            _passCtrl,
            hint: NutstoreService.hasPass ? '已保存，留空保持不变' : '输入应用密码',
            obscure: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: '测试连接',
                  color: _blue,
                  onTap: _testConnection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: '保存配置',
                  color: _green,
                  onTap: _saveConfig,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3E3B6)),
            ),
            child: const Text(
              '提示：请使用“应用密码”而非登录密码。可在官网 → 账户信息 → 安全选项 → 应用密码中生成。',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF8A6D1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 备份页 ──────────────────────────────────────────────

  Widget _backupTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const _BigIcon(
            color: _green,
            icon: Icons.upload_outlined,
          ),
          const SizedBox(height: 12),
          const Text(
            '手动备份',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '将当前所有数据备份到云端',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _actionButton(
            label: '立即备份',
            color: _green,
            icon: Icons.upload_outlined,
            onTap: _backupNow,
          ),
          const SizedBox(height: 16),
          _infoCard(
            icon: Icons.calendar_today_outlined,
            title: '命名规范',
            content: 'backup_YYYYMMDD_HHmmss.json',
          ),
          const SizedBox(height: 8),
          _infoCard(
            icon: Icons.storage_outlined,
            title: '存储目录',
            content: '/liaoran-backups/',
          ),
        ],
      ),
    );
  }

  // ── 还原页 ──────────────────────────────────────────────

  Widget _restoreTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const _BigIcon(
            color: _blue,
            icon: Icons.download_outlined,
          ),
          const SizedBox(height: 12),
          const Text(
            '从最新备份还原',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '一键恢复应用至最新状态',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _actionButton(
            label: '从最新备份还原',
            color: _blue,
            icon: Icons.download_outlined,
            onTap: _restoreLatest,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3E3B6)),
            ),
            child: const Text(
              '注意：还原前会自动保存当前数据至本地临时存储，如需选择历史备份还原，请切换到“管理”标签页。',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF8A6D1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 管理页 ──────────────────────────────────────────────

  Widget _manageTab() {
    if (_manageLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_backups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 44,
              color: Color(0xFFD3D7DB),
            ),
            const SizedBox(height: 10),
            const Text(
              '暂无备份文件',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '请先进行备份操作',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _refreshManage,
              child: const Text(
                '刷新',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _backups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final name = _backups[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FAF8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _prettyName(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _restoreOne(name),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    '还原',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteOne(name),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFE5484D),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _prettyName(String name) {
    final match = RegExp(r'backup_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})')
        .firstMatch(name);
    if (match == null) return name;
    return '${match[1]}-${match[2]}-${match[3]} '
        '${match[4]}:${match[5]}:${match[6]}';
  }

  // ── 通用小组件 ──────────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.manrope,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8E8E93),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            color: Color(0xFFB8BDC2),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9AA0A6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigIcon extends StatelessWidget {
  const _BigIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 30, color: color),
      ),
    );
  }
}
