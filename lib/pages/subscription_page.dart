import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/calculators/subscription_status_resolver.dart';
import '../models/subscription.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../theme/app_theme.dart';
import '../widgets/item_icon.dart';
import '../widgets/long_press_delete_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/primary_cta_button.dart';
import 'add_flow_page.dart';

/// 订阅管理页：月度汇总卡 + 状态筛选 + 订阅列表 + 详情/编辑。
///
/// 状态按「到期自动过期」规则实时判定展示；编辑复用添加页表单。
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionStore.instance,
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        return PageScaffold(
          title: '订阅管理',
          subtitle: '记录每一笔订阅 掌握续费节奏',
          currentIndex: 1,
          onNavTap: onNavTap,
          body: store.isEmpty
              ? const _EmptyState()
              : _SubscriptionSection(store: store),
        );
      },
    );
  }
}

/// 空状态（Figma 25_3）
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddFlowPage(initialTab: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 92),
        SvgPicture.asset(
          'assets/CodeBuddyAssets/25_3/7.svg',
          width: 73,
          height: 79,
        ),
        const SizedBox(height: 21),
        const Text('还没有订阅', style: AppTextStyles.emptyTitleLg),
        const SizedBox(height: 12),
        const Text(
          '点击下方按钮开始管理你的数字账单',
          style: AppTextStyles.emptySubtitleLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryCtaButton(
          label: '添加第一笔订阅',
          width: 224,
          height: 52,
          onTap: () => _openAdd(context),
        ),
      ],
    );
  }
}

/// 订阅列表区：汇总卡 + 状态筛选 + 卡片列表
class _SubscriptionSection extends StatefulWidget {
  const _SubscriptionSection({required this.store});

  final SubscriptionStore store;

  @override
  State<_SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<_SubscriptionSection> {
  static const _filters = ['全部', '生效中', '已过期', '已取消', '暂停中'];

  int _filterIndex = 0;

  /// 展示用状态（按到期日自动判定）
  static String _effective(Subscription s) =>
      SubscriptionStatusResolver.resolve(
        storedStatus: s.status,
        expiryDate: s.expiryDate,
      );

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final all = store.items;
    final filter = _filters[_filterIndex];
    final items = filter == '全部'
        ? all
        : all.where((s) => _effective(s) == filter).toList();

    final monthly = store.totalMonthly;
    final activeCount = all.where((s) => _effective(s) == '生效中').length;
    final decimals = SettingsStore.instance.decimalPlaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 月度汇总玻璃卡
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardMint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardStroke, width: 1),
          ),
          child: Row(
            children: [
              _SummaryItem(
                label: '月均合计',
                value: MoneyFormatter.format(monthly, decimals: decimals),
              ),
              const _VLine(),
              _SummaryItem(label: '生效中', value: '$activeCount'),
              const _VLine(),
              _SummaryItem(
                label: '日均开销',
                value: MoneyFormatter.format(
                  monthly / 30,
                  decimals: decimals,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 状态筛选
        Row(
          children: [
            for (final (i, f) in _filters.indexed) ...[
              _FilterChip(
                label: f,
                selected: i == _filterIndex,
                onTap: () => setState(() => _filterIndex = i),
              ),
              if (i < _filters.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '共 ${items.length} 个订阅',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '该状态下暂无订阅',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _SubscriptionCard(
              subscription: items[i],
              effectiveStatus: _effective(items[i]),
              onDelete: () => store.remove(items[i]),
            ),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF61758B),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  const _VLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFE8ECEA));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? null
              : Border.all(color: AppColors.cardStroke, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 订阅卡片：图标 + 名称/平台 + 金额 + 状态，长按删除、点击看详情
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.effectiveStatus,
    required this.onDelete,
  });

  final Subscription subscription;
  final String effectiveStatus;
  final VoidCallback onDelete;

  static const _statusColors = <String, Color>{
    '生效中': Color(0xFF10B981),
    '已过期': Color(0xFF94A3B8),
    '已取消': Color(0xFFF87171),
    '暂停中': Color(0xFFF59E0B),
  };

  static String _shortDate(DateTime d) => '${d.month}月${d.day}日';

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final statusColor = _statusColors[effectiveStatus] ?? const Color(0xFF10B981);
    final dueText = sub.nextChargeDate != null
        ? '下次扣款 ${_shortDate(sub.nextChargeDate!)}'
        : sub.expiryDate != null
            ? '到期 ${_shortDate(sub.expiryDate!)}'
            : '未设置到期';
    final money = MoneyFormatter.format(
      sub.amount,
      decimals: SettingsStore.instance.decimalPlaces,
      currency: sub.currency,
    );

    return RepaintBoundary(
      child: LongPressDeleteCard(
        key: ValueKey(sub.id),
        onTap: () => _showDetail(context),
        onDelete: onDelete,
        title: '删除订阅',
        message: '删除后不可恢复，确认要删除该订阅吗？',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardStroke, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadowPrimary,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ItemIconBadge(
                iconPath: sub.icon,
                fallbackIcon: Icons.calendar_month_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.platform} · ${sub.cycle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          effectiveStatus,
                          style: const TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF61758B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueText,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF61758B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 订阅详情底部面板：信息 + 编辑入口
class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.subscription});

  final Subscription subscription;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  /// 实时从 Store 取最新数据（编辑后保持同步）
  Subscription get _current => SubscriptionStore.instance.items
          .where((s) => s.id == widget.subscription.id)
          .firstOrNull ??
      widget.subscription;

  static String _fullDate(DateTime? d) =>
      d == null ? '—' : '${d.year}年${d.month}月${d.day}日';

  void _edit() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFlowPage(editingSubscription: _current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _current;
    final effective = SubscriptionStatusResolver.resolve(
      storedStatus: sub.status,
      expiryDate: sub.expiryDate,
    );
    final rows = <(String, String)>[
      ('订阅平台', sub.platform),
      ('订阅类型', sub.type),
      ('扣款周期', sub.cycle),
      ('首次订阅', _fullDate(sub.firstDate)),
      ('当前到期', _fullDate(sub.expiryDate)),
      ('下次扣款', _fullDate(sub.nextChargeDate)),
      ('当前状态', effective),
      if (sub.remark.isNotEmpty) ('备注', sub.remark),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Row(
              children: [
                ItemIconBadge(
                  iconPath: sub.icon,
                  fallbackIcon: Icons.calendar_month_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sub.currency} ${MoneyFormatter.format(sub.amount, currency: sub.currency)} / ${sub.cycle}',
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _edit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '编辑',
                      style: TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF61758B),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (sub.attachmentPath != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(sub.attachmentPath!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  cacheWidth:
                      (360 * MediaQuery.of(context).devicePixelRatio).round(),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
