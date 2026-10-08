import 'model_helpers.dart';

// da el model beta3 el appointment
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime date;
  final String time; // "10:30:00"
  final String status;
  final String? notes;
  // data idafeya men el join (esm el doctor aw el patient)
  final String doctorName;
  final String specialization;
  final String patientName;
  final String? patientPhone;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    this.doctorName = '',
    this.specialization = '',
    this.patientName = '',
    this.patientPhone,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    final doctor = asMap(map['doctors']);
    final patient = asMap(map['profiles']);
    return AppointmentModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      doctorId: map['doctor_id'] as String,
      date: toDate(map['appointment_date']),
      time: (map['appointment_time'] ?? '') as String,
      status: (map['status'] ?? 'pending') as String,
      notes: map['notes'] as String?,
      doctorName: (doctor['full_name'] ?? '') as String,
      specialization: (doctor['specialization'] ?? '') as String,
      patientName: (patient['full_name'] ?? 'Patient') as String,
      patientPhone: patient['phone'] as String?,
    );
  }

  bool get isActive => status == 'pending' || status == 'confirmed';
}
