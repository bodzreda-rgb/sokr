// hena el credentials beta3t Supabase
// 7ot el URL w el anon/publishable key bta3 el project bta3ak
// (Supabase Dashboard -> Project Settings -> API)
//
// MOHEM: matrga3sh service_role key hena abadan, da secret lel server bas.
//
// momken kman tb3thom men bara b:
// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bnhoxtuuicxntshnejqj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_aFtRkKn6ZrX03wDLEMJ1hA_M1R_Gbcf',
  );

  // esm el bucket elly bn7ot feh el medical records files
  static const String medicalBucket = 'medical-records';

  // bn-check en el user 7at el credentials fe3lan
  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.isNotEmpty;
}
