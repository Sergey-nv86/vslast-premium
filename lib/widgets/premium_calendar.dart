import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumCalendar extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onSelected;

  const PremiumCalendar({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onSelected,
  });

  @override
  State<PremiumCalendar> createState() => _PremiumCalendarState();
}

class _PremiumCalendarState extends State<PremiumCalendar> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  static const _weekDays = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  static const _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  void initState() {
    super.initState();

    _selectedDate = _dateOnly(widget.initialDate);
    _visibleMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _isBefore(DateTime a, DateTime b) {
    return _dateOnly(a).isBefore(_dateOnly(b));
  }

  bool _isAfter(DateTime a, DateTime b) {
    return _dateOnly(a).isAfter(_dateOnly(b));
  }

  bool _isAllowed(DateTime date) {
    return !_isBefore(date, widget.firstDate) &&
        !_isAfter(date, widget.lastDate);
  }

  void _previousMonth() {
    final previous = DateTime(
      _visibleMonth.year,
      _visibleMonth.month - 1,
    );

    final firstAllowedMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );

    if (previous.isBefore(firstAllowedMonth)) return;

    setState(() {
      _visibleMonth = previous;
    });
  }

  void _nextMonth() {
    final next = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
    );

    final lastAllowedMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );

    if (next.isAfter(lastAllowedMonth)) return;

    setState(() {
      _visibleMonth = next;
    });
  }

  List<DateTime?> _buildDays() {
    final firstDay = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    // DateTime.weekday: Пн = 1 ... Вс = 7.
    final leadingEmpty = firstDay.weekday - 1;

    final cells = <DateTime?>[];

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(
        DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          day,
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = _buildDays();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.divider,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 6),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _MonthButton(
                  icon: Icons.chevron_left,
                  onTap: _previousMonth,
                ),
                const SizedBox(width: 4),
                _MonthButton(
                  icon: Icons.chevron_right,
                  onTap: _nextMonth,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                for (final day in _weekDays)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: day == 'Сб' || day == 'Вс'
                              ? AppColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final date = days[index];

                if (date == null) {
                  return const SizedBox.shrink();
                }

                final selected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, today);
                final allowed = _isAllowed(date);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: allowed
                      ? () {
                          setState(() {
                            _selectedDate = date;
                          });

                          widget.onSelected(date);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBrown
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !selected
                          ? Border.all(
                              color: AppColors.primaryBrown,
                              width: 1.3,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected || isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: !allowed
                            ? AppColors.textSecondary.withValues(alpha: .35)
                            : selected
                                ? Colors.white
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBrown,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Сегодня',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 22,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
