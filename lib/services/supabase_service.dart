import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

// hena bn3ml connection m3 Supabase mara wa7da f awel el app
class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey, // public key bas (msh service_role)
    );
  }
}

// shortcut lel client 3shan nst5dmo f kol el services
SupabaseClient get supabase => Supabase.instance.client;

// el id beta3 el user elly 3aml login dlwa2ty
String get currentUserId {
  final id = supabase.auth.currentUser?.id;
  if (id == null) throw const AuthException('Please login first');
  return id;
}

// bn7wl ay error men Supabase le message mafhoma lel user
String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '23505') return 'This item already exists or the slot is taken.';
    if (error.code == '42501') return 'You are not allowed to do this action.';
    return error.message;
  }
  if (error is StorageException) return error.message;
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return 'No internet connection. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
