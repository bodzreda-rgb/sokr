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

  // da el signup: el esm w el phone byt5zno f metadata,
  // w el trigger f el database bey3ml el profile automatic (dayman patient)
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      },
    );
    // law email confirmation shaghal, el session btb2a null le7d ma y-confirm
    return res.session != null;
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
