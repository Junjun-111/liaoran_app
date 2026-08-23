import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../services/update_notice.dart';
import '../theme/app_theme.dart';
import '../widgets/changelog_card.dart';

/// 更新后首次打开展示的「本次更新内容」页。
class UpdateNoticePage extends StatelessWidget {
  const UpdateNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                '更新内容',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$kAppVersion 有什么新变化？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 28),
              const ChangelogCard(),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  UpdateNotice.markSeen();
                  Navigator.of(context).maybePop();
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF10B981), Color(0xFF0B8F66)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    '知道了，开始使用',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
