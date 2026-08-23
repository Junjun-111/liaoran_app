import 'dart:io' show File;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import '../domain/dictionaries.dart';
import '../services/lock_gate.dart';
import '../services/upload_service.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialog_controllers.dart';
import '../widgets/nutstore_sync_sheet.dart';
import '../widgets/page_header.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/top_snackbar.dart';
import 'about_page.dart';
import 'lock_screen.dart';
import 'trash_page.dart';
/// 个人中心页：设置全部可交互（货币/小数点/视图样式/分类标签/坚果云同步/锁定）。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onNavTap});
  final ValueChanged<int>? onNavTap;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final headerTop =
        PageHeader.headerTopFor(MediaQuery.of(context).padding.top);
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final settings = SettingsStore.instance;
        return PageScaffold(
          title: '',
          subtitle: '',
          currentIndex: 4,
          onNavTap: widget.onNavTap,
          bodyPadding: const EdgeInsets.symmetric(horizontal: 25),
          header: Padding(
            padding: EdgeInsets.only(top: headerTop + 28, left: 25, right: 25),
            child: _Avatar(
              nickname: settings.nickname,
              avatarPath: settings.avatarPath,
              onEdit: () => _editProfile(context),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 0),
              _SettingsGroup(
                title: '数值与单位',
                items: [
                  _SettingsItem(
                    icon: '3',
                    iconLeft: -4,
                    badge: '¥',
                    badgeColor: const Color(0xFFF5A623),
                    title: '货币单位',
                    subtitle: settings.currency,
                    onTap: () => _pickCurrency(context),
                  ),
                  _SettingsItem(
                    icon: '6',
                    iconLeft: -4,
                    badge: '#',
                    badgeColor: const Color(0xFF4A90E2),
                    title: '小数点设置',
                    subtitle: '${settings.decimalPlaces} 位',
                    onTap: () => _pickDecimals(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                title: '数据管理',
                items: [
                  _SettingsItem(
                    icon: '8',
                    iconLeft: -4,
                    iconSize: 40,
                    title: '坚果云同步',
                    subtitle: 'WebDAV 云端备份与还原',
                    onTap: () => showGeneralDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '坚果云同步',
                      barrierColor: Colors.transparent,
                      transitionDuration: const Duration(milliseconds: 220),
                      pageBuilder: (ctx, _, _) => Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 3,
                                sigmaY: 3,
                              ),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          const Center(child: NutstoreSyncSheet()),
                        ],
                      ),
                    ),
                  ),
                  _SettingsItem(
                    icon: '10',
                    iconLeft: -4,
                    iconSize: 40,
                    title: '分类管理',
                    onTap: () => _manageNames(context, title: '分类管理', isTag: false),
                  ),
                  _SettingsItem(
                    icon: '12',
                    iconLeft: -4,
                    iconSize: 40,
                    title: '标签管理',
                    onTap: () => _manageNames(context, title: '标签管理', isTag: true),
                  ),
                  _SettingsItem(
                    materialIcon: Icons.delete_sweep_outlined,
                    title: '回收站',
                    subtitle: '最近删除 30 天内可恢复',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TrashPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                title: '显示与外观',
                items: [
                  _SettingsItem(
                    icon: '14',
                    iconLeft: -4,
                    iconSize: 40,
                    title: '功能视图样式',
                    subtitle: settings.viewStyle,
                    onTap: () => _pickViewStyle(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                title: '其他',
                items: [
                  _SettingsItem(
                    materialIcon: Icons.info_outline,
                    title: '关于了然',
                    onTap: () => _openAbout(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _LockButton(onTap: () => _handleLock(context)),
              const SizedBox(height: 16),
              const _Signature(),
            ],
          ),
        );
      },
    );
  }
  // ── 选项选择（底部弹层） ──────────────────────────────────────
  Future<void> _showOptionsSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final option in options)
                GestureDetector(
                  onTap: () => Navigator.of(sheetCtx).pop(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: option == current
                          ? AppColors.navSelectedBg
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (option == current)
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelect(picked);
  }
  void _pickCurrency(BuildContext context) {
    final settings = SettingsStore.instance;
    _showOptionsSheet(
      context,
      title: '货币单位',
      options: Dictionaries.currencies,
      current: settings.currency,
      onSelect: settings.updateCurrency,
    );
  }
  void _pickDecimals(BuildContext context) {
    final settings = SettingsStore.instance;
    _showOptionsSheet(
      context,
      title: '小数点设置',
      options: const ['0 位', '1 位', '2 位'],
      current: '${settings.decimalPlaces} 位',
      onSelect: (v) => settings.updateDecimalPlaces(
        int.parse(v.split(' ').first),
      ),
    );
  }
  void _pickViewStyle(BuildContext context) {
    final settings = SettingsStore.instance;
    _showOptionsSheet(
      context,
      title: '功能视图样式',
      options: Dictionaries.viewStyles,
      current: settings.viewStyle,
      onSelect: settings.updateViewStyle,
    );
  }
  Future<void> _editProfile(BuildContext context) async {
    final result = await showDialog<_ProfileEditResult>(
      context: context,
      builder: (_) => const _ProfileEditDialog(),
    );
    if (result == null || !context.mounted) return;
    SettingsStore.instance.updateNickname(result.nickname);
    SettingsStore.instance.updateAvatarPath(result.avatarPath);
  }
  // ── 分类 / 标签管理 ───────────────────────────────────────────
  void _manageNames(
    BuildContext context, {
    required String title,
    required bool isTag,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameManagerSheet(title: title, isTag: isTag),
    );
  }
  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutPage()),
    );
  }

  // ── 应用锁定 ──────────────────────────────────────────────────
  Future<void> _handleLock(BuildContext context) async {
    final settings = SettingsStore.instance;
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      if (!canCheck || !supported) {
        if (context.mounted) {
          _snack(context, '设备不支持指纹/面容识别');
        }
        return;
      }
      // 立即锁定：开启指纹锁并强制下次进入也要验证；
      // 锁定页本身就是反馈，需要指纹才能回到应用
      settings.enableLock('');
      await LockGate.lockNow();
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    } catch (_) {
      if (context.mounted) {
        _snack(context, '无法启动系统识别，请重试');
      }
    }
  }
  Future<String?> _setupPasscode(BuildContext context) async {
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController(), TextEditingController()],
        builder: (ctx, ctrls) {
          final pwdCtrl = ctrls[0];
          final confirmCtrl = ctrls[1];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '设置锁定密码',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '4 位数字密码',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '确认密码'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  color: AppColors.textHint,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final pwd = pwdCtrl.text.trim();
                if (pwd.length < 4) {
                  setDialogState(() => error = '密码至少 4 位');
                  return;
                }
                if (pwd != confirmCtrl.text.trim()) {
                  setDialogState(() => error = '两次输入不一致');
                  return;
                }
                Navigator.of(ctx).pop(pwd);
              },
              child: const Text(
                '确定',
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
        },
      ),
    );
    return result;
  }
  Future<bool?> _verifyPasscode(BuildContext context) async {
    String? error;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController()],
        builder: (ctx, ctrls) {
          final ctrl = ctrls[0];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '关闭锁定',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '输入当前密码',
              errorText: error,
            ),
          ),
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
              onPressed: () {
                if (ctrl.text.trim() == SettingsStore.instance.passcode) {
                  Navigator.of(ctx).pop(true);
                } else {
                  setDialogState(() => error = '密码错误');
                }
              },
              child: const Text(
                '关闭',
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
        },
      ),
    );
    return result;
  }
  void _snack(BuildContext context, String message) {
    showTopSnackBar(context, message);
  }
}
/// 头像 + 用户名
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.nickname,
    required this.avatarPath,
    required this.onEdit,
  });
  final String nickname;
  final String? avatarPath;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF9F4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3DC78A),
                  width: 2.67,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: avatarPath == null
                    ? SvgPicture.asset(
                        'assets/CodeBuddyAssets/37_333/1.svg',
                        width: 80,
                        height: 80,
                      )
                    : Image.file(
                        File(avatarPath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        cacheWidth: (80 *
                                MediaQuery.of(context).devicePixelRatio)
                            .round(),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              nickname,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _ProfileEditResult {
  const _ProfileEditResult({required this.nickname, required this.avatarPath});
  final String nickname;
  final String? avatarPath;
}
class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog();
  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}
class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final _nameCtrl =
      TextEditingController(text: SettingsStore.instance.nickname);
  String? _avatarPath = SettingsStore.instance.avatarPath;
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
  Future<void> _pickAvatar() async {
    final path = await UploadService.pickImage();
    if (path != null && mounted) {
      setState(() => _avatarPath = path);
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '修改头像与昵称',
        style: TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF9F4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3DC78A),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _avatarPath == null
                    ? SvgPicture.asset(
                        'assets/CodeBuddyAssets/37_333/1.svg',
                        width: 72,
                        height: 72,
                      )
                    : Image.file(
                        File(_avatarPath!),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        cacheWidth: (72 *
                                MediaQuery.of(context).devicePixelRatio)
                            .round(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: '昵称',
              labelStyle: const TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              color: AppColors.textHint,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _ProfileEditResult(nickname: name, avatarPath: _avatarPath),
            );
          },
          child: const Text(
            '保存',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
/// 设置分组：小标题 + 白色卡片（含多行）
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});
  final String title;
  final List<Widget> items;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFAEAEB2),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Container(
                    height: 0.67,
                    margin: const EdgeInsets.only(left: 16),
                    color: const Color(0xFFF2F2F7),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
/// 设置项：图标 + 标题/副标题 + 右箭头（可点击）
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    this.icon = '',
    this.materialIcon,
    required this.title,
    this.iconLeft = 0,
    this.iconSize = 32,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.onTap,
  });
  final String icon;
  final IconData? materialIcon;
  final String title;
  final double iconLeft;
  final double iconSize;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Transform.translate(
                offset: Offset(iconLeft, 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: materialIcon != null
                          ? Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                materialIcon,
                                size: 18,
                                color: Colors.white,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/CodeBuddyAssets/37_333/$icon.svg',
                              width: iconSize,
                              height: iconSize,
                            ),
                    ),
                    if (badge != null)
                      Positioned(
                      left: 0,
                      top: 0,
                      width: iconSize,
                      height: iconSize,
                        child: Center(
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: badge == '¥' ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/CodeBuddyAssets/37_333/9.svg',
              width: 12,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
/// 红色"立即锁定"按钮（已开启时变为关闭入口）
class _LockButton extends StatelessWidget {
  const _LockButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/CodeBuddyAssets/37_333/16.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              '立即锁定',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// 底部署名
class _Signature extends StatelessWidget {
  const _Signature();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '了然 · 小不点.',
        style: TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFFC0C0C0),
        ),
      ),
    );
  }
}
/// 分类 / 标签管理弹层
class _NameManagerSheet extends StatefulWidget {
  const _NameManagerSheet({required this.title, required this.isTag});
  final String title;
  final bool isTag;
  @override
  State<_NameManagerSheet> createState() => _NameManagerSheetState();
}
class _NameManagerSheetState extends State<_NameManagerSheet> {
  List<String> get _names =>
      widget.isTag
          ? SettingsStore.instance.tags
          : SettingsStore.instance.categories;
  Future<void> _add() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController()],
        builder: (ctx, ctrls) {
          final ctrl = ctrls[0];
          return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '新增${widget.isTag ? '标签' : '分类'}',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: '名称',
            labelStyle: TextStyle(
              fontFamily: AppFonts.manrope,
              color: AppColors.textHint,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text(
              '添加',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
    if (name != null && name.isNotEmpty) {
      if (widget.isTag) {
        SettingsStore.instance.addTag(name);
      } else {
        SettingsStore.instance.addCategory(name);
      }
    }
  }
  Future<void> _rename(String oldName) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController(text: oldName)],
        builder: (ctx, ctrls) {
          final ctrl = ctrls[0];
          return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '重命名${widget.isTag ? '标签' : '分类'}',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(labelText: '新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text(
              '保存',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != oldName) {
      if (widget.isTag) {
        SettingsStore.instance.renameTag(oldName, newName);
      } else {
        SettingsStore.instance.renameCategory(oldName, newName);
      }
    }
  }
  Future<void> _remove(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '确认删除',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text('确定删除「$name」吗？'),
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
    if (ok == true) {
      if (widget.isTag) {
        SettingsStore.instance.removeTag(name);
      } else {
        SettingsStore.instance.removeCategory(name);
      }
    }
  }
    @override
    Widget build(BuildContext context) {
      return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final names = _names;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (names.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '暂无数据，点击下方按钮添加',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final name in names)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FAF8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: AppFonts.manrope,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _rename(name),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _remove(name),
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
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _add,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '新增${widget.isTag ? '标签' : '分类'}',
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}
