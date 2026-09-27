import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/client_identity_service.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _favoriteIds.clear();
        _loadedUserId = null;
        notifyListeners();
        return;
      }

      if (data.session != null) {
        unawaited(load());
      }
    });

    if (_supabase.auth.currentUser != null) {
      unawaited(load());
    }
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  final Set<String> _favoriteIds = {};

  StreamSubscription<AuthState>? _authSubscription;
  Future<void>? _loadRequest;
  String? _loadedUserId;

  bool isFavorite(Product product) => _favoriteIds.contains(product.id);

  int get count => _favoriteIds.length;

  Future<void> load({bool forceRefresh = false}) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _favoriteIds.clear();
      _loadedUserId = null;
      return Future<void>.value();
    }

    if (!forceRefresh && _loadedUserId == user.id) {
      return Future<void>.value();
    }

    final existing = _loadRequest;
    if (existing != null) {
      return existing;
    }

    final request = _loadFromSupabase(user.id);
    _loadRequest = request;

    return request.whenComplete(() {
      if (identical(_loadRequest, request)) {
        _loadRequest = null;
      }
    });
  }

  Future<void> _loadFromSupabase(String userId) async {
    try {
      final rows = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);

      _favoriteIds
        ..clear()
        ..addAll(
          rows
              .map((row) => row['product_id']?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty),
        );

      _loadedUserId = userId;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('[Favorites] load error: $error');
      debugPrint('$stackTrace');
    }
  }

  void toggle(Product product) {
    final user = _supabase.auth.currentUser;
    final productId = product.id.trim();
    if (productId.isEmpty) return;

    final wasFavorite = _favoriteIds.contains(productId);

    if (wasFavorite) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    if (user == null) return;

    unawaited(
      _persistToggle(
        userId: user.id,
        productId: productId,
        add: !wasFavorite,
      ),
    );
  }

  Future<void> _persistToggle({
    required String userId,
    required String productId,
    required bool add,
  }) async {
    try {
      if (add) {
        final clientId =
            await ClientIdentityService.instance.ensureClientId();

        final payload = <String, dynamic>{
          'user_id': userId,
          'product_id': productId,
        };

        if (clientId != null && clientId.isNotEmpty) {
          payload['client_id'] = clientId;
        }

        // favorites has INSERT/DELETE/SELECT RLS, but no UPDATE policy.
        // upsert() turns an existing row into UPDATE and is therefore rejected
        // by RLS. A normal INSERT is the correct operation for adding a favorite.
        await _supabase.from('favorites').insert(payload);
      } else {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      }
    } catch (error, stackTrace) {
      debugPrint('[Favorites] persist error: $error');
      debugPrint('$stackTrace');

      // Keep UI and database consistent if persistence fails.
      if (add) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
