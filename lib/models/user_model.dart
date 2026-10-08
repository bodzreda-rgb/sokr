// da el model beta3 el user profile (men table profiles)
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        fullName: (map['full_name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        phone: map['phone'] as String?,
        role: (map['role'] ?? UserRoles.patient) as String,
        avatarUrl: map['avatar_url'] as String?,
      );

  // el first name bas lel greeting f el home
  String get firstName =>
      fullName.trim().isEmpty ? 'there' : fullName.trim().split(' ').first;
}

// el roles elly mawgoda f el app (patient = el user el 3adi, doctor = el doctor, admin = by-edit kol 7aga)
class UserRoles {
  static const patient = 'patient';
  static const doctor = 'doctor';
  static const admin = 'admin';
}
