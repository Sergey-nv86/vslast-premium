import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stable business identity used by the client application.
///
/// During the migration the Supabase Auth user id remains an internal
/// security anchor. Business features should gradually move to clientId.
///
/// The service never stores or requests name, phone, email, birth date or
/// delivery address.
class ClientIdentityService {
  ClientIdentityService._();

  static final ClientIdentityService instance = ClientIdentityService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  String? _clientId;
  Future<String?>? _pendingLoad;

  String? get clientId => _clientId;

  bool get hasClientId => _clientId != null && _clientId!.isNotEmpty;

  Future<String?> ensureClientId() async {
    if (hasClientId) return _clientId;

    final existing = _pendingLoad;
    if (existing != null) return existing;

    final future = _loadClientId();
    _pendingLoad = future;

    try {
      return await future;
    } finally {
      _pendingLoad = null;
    }
  }

  Future<String?> _loadClientId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[ClientID] No authenticated session');
      return null;
    }

    try {
      final response = await _supabase.rpc('ensure_client_account');

      String? value;

      if (response is List && response.isNotEmpty) {
        final row = response.first;
        if (row is Map) {
          value = row['client_id']?.toString();
        }
      } else if (response is Map) {
        value = response['client_id']?.toString();
      }

      if (value == null || value!.trim().isEmpty) {
        debugPrint('[ClientID] RPC returned no client_id');
        return null;
      }

      _clientId = value!.trim();
      debugPrint('[ClientID] Ready: $_clientId');
      return _clientId;
    } catch (error, stackTrace) {
      debugPrint('[ClientID] Failed to ensure client id: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  void clear() {
    _clientId = null;
  }
}
