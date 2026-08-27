import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../theme/app_theme.dart';

/// 更新日志卡片：版本号标题 + 黑体标题式更新内容。
class ChangelogCard extends StatelessWidget {
  const ChangelogCard({super.key});

  static const _lines = <(String, String)>[
    (
      '1. 累值计价：',
      '编辑资产时新增「累值计价」开关，位于编辑页面。开启后日均成本按累计价值计算（买入价 + 累计投入 + 维修保养），'
          '反映每天实际花费；关闭则按买入价计算。',
    ),
  ];

  TextSpan _build() {
    final children = <TextSpan>[];
    for (var i = 0; i < _lines.length; i++) {
      if (i > 0) children.add(const TextSpan(text: '\n'));
      children.add(
        TextSpan(
          children: [
            TextSpan(
              text: _lines[i].$1,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            TextSpan(text: _lines[i].$2),
          ],
        ),
      );
    }
    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kAppVersion,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            _build(),
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
