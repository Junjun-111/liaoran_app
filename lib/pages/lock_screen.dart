import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/lock_gate.dart';
import '../theme/app_theme.dart';

/// 锁定页：使用系统生物识别（指纹/面容）解锁。
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    LockGate.lockScreenShowing = true;
    _authenticate();
  }

  @override
  void dispose() {
    LockGate.lockScreenShowing = false;
    super.dispose();
  }

  Future<void> _authenticate() async {
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
            _error = '设备不支持指纹/面容识别';
          });
        }
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: '请验证指纹以解锁应用',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
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

  void _retry() {
    if (_checking) return;
    _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    // 禁止系统返回键退出锁定页：只有验证指纹成功才能进入应用
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: _checking
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 18),
                const Text(
                  '已锁定',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.brandTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  '使用手机系统指纹/面容解锁应用',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.tagline,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      color: Color(0xFFE5484D),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _retry,
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
                        : const Text(
                            '使用指纹解锁',
                            style: AppTextStyles.emptyCta,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
