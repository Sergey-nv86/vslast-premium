import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.readAt,
  });

  bool get isRead => readAt != null;

  String? get orderId => data['order_id']?.toString();

  factory AppNotification.fromMap(Map<String, dynamic> row) {
    final rawData = row['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return AppNotification(
      id: row['id'].toString(),
      type: row['type']?.toString() ?? 'notification',
      title: row['title']?.toString() ?? 'Всласть',
      body: row['body']?.toString() ?? '',
      data: data,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: DateTime.tryParse(row['read_at']?.toString() ?? ''),
    );
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<AppNotification>> fetchNotifications({int limit = 100}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _supabase
        .from('notification_queue')
        .select('id,type,title,body,data,created_at,read_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final rows = await _supabase
        .from('notification_queue')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null);

    return rows.length;
  }

  Future<void> markRead(String notificationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notification_queue')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  Future<void> markAllRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notification_queue')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}
