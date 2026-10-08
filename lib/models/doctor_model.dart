import 'model_helpers.dart';

// da el model beta3 el doctor (doctors + el profile bta3o)
class DoctorModel {
  final String id;
  final String profileId;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String specialization;
  final String bio;
  final int yearsExperience;
  final double consultationPrice;
  final String clinicName;
  final String clinicAddress;
  final double? latitude;
  final double? longitude;
  final double rating;
  final bool isAvailable;

  const DoctorModel({
    required this.id,
    required this.profileId,
    required this.name,
    this.avatarUrl,
    this.phone,
    required this.specialization,
    required this.bio,
    required this.yearsExperience,
    required this.consultationPrice,
    required this.clinicName,
    required this.clinicAddress,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.isAvailable,
  });

  // el query bt-join el profiles: select('*, profiles(full_name, avatar_url, phone)')
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    final profile = asMap(map['profiles']);
    return DoctorModel(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: (profile['full_name'] ?? 'Doctor') as String,
      avatarUrl: profile['avatar_url'] as String?,
      phone: profile['phone'] as String?,
      specialization: (map['specialization'] ?? '') as String,
      bio: (map['bio'] ?? '') as String,
      yearsExperience: toInt(map['years_experience']),
      consultationPrice: toDouble(map['consultation_price']),
      clinicName: (map['clinic_name'] ?? '') as String,
      clinicAddress: (map['clinic_address'] ?? '') as String,
      latitude: toDoubleOrNull(map['latitude']),
      longitude: toDoubleOrNull(map['longitude']),
      rating: toDouble(map['rating']),
      isAvailable: (map['is_available'] ?? true) as bool,
    );
  }

  // el specializations elly bnst5dmha f el filter
  static const specializations = [
    'Cardiologist',
    'Neurologist',
    'Dentist',
    'Orthopedic',
    'Endocrinologist',
    'Dermatologist',
    'Pediatrician',
    'General Practitioner',
  ];
}

// da el model beta3 mawa3eed el doctor f el esbo3
class AvailabilityModel {
  final String id;
  final String doctorId;
  final int dayOfWeek; // 0 = Sunday ... 6 = Saturday
  final String startTime; // "10:00:00"
  final String endTime;
  final bool isAvailable;

  const AvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) =>
      AvailabilityModel(
        id: map['id'] as String,
        doctorId: map['doctor_id'] as String,
        dayOfWeek: toInt(map['day_of_week']),
        startTime: (map['start_time'] ?? '00:00:00') as String,
        endTime: (map['end_time'] ?? '00:00:00') as String,
        isAvailable: (map['is_available'] ?? true) as bool,
      );

  static const dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayName => dayNames[dayOfWeek % 7];
}
