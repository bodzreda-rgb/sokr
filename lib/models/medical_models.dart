import 'model_helpers.dart';

// da el model beta3 el medical record
class MedicalRecordModel {
  final String id;
  final String title;
  final String description;
  final String? filePath; // el path gowa el storage bucket
  final String recordType;
  final DateTime createdAt;

  const MedicalRecordModel({
    required this.id,
    required this.title,
    required this.description,
    this.filePath,
    required this.recordType,
    required this.createdAt,
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map) =>
      MedicalRecordModel(
        id: map['id'] as String,
        title: (map['title'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        filePath: map['file_url'] as String?,
        recordType: (map['record_type'] ?? 'Health Summary') as String,
        createdAt: toDate(map['created_at']),
      );

  static const types = [
    'Prescriptions',
    'Lab Reports',
    'X-Ray Reports',
    'Vaccinations',
    'Health Summary',
  ];
}

// da el model beta3 qeyas se7y wa7ed
class HealthMetricModel {
  final String id;
  final int? heartRate;
  final String? bloodPressure;
  final int? bloodSugar;
  final double? weight;
  final double? height;
  final int? steps;
  final int? caloriesBurned;
  final double? sleepHours;
  final DateTime recordedAt;

  const HealthMetricModel({
    required this.id,
    this.heartRate,
    this.bloodPressure,
    this.bloodSugar,
    this.weight,
    this.height,
    this.steps,
    this.caloriesBurned,
    this.sleepHours,
    required this.recordedAt,
  });

  factory HealthMetricModel.fromMap(Map<String, dynamic> map) =>
      HealthMetricModel(
        id: map['id'] as String,
        heartRate: toIntOrNull(map['heart_rate']),
        bloodPressure: map['blood_pressure'] as String?,
        bloodSugar: toIntOrNull(map['blood_sugar']),
        weight: toDoubleOrNull(map['weight']),
        height: toDoubleOrNull(map['height']),
        steps: toIntOrNull(map['steps']),
        caloriesBurned: toIntOrNull(map['calories_burned']),
        sleepHours: toDoubleOrNull(map['sleep_hours']),
        recordedAt: toDate(map['recorded_at']),
      );
}

// da el model beta3 el roshetta
class PrescriptionModel {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String instructions;
  final String doctorName;
  final String patientName;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.instructions,
    required this.doctorName,
    required this.patientName,
    required this.createdAt,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    final doctor = asMap(map['doctors']);
    final doctorProfile = asMap(doctor['profiles']);
    final patient = asMap(map['profiles']);
    return PrescriptionModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      medicineName: (map['medicine_name'] ?? '') as String,
      dosage: (map['dosage'] ?? '') as String,
      instructions: (map['instructions'] ?? '') as String,
      doctorName: (doctorProfile['full_name'] ?? '') as String,
      patientName: (patient['full_name'] ?? '') as String,
      createdAt: toDate(map['created_at']),
    );
  }
}
