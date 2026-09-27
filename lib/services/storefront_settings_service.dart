import 'package:supabase_flutter/supabase_flutter.dart';

/// Global storefront settings used by the client Home screen and Admin UI.
class StorefrontSettingsService {
  StorefrontSettingsService._();

  static final StorefrontSettingsService instance =
      StorefrontSettingsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  bool? _homeAvailabilityEnabled;

  Future<bool> getHomeAvailabilityEnabled({
    bool forceRefresh = false,
  }) async {
    final cached = _homeAvailabilityEnabled;
    if (!forceRefresh && cached != null) {
      return cached;
    }

    final row = await _supabase
        .from('order_settings')
        .select('home_availability_enabled')
        .eq('id', 1)
        .single();

    final enabled = row['home_availability_enabled'] != false;
    _homeAvailabilityEnabled = enabled;
    return enabled;
  }

  Future<void> setHomeAvailabilityEnabled(bool enabled) async {
    await _supabase
        .from('order_settings')
        .update({
          'home_availability_enabled': enabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', 1);

    _homeAvailabilityEnabled = enabled;
  }
}
