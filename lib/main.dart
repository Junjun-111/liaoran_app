import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'pages/add_flow_page.dart';
import 'pages/home_page.dart';
import 'pages/my_assets_page.dart';
import 'pages/profile_page.dart';
import 'pages/subscription_page.dart';
import 'pages/wishlist_page.dart';
import 'services/nutstore_service.dart';
import 'state/asset_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // 初始化绑定，确保 SystemChrome 调用在 runApp 前生效
  WidgetsFlutterBinding.ensureInitialized();
  // 先恢复手机本地保存的资产，再启动界面
  await AssetStore.instance.load();
  // 读取坚果云同步配置
  await NutstoreService.load();
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

class _RootShellState extends State<_RootShell> {
  int _index = 0;

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
