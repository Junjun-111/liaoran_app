import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../theme/app_theme.dart';

/// 更新日志卡片：版本号标题 + 黑体标题式更新内容。
class ChangelogCard extends StatelessWidget {
  const ChangelogCard({super.key});

  static const _lines = <(String, String)>[
    (
      '1. 首页搜索与排序：',
      '资产列表新增搜索与排序入口，支持按名称/分类/标签/备注实时搜索，'
          '并可按添加时间、购买时间、日均成本、服役时长、物品价值排序。',
    ),
    (
      '2. 年度/月度报告：',
      '「我的资产」新增报告入口，汇总本期资产变化、订阅支出与心愿进度，'
          '支持一键生成图片分享。',
    ),
    (
      '3. 每周自动备份：',
      '坚果云同步新增自动备份开关，每周日自动将全部数据上传云端，无需手动操作。',
    ),
    (
      '4. 回收站：',
      '删除的资产进入回收站，30 天内可随时恢复，防止误删。',
    ),
    (
      '5. 心愿一键转资产：',
      '心愿攒满 100% 后可直接转为资产，攒钱目标无缝衔接资产管理。',
    ),
    (
      '6. 维修/保养记录：',
      '资产详情新增维修与保养记录，花费自动计入累计投入。',
    ),
    (
      '7. 到期提醒：',
      '订阅与 Care 支持自定义提前天数与时间提醒，防止忘记处理自动续费。',
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
