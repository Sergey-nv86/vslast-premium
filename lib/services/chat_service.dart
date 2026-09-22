import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>> ensureMyThread() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован.');

    final existing = await _supabase
        .from('chat_threads')
        .select('id, client_user_id, client_id, last_message_at, last_message_preview')
        .eq('client_user_id', user.id)
        .maybeSingle();

    if (existing != null) return Map<String, dynamic>.from(existing);

    final account = await _supabase
        .from('client_accounts')
        .select('client_id')
        .eq('legacy_user_id', user.id)
        .maybeSingle();

    final inserted = await _supabase
        .from('chat_threads')
        .insert({
          'client_user_id': user.id,
          'client_id': account?['client_id'],
        })
        .select('id, client_user_id, client_id, last_message_at, last_message_preview')
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  Future<int> unreadForCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final result = await _supabase
        .from('chat_messages')
        .select('id, chat_threads!inner(client_user_id)')
        .eq('chat_threads.client_user_id', user.id)
        .neq('sender_user_id', user.id)
        .isFilter('read_at', null);

    return result.length;
  }

  Future<List<Map<String, dynamic>>> messages(String threadId) async {
    final rows = await _supabase
        .from('chat_messages')
        .select('id, thread_id, sender_user_id, sender_role, body, image_path, created_at, read_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    return _withSignedUrls(
      rows.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  Future<void> markIncomingRead(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('chat_messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('thread_id', threadId)
        .neq('sender_user_id', user.id)
        .isFilter('read_at', null);
  }

  Future<void> sendMessage({
    required String threadId,
    String? body,
    String? imagePath,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован.');

    final isAdmin = await _isAdmin();
    await _supabase.from('chat_messages').insert({
      'thread_id': threadId,
      'sender_user_id': user.id,
      'sender_role': isAdmin ? 'admin' : 'customer',
      'body': body?.trim().isEmpty == true ? null : body?.trim(),
      'image_path': imagePath,
    });
  }

  Future<String?> pickAndUploadImage(String threadId) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;

    final extension = _extension(picked.name);
    final path = '${threadId}/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _supabase.storage.from('chat-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _contentType(extension),
        upsert: false,
      ),
    );

    return path;
  }

  Future<List<Map<String, dynamic>>> adminThreads() async {
    final rows = await _supabase
        .from('chat_threads')
        .select('id, client_user_id, client_id, last_message_at, last_message_preview, created_at')
        .order('last_message_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false);

    final threads = rows.map((e) => Map<String, dynamic>.from(e)).toList();
    final userIds = threads
        .map((e) => e['client_user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final profiles = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final profileRows = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, display_name, phone')
          .inFilter('id', userIds);
      for (final row in profileRows) {
        final map = Map<String, dynamic>.from(row);
        profiles[map['id'].toString()] = map;
      }
    }

    for (final thread in threads) {
      final id = thread['client_user_id']?.toString();
      thread['profile'] = id == null ? null : profiles[id];
      thread['unread_count'] = await _unreadForThread(
        thread['id'].toString(),
        incomingOnly: true,
      );
    }

    return threads;
  }

  Future<int> adminUnreadCount() async {
    final rows = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('sender_role', 'customer')
        .isFilter('read_at', null);
    return rows.length;
  }

  Future<int> _unreadForThread(
    String threadId, {
    required bool incomingOnly,
  }) async {
    var query = _supabase
        .from('chat_messages')
        .select('id')
        .eq('thread_id', threadId)
        .isFilter('read_at', null);

    if (incomingOnly) query = query.eq('sender_role', 'customer');

    final rows = await query;
    return rows.length;
  }

  Future<bool> _isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final row = await _supabase
        .from('profiles')
        .select('role, is_active')
        .eq('id', user.id)
        .maybeSingle();
    final role = row?['role']?.toString();
    return row?['is_active'] == true &&
        {'owner', 'admin', 'manager'}.contains(role);
  }

  Future<List<Map<String, dynamic>>> _withSignedUrls(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final path = row['image_path']?.toString();
      if (path == null || path.isEmpty) continue;
      try {
        row['image_url'] = await _supabase.storage
            .from('chat-images')
            .createSignedUrl(path, 60 * 60);
      } catch (_) {
        row['image_url'] = null;
      }
    }
    return rows;
  }

  String _extension(String name) {
    final value = name.split('.').last.toLowerCase();
    if (value == 'png') return 'png';
    if (value == 'webp') return 'webp';
    return 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
