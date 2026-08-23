import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/models/asset.dart';
import '../theme/app_theme.dart';
import 'app_date_picker.dart';
import 'background_blobs.dart';

/// 累计投入卡片（折叠态）：只展示总额 + 展开箭头 + 笔数，
/// 明细统一收纳进 [InvestmentRecordsPage]，不再逐条平铺。
class InvestmentCard extends StatelessWidget {
  const InvestmentCard({
    super.key,
    required this.investments,
    required this.currency,
    this.decimals = 2,
    this.onOpen,
    this.onAdd,
  });

  final List<InvestmentRecord> investments;
  final String currency;
  final int decimals;

  /// 点击总额 / 笔数时打开记录页
  final VoidCallback? onOpen;

  /// 传入时显示“添加投入记录”入口
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final total = investments.fold<double>(0, (s, r) => s + r.amount);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Row(
              children: [
                const Text(
                  '累计投入',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF61758B),
                  ),
                ),
                const Spacer(),
                Text(
                  MoneyFormatter.format(
                    total,
                    currency: currency,
                    decimals: decimals,
                  ),
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          if (investments.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '共 ${investments.length} 笔记录',
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
          if (onAdd != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Color(0xFF3DC88A),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '添加投入记录',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3DC88A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 投入记录明细页：列出每一条投入，支持点击重新编辑、删除（可编辑模式）。
class InvestmentRecordsPage extends StatefulWidget {
  const InvestmentRecordsPage({
    super.key,
    required this.initial,
    required this.currency,
    this.decimals = 2,
    this.editable = false,
    this.onChanged,
  });

  final List<InvestmentRecord> initial;
  final String currency;
  final int decimals;

  /// 是否允许增删改（编辑资产表单传 true；详情查看传 false）
  final bool editable;

  /// 列表变化后回传（用于编辑资产表单同步状态）
  final ValueChanged<List<InvestmentRecord>>? onChanged;

  @override
  State<InvestmentRecordsPage> createState() => _InvestmentRecordsPageState();
}

class _InvestmentRecordsPageState extends State<InvestmentRecordsPage> {
  late List<InvestmentRecord> _records = [...widget.initial];

  void _commit(List<InvestmentRecord> records) {
    widget.onChanged?.call(records);
  }

  Future<void> _add() async {
    final record = await showDialog<InvestmentRecord>(
      context: context,
      builder: (_) => const InvestmentDialog(),
    );
    if (record == null || !mounted) return;
    final records = [..._records, record];
    setState(() => _records = records);
    _commit(records);
  }

  Future<void> _edit(int index) async {
    final updated = await showDialog<InvestmentRecord>(
      context: context,
      builder: (_) => InvestmentDialog(initial: _records[index]),
    );
    if (updated == null || !mounted) return;
    final records = [..._records]..[index] = updated;
    setState(() => _records = records);
    _commit(records);
  }

  void _remove(int index) {
    final records = [..._records]..removeAt(index);
    setState(() => _records = records);
    _commit(records);
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final display = _records.reversed.toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        // 与首页一致的不透明白底：透明底会露出系统默认的黑色背景
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(child: BackgroundBlobs()),
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: display.isEmpty ? _empty() : _list(display),
                  ),
                  if (widget.editable) _bottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 9, 22, 13),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(width: 11),
          const Text(
            '投入记录',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 24.6,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            '共 ${_records.length} 笔',
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<InvestmentRecord> display) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: display.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final record = display[i];
        final index = _records.indexOf(record);
        return _recordCard(record, index, serial: i + 1);
      },
    );
  }

  Widget _recordCard(InvestmentRecord record, int index,
      {required int serial}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.editable ? () => _edit(index) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xD1FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x80FFFFFF)),
        ),
        child: Row(
          children: [
            // 序号
            SizedBox(
              width: 26,
              child: Text(
                '$serial',
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.remark.isNotEmpty)
                    Text(
                      record.remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.manrope,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _date(record.date),
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              MoneyFormatter.format(
                record.amount,
                currency: widget.currency,
                decimals: widget.decimals,
              ),
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (widget.editable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _remove(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Color(0xFF9AA0A6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_outlined, size: 56, color: Color(0xFFB9C6D2)),
          const SizedBox(height: 16),
          const Text(
            '暂无投入记录',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.editable ? '点击下方按钮添加第一笔投入' : '该资产暂无后续投入',
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: GestureDetector(
          onTap: _add,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5DDBA0), Color(0xFF2BAF74)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2BAF74).withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '添加投入记录',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 添加 / 编辑投入记录弹窗。传入 [initial] 时进入编辑模式：回填金额、
/// 日期、备注，并保留原创建时间。
class InvestmentDialog extends StatefulWidget {
  const InvestmentDialog({super.key, this.initial});

  final InvestmentRecord? initial;

  @override
  State<InvestmentDialog> createState() => _InvestmentDialogState();
}

class _InvestmentDialogState extends State<InvestmentDialog> {
  late final _amountCtrl = TextEditingController(
    text: widget.initial?.amount.toStringAsFixed(2) ?? '',
  );
  late final _remarkCtrl = TextEditingController(
    text: widget.initial?.remark ?? '',
  );
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = '请输入大于 0 的金额');
      return;
    }
    Navigator.of(context).pop(
      InvestmentRecord(
        amount: amount,
        date: _date,
        remark: _remarkCtrl.text.trim(),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? '编辑投入记录' : '添加投入记录',
        style: const TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: '投入金额',
              errorText: _error,
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
          GestureDetector(
            onTap: () async {
              final picked = await showAppDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Color(0xFF61758B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '投入日期：${_date.year}年${_date.month}月${_date.day}日',
                    style: const TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkCtrl,
            // 显式指定文本键盘，避免中文输入法组合被前一个数字键盘状态干扰
            keyboardType: TextInputType.text,
            // 注意：不能设置 autocorrect / enableSuggestions 为 false，
            // 否则 Android 会弹出“安全键盘”，只能输入字母数字、无法输入中文
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: '备注',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              color: AppColors.textHint,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
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
  }
}
