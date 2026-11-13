class SupabaseConfig {
  // Production remains the default. Preview builds override these at compile time.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hcisinnackmcijghrtsa.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable__mFECEGceujEPpU1yI2g2A_elVI63hE',
  );
}
