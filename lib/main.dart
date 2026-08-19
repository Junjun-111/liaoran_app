import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'pages/add_flow_page.dart';
import 'pages/first_run_dialog.dart';
import 'pages/home_page.dart';
import 'pages/lock_screen.dart';
import 'pages/my_assets_page.dart';
import 'pages/profile_page.dart';
import 'pages/subscription_page.dart';
import 'pages/welcome_page.dart';
import 'pages/wishlist_page.dart';
import 'services/lock_gate.dart';
import 'services/nutstore_service.dart';
import 'state/asset_store.dart';
import 'state/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // 初始化绑定，确保 SystemChrome 调用在 runApp 前生效
  WidgetsFlutterBinding.ensureInitialized();
  // 先恢复手机本地保存的资产，再启动界面
  await AssetStore.instance.load();
  // 读取坚果云同步配置
  await NutstoreService.load();
  // 读取应用锁状态；已启用指纹锁的，冷启动也要先验证指纹
  await LockGate.load();
  if (LockGate.enabled && !SettingsStore.instance.lockEnabled) {
    SettingsStore.instance.enableLock('');
  }
  // 沉浸式状态栏：edgeToEdge 模式，内容绘制到状态栏 / 导航栏后面（系统栏全透明）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const LiaoranApp());
}

class LiaoranApp extends StatelessWidget {
  const LiaoranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '了然',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _RootShell(),
    );
  }
}

/// 根布局壳：用 IndexedStack 保持 5 个页面常驻，底部导航切换不重建。
class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _gating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialGate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 首次启动：弹「启用指纹保护」→ 真实指纹认证 → 纸屑动画欢迎页。
  /// 已启用指纹锁：冷启动直接验证指纹进入首页（无欢迎页）。
  Future<void> _openInitialGate() async {
    if (!mounted) return;

    if (!LockGate.firstRunDone) {
      // 必须通过真实指纹认证才能继续；任何方式关掉弹窗都会重新弹出
      var enabled = false;
      while (!enabled && mounted) {
        enabled = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const FirstRunDialog(),
            ) ??
            false;
      }
      await LockGate.setFirstRunDone(true);
      if (mounted) {
        SettingsStore.instance.enableLock('');
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
      return;
    }

    if (LockGate.enabled) {
      await _requireUnlock();
    }
  }

  /// 全屏指纹验证；通过后返回首页，不显示任何欢迎页。
  Future<void> _requireUnlock() async {
    if (_gating || LockGate.lockScreenShowing || !mounted) return;
    _gating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    } finally {
      _gating = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 退到后台记录时间；回到前台时若超过 30 分钟则先验证指纹
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      LockGate.markBackground();
    } else if (state == AppLifecycleState.resumed) {
      if (LockGate.enabled && LockGate.backgroundedLong) {
        LockGate.clearBackground();
        _requireUnlock();
      }
    }
  }

  void _onNavTap(int i) {
    if (i < 0) {
      // -1 = 添加按钮：打开添加流程页
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddFlowPage(initialTab: 0)),
      );
      return;
    }
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // 标签切换为瞬时切换（与正常 App 一致，不做整页位移动画）
    return IndexedStack(
      index: _index,
      children: [
        HomePage(onNavTap: _onNavTap),
        SubscriptionPage(onNavTap: _onNavTap),
        WishlistPage(onNavTap: _onNavTap),
        MyAssetsPage(onNavTap: _onNavTap),
        ProfilePage(onNavTap: _onNavTap),
      ],
    );
  }
}
