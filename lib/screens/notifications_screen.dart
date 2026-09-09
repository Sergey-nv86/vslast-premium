import 'package:flutter/material.dart';

import '../models/order_list_item.dart';
import '../services/notification_service.dart';
import '../screens/order_detail_screen.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationService.instance.fetchNotifications();
  }

  Future<void> _reload() async {
    setState(() {
      _notificationsFuture = NotificationService.instance.fetchNotifications();
    });
    try {
      await _notificationsFuture;
    } catch (_) {}
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await NotificationService.instance.markRead(notification.id);
      if (!mounted) return;
      setState(() {
        _notificationsFuture = NotificationService.instance.fetchNotifications();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.instance.markAllRead();
      if (!mounted) return;
      setState(() {
        _notificationsFuture = NotificationService.instance.fetchNotifications();
      });
    } catch (_) {}
  }

  Future<void> _open(AppNotification notification) async {
    await _markRead(notification);
    if (!mounted) return;
    final orderId = notification.orderId;
    if (orderId == null || orderId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Прочитать все'),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Не удалось загрузить уведомления')),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? const [];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFFC4956A))),
                  SizedBox(height: 14),
                  Center(child: Text('Уведомлений пока нет')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Material(
                  color: notification.isRead ? Colors.white : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _open(notification),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5E6D3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notification.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                              color: AppColors.primaryBrown,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: AppTextStyles.rowLabelMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(notification.createdAt),
                                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 5),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB5423F),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }
}
