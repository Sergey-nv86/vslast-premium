import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Клиентский экран «График».
///
/// На первом этапе это самостоятельный UI-экран.
/// Реальные даты/заказы будут подключены следующим этапом
/// без изменения утверждённой структуры интерфейса.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  static const List<String> _weekDays = [
    'ПН',
    'ВТ',
    'СР',
    'ЧТ',
    'ПТ',
    'СБ',
    'ВС',
  ];

  static const List<String> _timeSlots = [
    '10:00–12:00',
    '12:00–14:00',
    '14:00–16:00',
    '16:00–18:00',
    '18:00–20:00',
  ];

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return months[month - 1];
  }

  String _monthTitle(DateTime date) {
    const months = [
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

    return months[date.month - 1];
  }

  List<DateTime> _buildWeek() {
    final date = _dateOnly(_selectedDate);

    final monday = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final week = _buildWeek();
    final today = _dateOnly(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('График', style: AppTextStyles.screenTitle),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _selectDate(today);
                        },
                        icon: const Icon(
                          Icons.today_outlined,
                          size: 21,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ----------------------------------------------------------
            // БЛИЖАЙШИЙ ЗАКАЗ
            // ----------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_available_outlined,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Ближайшее получение',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${today.day} ${_monthName(today.month)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Выберите дату ниже',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ----------------------------------------------------------
            // МЕСЯЦ
            // ----------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _monthTitle(_selectedDate),
                        style: AppTextStyles.sectionLabel.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedDate.year}',
                      style: AppTextStyles.rowLabelMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ----------------------------------------------------------
            // НЕДЕЛЯ
            // ----------------------------------------------------------
            SliverToBoxAdapter(
              child: SizedBox(
                height: 82,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: week.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = week[index];
                    final selected = _isSameDay(date, _selectedDate);
                    final isToday = _isSameDay(date, today);

                    return GestureDetector(
                      onTap: () => _selectDate(date),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 54,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBrown
                              : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryBrown
                                : AppColors.divider,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekDays[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white70
                                    : AppColors.rowLabelMuted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.primaryBrown,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            // ----------------------------------------------------------
            // ВЫБРАННАЯ ДАТА
            // ----------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${_selectedDate.day} ${_monthName(_selectedDate.month)}',
                  style: AppTextStyles.sectionLabel.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ----------------------------------------------------------
            // ИНТЕРВАЛЫ
            // ----------------------------------------------------------
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _timeSlots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_outlined,
                            size: 19,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slot,
                            style: AppTextStyles.rowLabel.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primaryBrown,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ----------------------------------------------------------
            // ИНФОРМАЦИЯ
            // ----------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 21,
                        color: AppColors.primaryBrown,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Здесь будет отображаться график получения '
                          'ваших заказов. Вы сможете быстро увидеть '
                          'дату, на которую вы хотите оформить предзаказ.',
                          style: AppTextStyles.rowLabel.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
