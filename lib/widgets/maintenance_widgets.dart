import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters/money_formatter.dart';
import '../domain/models/asset.dart';
import '../theme/app_theme.dart';
import 'app_date_picker.dart';
import 'background_blobs.dart';

/// 维修 / 保养卡片（折叠态）：总花费 + 记录数 + 添加入口。
class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.records,
    required this.currency,
    this.decimals = 2,
    this.onOpen,
    this.onAdd,
  });

  final List<MaintenanceRecord> records;
  final String currency;
  final int decimals;
  final VoidCallback? onOpen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(0, (s, r) => s + r.cost);
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
                const Icon(
                  Icons.build_outlined,
                  size: 16,
                  color: Color(0xFF61758B),
                ),
                const SizedBox(width: 6),
                const Text(
                  '维修 / 保养',
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
          if (records.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '共 ${records.length} 条记录 · 已计入累计投入',
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
                    '添加维修 / 保养记录',
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

/// 维修 / 保养记录明细页：列出每条记录，支持添加、编辑、删除。
class MaintenanceRecordsPage extends StatefulWidget {
  const MaintenanceRecordsPage({
    super.key,
    required this.initial,
    required this.currency,
    this.decimals = 2,
    this.editable = false,
    this.onChanged,
  });

  final List<MaintenanceRecord> initial;
  final String currency;
  final int decimals;
  final bool editable;
  final ValueChanged<List<MaintenanceRecord>>? onChanged;

  @override
  State<MaintenanceRecordsPage> createState() =>
      _MaintenanceRecordsPageState();
}

class _MaintenanceRecordsPageState extends State<MaintenanceRecordsPage> {
  late List<MaintenanceRecord> _records = [...widget.initial];

  void _commit(List<MaintenanceRecord> records) {
    widget.onChanged?.call(records);
  }

  Future<void> _add() async {
    final record = await showDialog<MaintenanceRecord>(
      context: context,
      builder: (_) => const MaintenanceDialog(),
    );
    if (record == null || !mounted) return;
    final records = [..._records, record];
    setState(() => _records = records);
    _commit(records);
  }

  Future<void> _edit(int index) async {
    final updated = await showDialog<MaintenanceRecord>(
      context: context,
      builder: (_) => MaintenanceDialog(initial: _records[index]),
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
            '维修 / 保养记录',
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
            '共 ${_records.length} 条',
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

  Widget _list(List<MaintenanceRecord> display) {
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

  Widget _recordCard(MaintenanceRecord record, int index,
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
                  if (record.description.isNotEmpty)
                    Text(
                      record.description,
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
                record.cost,
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
          const Icon(
            Icons.build_outlined,
            size: 56,
            color: Color(0xFFB9C6D2),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无维修 / 保养记录',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.editable ? '点击下方按钮添加第一条记录' : '该资产暂无维修 / 保养记录',
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
                  '添加维修 / 保养记录',
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

/// 添加 / 编辑维修保养记录弹窗。
class MaintenanceDialog extends StatefulWidget {
  const MaintenanceDialog({super.key, this.initial});

  final MaintenanceRecord? initial;

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  late final _costCtrl = TextEditingController(
    text: widget.initial?.cost.toStringAsFixed(2) ?? '',
  );
  late final _descCtrl = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  final FocusNode _descFocus = FocusNode();
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  String? _error;

  @override
  void dispose() {
    _costCtrl.dispose();
    _descCtrl.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 弹窗打开后自动聚焦说明框，让键盘直接以文本键盘弹出，
    // 避免从金额数字键盘切换到文本键盘时输入法异常导致无法输入中文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _descFocus.requestFocus();
    });
  }

  void _submit() {
    final cost = double.tryParse(_costCtrl.text.trim());
    if (cost == null || cost < 0) {
      setState(() => _error = '请输入大于等于 0 的金额');
      return;
    }
    Navigator.of(context).pop(
      MaintenanceRecord(
        cost: cost,
        date: _date,
        description: _descCtrl.text.trim(),
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
        isEdit ? '编辑维修 / 保养' : '添加维修 / 保养',
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
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: '花费金额',
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
                    '日期：${_date.year}年${_date.month}月${_date.day}日',
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
            controller: _descCtrl,
            focusNode: _descFocus,
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
              labelText: '说明（如：换电池、常规保养）',
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
