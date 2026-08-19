import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 全局统一的日期选择器（自绘，贴合 App 玻璃拟态风格）。
///
/// - 白色大圆角卡片 + 柔和阴影，与 App 卡片语言一致
/// - 选中日 = 薄荷绿渐变圆 + 白字；今天 = 绿描边
/// - 中文星期（周一~周日）、中文按钮（取消/确定）
/// - 点击年月可切换到年份选择模式，快速跨年
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _AppDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

class _AppDatePickerDialog extends StatefulWidget {
  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _shortWeek = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  late DateTime _selected = _clamp(_dateOnly(widget.initialDate));
  late DateTime _view = DateTime(_selected.year, _selected.month);
  bool _yearMode = false;

  DateTime _clamp(DateTime d) {
    final first = _dateOnly(widget.firstDate);
    final last = _dateOnly(widget.lastDate);
    if (d.isBefore(first)) return first;
    if (d.isAfter(last)) return last;
    return d;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isEnabled(DateTime d) {
    final day = _dateOnly(d);
    return !day.isBefore(_dateOnly(widget.firstDate)) &&
        !day.isAfter(_dateOnly(widget.lastDate));
  }

  int get _daysInViewMonth => DateTime(_view.year, _view.month + 1, 0).day;

  /// 每月 1 号前需要空出的格子数（周一起始）
  int get _leadingBlanks => DateTime(_view.year, _view.month, 1).weekday - 1;

  void _goMonth(int delta) {
    setState(() {
      var y = _view.year;
      var m = _view.month + delta;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _view = DateTime(y, m);
    });
  }

  void _goYearRange(int delta) {
    setState(() {
      final base = (_view.year ~/ 12) * 12;
      final target = base + delta * 12;
      final minYear = widget.firstDate.year;
      final maxYear = widget.lastDate.year;
      final year = target < minYear ? minYear : (target > maxYear ? maxYear : target);
      _view = DateTime(year, _view.month);
    });
  }

  void _pickYear(int year) {
    setState(() {
      _view = DateTime(year, _view.month);
      _yearMode = false;
    });
  }

  String get _bigDateText {
    final d = _selected;
    return '${d.month}月${d.day}日 ${_shortWeek[d.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadowBlack,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题 + 选中日期
              const Text(
                '选择日期',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bigDateText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 14),
              // 年月切换行
              Row(
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left,
                    onTap: () =>
                        _yearMode ? _goYearRange(-1) : _goMonth(-1),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _yearMode = !_yearMode),
                      child: Text(
                        _yearMode
                            ? '${(_view.year ~/ 12) * 12} - ${(_view.year ~/ 12) * 12 + 11}年'
                            : '${_view.year}年${_view.month}月',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                  _NavArrow(
                    icon: Icons.chevron_right,
                    onTap: () =>
                        _yearMode ? _goYearRange(1) : _goMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!_yearMode) ...[
                // 星期表头
                Row(
                  children: [
                    for (final w in _weekdays)
                      Expanded(
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildDayGrid(),
              ] else
                _buildYearGrid(),
              const SizedBox(height: 14),
              // 底部按钮
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: '取消',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: '确定',
                      primary: true,
                      onTap: () => Navigator.of(context).pop(_selected),
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

  Widget _buildDayGrid() {
    final today = _dateOnly(DateTime.now());
    final cells = <Widget>[];
    final total = _leadingBlanks + _daysInViewMonth;
    final rows = (total / 7).ceil();

    for (var i = 0; i < rows * 7; i++) {
      final dayNumber = i - _leadingBlanks + 1;
      if (dayNumber < 1 || dayNumber > _daysInViewMonth) {
        cells.add(const SizedBox.shrink());
      } else {
        final date = DateTime(_view.year, _view.month, dayNumber);
        final enabled = _isEnabled(date);
        final selected = _dateOnly(date) == _dateOnly(_selected);
        final isToday = date == today;
        cells.add(
          _DayCell(
            day: dayNumber,
            enabled: enabled,
            selected: selected,
            isToday: isToday,
            onTap: enabled
                ? () => setState(() {
                      _selected = date;
                      _view = DateTime(_view.year, _view.month);
                    })
                : null,
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++) Expanded(child: cells[r * 7 + c]),
            ],
          ),
      ],
    );
  }

  Widget _buildYearGrid() {
    final base = (_view.year ~/ 12) * 12;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 3; r++)
          Row(
            children: [
              for (var c = 0; c < 4; c++)
                Expanded(
                  child: _YearCell(
                    year: base + r * 4 + c,
                    selected: base + r * 4 + c == _view.year,
                    onTap: () => _pickYear(base + r * 4 + c),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 左/右切换箭头
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}

/// 单个日期格
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.enabled,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool enabled;
  final bool selected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? const Color(0xFFD0D0D0)
        : selected
            ? Colors.white
            : const Color(0xFF1A1A1A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4DD49A), Color(0xFF2BAF74)],
                ),
                shape: BoxShape.circle,
              )
            : isToday
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2BAF74),
                      width: 1.2,
                    ),
                  )
                : null,
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// 年份格（年份选择模式）
class _YearCell extends StatelessWidget {
  const _YearCell({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFF3DC88A),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Text(
          '$year',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}

/// 底部操作按钮
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary
              : const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
