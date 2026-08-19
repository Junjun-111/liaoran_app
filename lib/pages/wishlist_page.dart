import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/models/wishlist_item.dart';
import '../state/settings_store.dart';
import '../state/wishlist_store.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/dialog_controllers.dart';
import '../widgets/item_icon.dart';
import 'add_flow_page.dart';

/// 心愿清单页：心愿列表 + 攒钱进度 + 详情（攒一笔 / 完成）。
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistStore.instance,
      builder: (context, _) {
        final store = WishlistStore.instance;
        return PageScaffold(
          title: '心愿清单',
          subtitle: '攒钱 未来更好的相遇',
          currentIndex: 2,
          onNavTap: onNavTap,
          body: store.isEmpty
              ? const _EmptyState()
              : _WishSection(store: store),
        );
      },
    );
  }
}

/// 空状态（Figma 26_131）
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddFlowPage(initialTab: 2)),
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
          'assets/CodeBuddyAssets/26_131/7.svg',
          width: 72,
          height: 79,
        ),
        const SizedBox(height: 21),
        const Text('清单空空', style: AppTextStyles.emptyTitleLg),
        const SizedBox(height: 12),
        const Text(
          '添加一个奋斗目标 开始攒钱计划',
          style: AppTextStyles.emptySubtitleLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryCtaButton(
          label: '添加第一个心愿',
          width: 224,
          height: 52,
          onTap: () => _openAdd(context),
        ),
      ],
    );
  }
}

/// 心愿列表区
class _WishSection extends StatelessWidget {
  const _WishSection({required this.store});

  final WishlistStore store;

  @override
  Widget build(BuildContext context) {
    final items = store.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '共 ${items.length} 个心愿',
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          _WishCard(
            item: items[i],
            onDelete: () => store.remove(items[i]),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// 心愿卡片：图标 + 名称/分类 + 目标金额 + 进度条
class _WishCard extends StatelessWidget {
  const _WishCard({required this.item, required this.onDelete});

  final WishlistItem item;
  final VoidCallback onDelete;

  static const _defaultIcon = 'assets/CodeBuddyAssets/43_1372/5.svg';

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WishDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
    final targetText = MoneyFormatter.format(item.targetAmount, decimals: decimals);
    final percent = (item.progress * 100).round();

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE5484D),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showDetail(context),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ItemIconBadge(
                    iconPath: item.icon,
                    fallbackSvg: _defaultIcon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
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
                          '${item.category} · ${item.completed ? '已完成' : '进行中'}',
                          style: const TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        targetText,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percent%',
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
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  color: AppColors.emptyIconBg,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: item.progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
                        ),
                      ),
                    ),
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

/// 心愿详情底部面板：目标/已攒/进度 + 攒一笔 + 完成
class _WishDetailSheet extends StatefulWidget {
  const _WishDetailSheet({required this.item});

  final WishlistItem item;

  @override
  State<_WishDetailSheet> createState() => _WishDetailSheetState();
}

class _WishDetailSheetState extends State<_WishDetailSheet> {
  WishlistItem get _current => WishlistStore.instance.items
          .where((w) => w.id == widget.item.id)
          .firstOrNull ??
      widget.item;

  void _update(WishlistItem updated) {
    WishlistStore.instance.update(updated);
    setState(() {});
  }

  void _recordDeposit(double amount) {
    final item = _current;
    _update(
      item.copyWith(
        savedAmount: item.savedAmount + amount,
        transactions: [
          ...item.transactions,
          WishTransaction(
            id: 't${DateTime.now().microsecondsSinceEpoch}',
            type: WishTransactionType.deposit,
            amount: amount,
            date: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void _recordWithdraw(double amount) {
    final item = _current;
    _update(
      item.copyWith(
        savedAmount:
            (item.savedAmount - amount).clamp(0.0, double.infinity).toDouble(),
        transactions: [
          ...item.transactions,
          WishTransaction(
            id: 't${DateTime.now().microsecondsSinceEpoch}',
            type: WishTransactionType.withdraw,
            amount: amount,
            date: DateTime.now(),
          ),
        ],
      ),
    );
  }

  Future<void> _deposit() async {
    var error = false;
    final value = await showDialog<double>(
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
            '攒一笔',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: '本次攒入金额',
              errorText: error ? '请输入大于 0 的金额' : null,
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
                  color: Color(0xFF3DC88A),
                  width: 1.5,
                ),
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
              onPressed: () {
                final value = double.tryParse(ctrl.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(() => error = true);
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
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
          ),
          );
        },
      ),
    );

    if (value == null || !mounted) return;

    _recordDeposit(value);
  }

  Future<void> _withdraw() async {
    var errorText = '';
    final value = await showDialog<double>(
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
                '取出',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: '本次取出金额',
                  errorText: errorText.isEmpty ? null : errorText,
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
                      color: Color(0xFF3DC88A),
                      width: 1.5,
                    ),
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
                  onPressed: () {
                    final amount = double.tryParse(ctrl.text.trim());
                    if (amount == null || amount <= 0) {
                      setDialogState(() => errorText = '请输入大于 0 的金额');
                      return;
                    }
                    if (amount > _current.savedAmount) {
                      setDialogState(
                        () => errorText = '取出金额不能超过已攒金额',
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(amount);
                  },
                  child: const Text(
                    '取出',
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

    if (value == null || !mounted) return;
    _recordWithdraw(value);
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WishHistorySheet(item: _current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _current;
    final decimals = SettingsStore.instance.decimalPlaces;
    final percent = (item.progress * 100).round();

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
            Row(
              children: [
                GestureDetector(
                  onTap: _showHistory,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE3E8E6)),
                    ),
                    child: const Icon(
                      Icons.table_chart_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E8E6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.category} · ${item.completed ? '已完成' : '进行中'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _StatItem(
                    label: '目标金额',
                    value: MoneyFormatter.format(
                      item.targetAmount,
                      decimals: decimals,
                    ),
                  ),
                  const _VLine(),
                  _StatItem(
                    label: '已攒',
                    value: MoneyFormatter.format(
                      item.savedAmount,
                      decimals: decimals,
                    ),
                  ),
                  const _VLine(),
                  _StatItem(label: '进度', value: '$percent%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 10,
                color: AppColors.emptyIconBg,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: item.progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!item.completed)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in const [50, 200, 600, 1000])
                    _QuickSaveChip(
                      label: '$amount',
                      onTap: () => _recordDeposit(amount.toDouble()),
                    ),
                  _QuickSaveChip(label: '自定义', onTap: _deposit),
                ],
              ),
            if (!item.completed) const SizedBox(height: 16),
            if (!item.completed) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _deposit,
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '攒一笔',
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _withdraw,
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3E8E6)),
                        ),
                        child: const Text(
                          '取出',
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5484D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _update(_current.copyWith(completed: true)),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3E8E6)),
                  ),
                  child: const Text(
                    '完成心愿',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => _update(_current.copyWith(completed: false)),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3E8E6)),
                  ),
                  child: const Text(
                    '重新开启',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickSaveChip extends StatelessWidget {
  const _QuickSaveChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _WishHistorySheet extends StatelessWidget {
  const _WishHistorySheet({required this.item});

  final WishlistItem item;

  static String _dateText(DateTime d) => '${d.month}月${d.day}日';

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsStore.instance.decimalPlaces;
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
            const Text(
              '流水记录',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '添加日期：${_dateText(item.addDate)}',
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: _HistoryHeader(label: '日期'),
                ),
                Expanded(
                  child: _HistoryHeader(label: '存入'),
                ),
                Expanded(
                  child: _HistoryHeader(label: '取出'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '暂无流水记录',
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
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: item.transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final tx = item.transactions[index];
                    final amount = MoneyFormatter.format(
                      tx.amount,
                      decimals: decimals,
                    );
                    final isDeposit =
                        tx.type == WishTransactionType.deposit;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _dateText(tx.date),
                              style: const TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              isDeposit ? amount : '',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              isDeposit ? '' : '-$amount',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 12,
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
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppFonts.manrope,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

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
                fontSize: 14,
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
