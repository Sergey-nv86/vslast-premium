import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.instance.fetchNotifications();
  }

  Future<void> _reload() async {
    final future = NotificationService.instance.fetchNotifications();
    setState(() => _future = future);
    await future;
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.instance.markRead(notification.id);
      if (mounted) setState(() {});
    }

    final orderId = notification.orderId;
    if (orderId != null && orderId.isNotEmpty && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
      );
    }
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    if (sameDay) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return 'Сегодня, $hh:$mm';
    }
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryBrown)),
        iconTheme: const IconThemeData(color: AppColors.primaryBrown),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.instance.markAllRead();
              await _reload();
            },
            child: const Text('Прочитать все', style: TextStyle(color: AppColors.primaryBrown)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFC4956A),
        onRefresh: _reload,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFC4956A)));
            }
            if (snapshot.hasError) {
              return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                const SizedBox(height: 180),
                Center(child: Text('Не удалось загрузить уведомления')),
                const SizedBox(height: 12),
                Center(child: TextButton(onPressed: _reload, child: const Text('Повторить'))),
              ]);
            }

            final notifications = snapshot.data ?? const [];
            if (notifications.isEmpty) {
              return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                SizedBox(height: 180),
                Center(child: Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFFC4956A))),
                SizedBox(height: 14),
                Center(child: Text('Уведомлений пока нет')),
              ]);
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Material(
                  color: notification.isRead ? Colors.white : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _open(notification),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(color: Color(0xFFF1E8E0), shape: BoxShape.circle),
                            child: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryBrown),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800, color: AppColors.primaryBrown))),
                                  if (!notification.isRead) const Padding(padding: EdgeInsets.only(left: 8), child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFB5423F))),
                                ]),
                                const SizedBox(height: 5),
                                Text(notification.body, style: AppTextStyles.rowLabelMuted),
                                const SizedBox(height: 7),
                                Text(_dateLabel(notification.createdAt), style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
