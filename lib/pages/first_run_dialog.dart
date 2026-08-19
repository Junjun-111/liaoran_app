import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/app_theme.dart';

/// 首次启动弹窗：点击「启用指纹保护」必须通过系统真实指纹认证。
class FirstRunDialog extends StatefulWidget {
  const FirstRunDialog({super.key});

  @override
  State<FirstRunDialog> createState() => _FirstRunDialogState();
}

class _FirstRunDialogState extends State<FirstRunDialog> {
  final _auth = LocalAuthentication();
  bool _checking = false;
  String? _error;

  Future<void> _enable() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) {
        if (mounted) {
          setState(() {
            _checking = false;
            _error = '设备不支持指纹/面容识别，无法启用';
          });
        }
        return;
      }
      // 必须经过系统真实认证：指纹/面容验证失败不会放行
      final ok = await _auth.authenticate(
        localizedReason: '请验证指纹以开启应用保护',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _checking = false;
          _error = '验证失败，请重试';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = '无法启动系统识别，请重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 屏蔽系统返回键：不通过真实指纹认证就不能进入应用
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 指纹图标：白色圆角方块 + 绿色指纹
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 52,
                  color: _checking ? AppColors.primary : const Color(0xFF34C98B),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '欢迎使用了然',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '点击按钮启用指纹保护，\n安全守护您的每一笔资产',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  color: Color(0xFFE5484D),
                ),
              ),
            ],
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _checking ? null : _enable,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: _checking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '启用指纹保护',
                            style: TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
  }
}
