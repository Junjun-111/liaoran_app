import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../theme/app_theme.dart';
import '../widgets/changelog_card.dart';

/// 关于了然：浅色背景 + 96×96 图标 + 版本号 + 更新日志。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 顶部：返回 + 标题 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 9, 22, 13),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Color(0xFF444444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    '关于',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // ── 应用图标（96×96 图片）──
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 0.9375,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icons/app_icon_96.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ── 版本号 ──
            Center(
              child: Text(
                kAppVersion,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0BB981),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // ── 更新日志 ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '更新日志',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  ChangelogCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
