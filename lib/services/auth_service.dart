import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'supabase_service.dart';

// da el service elly bey3ml kol 7aga leha 3elaqa bel Authentication
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // el profile beta3 el user el 7ali (el screens bt-listen 3aleh)
  final profile = ValueNotifier<UserModel?>(null);

  // auth state listener: by2olna lama el user y3ml login aw logout
  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  Session? get session => supabase.auth.currentSession;

  // da el signup: bnb3t el data le Edge Function "signup" 3la el server,
  // heya btfta7 el account confirmed (mn 8er email), w ba3d keda bn3ml login 3la tool.
  // el trigger f el database bey3ml el profile automatic (dayman patient)
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      await supabase.functions.invoke('signup', body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      });
    } on FunctionException catch (e) {
      // el server rad b error (masalan el email mawgood) -> nzhr el message lel user
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : details?.toString();
      throw AuthException(message ?? 'Sign up failed. Please try again.');
    }
    await signIn(email, password);
    return true;
  }

  // da el login function beta3t el user
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // forgot password: Supabase byb3t email feh link l-reset
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    profile.value = null;
  }

  // hena bngeb el profile (w el role) men table profiles
  Future<UserModel> loadProfile() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .single();
    final user = UserModel.fromMap(data);
    profile.value = user;
    return user;
  }

  // hena bn3dl el profile (el RLS mtsm7sh y3dl 8er profile bta3o)
  Future<void> updateProfile({required String fullName, String? phone}) async {
    await supabase.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
    }).eq('id', currentUserId);
    await loadProfile();
  }
}
