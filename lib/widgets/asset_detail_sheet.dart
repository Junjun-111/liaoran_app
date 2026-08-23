import 'dart:io' show File;

import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/calculators/cost_per_day_calculator.dart';
import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import '../pages/add_flow_page.dart';
import 'app_date_picker.dart';
import 'dialog_controllers.dart';
import 'investment_widgets.dart';
import 'maintenance_widgets.dart';
import 'item_icon.dart';

/// 资产详情底部面板（首页 / 我的资产页共用）。
///
/// 统计（买入价/使用天数/日均成本）、目标日均成本与回本进度、
/// 状态流转（服役中/已退役/已卖出）、卖出记录与盈亏复盘。
class AssetDetailSheet extends StatefulWidget {
  const AssetDetailSheet({super.key, required this.asset});

  final Asset asset;

  @override
  State<AssetDetailSheet> createState() => _AssetDetailSheetState();
}

class _AssetDetailSheetState extends State<AssetDetailSheet> {
  static const _defaultIcon = 'assets/CodeBuddyAssets/42_951/6.svg';

  /// 实时从 Store 取最新数据（状态流转/卖出后保持同步）
  Asset get _current => AssetStore.instance.items.firstWhere(
        (a) => a.id == widget.asset.id,
        orElse: () => widget.asset,
      );

  CostPerDayResult _calc(Asset asset) => const CostPerDayCalculator().calculate(
        purchasePrice: asset.purchasePrice,
        purchaseDate: asset.purchaseDate,
        status: asset.status,
        retiredDate: asset.retiredDate,
        salePrice: asset.latestSale?.salePrice,
        saleDate: asset.latestSale?.saleDate,
        targetCpd: asset.targetCpd,
      );

  void _update(Asset updated) {
    AssetStore.instance.update(updated);
    setState(() {});
  }

  void _edit() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFlowPage(editingAsset: _current),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '删除资产',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text('删除后该资产的全部记录将丢失，确定删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '删除',
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
    if (ok == true && mounted) {
      AssetStore.instance.moveToTrash(_current);
      Navigator.of(context).pop();
    }
  }

  Future<void> _changeStatus(AssetLifecycleStatus status) async {
    if (status == _current.status) return;
    switch (status) {
      case AssetLifecycleStatus.active:
        _update(_current.copyWith(status: AssetLifecycleStatus.active));
        break;
      case AssetLifecycleStatus.retired:
        await _retire();
        break;
      case AssetLifecycleStatus.sold:
        await _recordSale();
        break;
    }
  }

  Future<void> _retire() async {
    final asset = _current;
    final picked = await showAppDatePicker(
      context: context,
      initialDate: asset.retiredDate ?? DateTime.now(),
      firstDate: asset.purchaseDate,
    );
    if (picked == null || !mounted) return;
    _update(
      asset.copyWith(
        status: AssetLifecycleStatus.retired,
        retiredDate: picked,
      ),
    );
  }

  Future<void> _recordSale() async {
    var saleDate = _current.latestSale?.saleDate ?? DateTime.now();
    var priceError = false;

    final result = await showDialog<(double, String, DateTime)>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController(), TextEditingController()],
        builder: (ctx, ctrls) {
          final priceCtrl = ctrls[0];
          final remarkCtrl = ctrls[1];
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              Future<void> pickDate() async {
                final picked = await showAppDatePicker(
                  context: ctx,
                  initialDate: saleDate,
                  firstDate: _current.purchaseDate,
                );
                if (picked != null) setDialogState(() => saleDate = picked);
              }

              return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '记录卖出',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: '卖出价格',
                      errorText: priceError ? '请输入正确的卖出价格' : null,
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
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '卖出日期：${_dateText(saleDate)}',
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkCtrl,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: '备注（可选）',
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
                ],
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
                  final price = double.tryParse(priceCtrl.text.trim());
                  if (price == null || price < 0) {
                    setDialogState(() => priceError = true);
                    return;
                  }
                  Navigator.of(ctx).pop(
                    (price, remarkCtrl.text.trim(), saleDate),
                  );
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
          );
            },
          );
        },
      ),
    );

    if (result == null || !mounted) return;
    final (price, remark, date) = result;

    final asset = _current;
    final record = SaleRecord(
      salePrice: price,
      saleDate: date,
      remark: remark,
      createdAt: DateTime.now(),
    );
    _update(
      asset.copyWith(
        status: AssetLifecycleStatus.sold,
        saleRecords: [...asset.saleRecords, record],
      ),
    );
  }

  Future<void> _editTarget() async {
    var error = false;

    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [
          TextEditingController(
            text: _current.targetCpd?.toStringAsFixed(2) ?? '',
          ),
        ],
        builder: (ctx, ctrls) {
          final ctrl = ctrls[0];
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '设置目标日均成本',
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: '目标（元/天）',
                hintText: '如：8.8',
                errorText: error ? '请输入大于 0 的数字' : null,
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
                onPressed: () => Navigator.of(ctx).pop('clear'),
                child: const Text(
                  '清除',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    color: Color(0xFFE5484D),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
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
          );
            },
          );
        },
      ),
    );

    if (result == null || !mounted) return;
    if (result == 'clear') {
      _update(_current.copyWith(targetCpd: null));
    } else {
      _update(_current.copyWith(targetCpd: result as double));
    }
  }

  static String _dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final asset = _current;
    final calc = _calc(asset);
    final decimals = SettingsStore.instance.decimalPlaces;
    final currency = asset.currency;

    final priceText = MoneyFormatter.format(
      asset.purchasePrice,
      decimals: decimals,
      currency: currency,
    );
    final cpdText = calc.costPerDay == null
        ? '—'
        : '${MoneyFormatter.format(calc.costPerDay!, decimals: decimals, currency: currency)}/天';
    final targetText = asset.targetCpd == null
        ? '未设置'
        : '${MoneyFormatter.format(asset.targetCpd!, decimals: decimals, currency: currency)}/天';

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
                    iconPath: asset.icon,
                    fallbackSvg: _defaultIcon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${asset.category} · ${asset.status.label}',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _delete,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Color(0xFFE5484D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    if (asset.investments.isNotEmpty) ...[
                      _StatItem(
                        label: '累计价值',
                        value: MoneyFormatter.format(
                          asset.purchasePrice + asset.cumulativeInvestment,
                          decimals: decimals,
                          currency: currency,
                        ),
                      ),
                      const _VLine(),
                    ],
                    _StatItem(label: '买入价', value: priceText),
                    const _VLine(),
                    _StatItem(label: '使用天数', value: '${calc.daysUsed} 天'),
                    const _VLine(),
                    _StatItem(label: '日均成本', value: cpdText),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InvestmentCard(
                investments: asset.investments,
                currency: currency,
                decimals: decimals,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvestmentRecordsPage(
                      initial: asset.investments,
                      currency: currency,
                      decimals: decimals,
                      editable: true,
                      onChanged: (records) {
                        _update(_current.copyWith(investments: records));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MaintenanceCard(
                records: asset.maintenanceRecords,
                currency: currency,
                decimals: decimals,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MaintenanceRecordsPage(
                      initial: asset.maintenanceRecords,
                      currency: currency,
                      decimals: decimals,
                      editable: true,
                      onChanged: (records) {
                        _update(
                          _current.copyWith(maintenanceRecords: records),
                        );
                      },
                    ),
                  ),
                ),
                onAdd: () async {
                  final record = await showDialog<MaintenanceRecord>(
                    context: context,
                    builder: (_) => const MaintenanceDialog(),
                  );
                  if (record != null) {
                    _update(
                      _current.copyWith(
                        maintenanceRecords: [
                          ..._current.maintenanceRecords,
                          record,
                        ],
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    '目标日均成本',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    targetText,
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF61758B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _editTarget,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (asset.targetCpd != null && calc.paybackProgress != null) ...[
                _PaybackBar(progress: calc.paybackProgress!),
                const SizedBox(height: 8),
                Text(
                  calc.isPaidBack!
                      ? '已回本'
                      : '距回本还需 ${calc.daysToPayback} 天',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: calc.isPaidBack!
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ] else ...[
                const Text(
                  '设置目标日均成本后，自动判断是否回本',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
              if (asset.careExpiryDate != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Care 到期时间',
                      style: TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _dateText(asset.careExpiryDate!),
                      style: const TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF61758B),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '资产状态',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final s in AssetLifecycleStatus.values) ...[
                    _StatusChip(
                      label: s.label,
                      selected: asset.status == s,
                      onTap: () => _changeStatus(s),
                    ),
                    if (s != AssetLifecycleStatus.values.last)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
              if (asset.saleRecords.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '卖出记录',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final r in asset.saleRecords.reversed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${MoneyFormatter.format(r.salePrice, decimals: decimals, currency: currency)} · ${_dateText(r.saleDate)}',
                            style: const TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (r.remark.isNotEmpty)
                          Flexible(
                            child: Text(
                              r.remark,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (calc.profitLoss != null) ...[
                  Row(
                    children: [
                      const Text(
                        '卖出盈亏',
                        style: TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF61758B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        MoneyFormatter.signed(
                          calc.profitLoss!,
                          decimals: decimals,
                          currency: currency,
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: calc.profitLoss! >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5484D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        '保值率',
                        style: TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF61758B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(calc.retentionRate! * 100).round()}%',
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (asset.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '标签：',
                      style: TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    for (final tag in asset.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE3E8E6)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (asset.remark.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '备注：${asset.remark}',
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
              if (asset.attachmentPath != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(asset.attachmentPath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    cacheWidth: (360 *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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

class _PaybackBar extends StatelessWidget {
  const _PaybackBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 10,
        color: AppColors.emptyIconBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: p,
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? null
              : Border.all(color: const Color(0xFFE3E8E6), width: 1),
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
