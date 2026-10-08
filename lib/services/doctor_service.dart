import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_models.dart';
import 'supabase_service.dart';

// kol el queries beta3t el doctors w el appointments w el prescriptions
class DoctorService {
  static const _doctorSelect = '*, profiles(full_name, avatar_url, phone)';
  static const _patientAppointmentSelect =
      '*, doctors(specialization, profiles(full_name))';
  static const _doctorAppointmentSelect = '*, profiles(full_name, phone)';

  // hena bngeb kol el doctors (w bn-join el esm men profiles)
  static Future<List<DoctorModel>> getDoctors() async {
    final data = await supabase
        .from('doctors')
        .select(_doctorSelect)
        .order('rating', ascending: false);
    return data.map(DoctorModel.fromMap).toList();
  }

  static Future<DoctorModel?> getDoctorById(String id) async {
    final data = await supabase
        .from('doctors')
        .select(_doctorSelect)
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : DoctorModel.fromMap(data);
  }

  // el doctor profile beta3 el user el 7ali (lel dashboard)
  static Future<DoctorModel?> getMyDoctorProfile() async {
    final data = await supabase
        .from('doctors')
        .select(_doctorSelect)
        .eq('profile_id', currentUserId)
        .maybeSingle();
    return data == null ? null : DoctorModel.fromMap(data);
  }

  static Future<void> updateDoctor(String id, Map<String, dynamic> values) async {
    await supabase.from('doctors').update(values).eq('id', id);
  }

  // ---------------- availability ----------------

  static Future<List<AvailabilityModel>> getAvailability(String doctorId) async {
    final data = await supabase
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .order('day_of_week')
        .order('start_time');
    return data.map(AvailabilityModel.fromMap).toList();
  }

  static Future<void> addAvailability({
    required String doctorId,
    required int dayOfWeek,
    required String start,
    required String end,
  }) async {
    await supabase.from('doctor_availability').insert({
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': start,
      'end_time': end,
    });
  }

  static Future<void> deleteAvailability(String id) async {
    await supabase.from('doctor_availability').delete().eq('id', id);
  }

  // hena bngeb el awqat el ma7goza (RPC 3shan mnshofsh data el patients el tanyeen)
  static Future<Set<String>> getBookedSlots(String doctorId, String date) async {
    final data = await supabase.rpc(
      'get_booked_slots',
      params: {'p_doctor': doctorId, 'p_date': date},
    );
    return (data as List).map((e) => e.toString().substring(0, 5)).toSet();
  }

  // ---------------- appointments ----------------

  // hena bn3ml insert lel appointment
  static Future<void> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    await supabase.from('appointments').insert({
      'patient_id': currentUserId,
      'doctor_id': doctorId,
      'appointment_date': date,
      'appointment_time': time,
      'notes': notes,
    });
  }

  // el patient byshof el appointments beta3to bas (RLS)
  static Future<List<AppointmentModel>> getMyAppointments() async {
    final data = await supabase
        .from('appointments')
        .select(_patientAppointmentSelect)
        .eq('patient_id', currentUserId)
        .order('appointment_date')
        .order('appointment_time');
    return data.map(AppointmentModel.fromMap).toList();
  }

  // a2rab appointment gaya lel home screen
  static Future<AppointmentModel?> getUpcomingAppointment() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await supabase
        .from('appointments')
        .select(_patientAppointmentSelect)
        .eq('patient_id', currentUserId)
        .inFilter('status', ['pending', 'confirmed'])
        .gte('appointment_date', today)
        .order('appointment_date')
        .order('appointment_time')
        .limit(1);
    return data.isEmpty ? null : AppointmentModel.fromMap(data.first);
  }

  // el appointments elly 3and el doctor
  static Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final data = await supabase
        .from('appointments')
        .select(_doctorAppointmentSelect)
        .eq('doctor_id', doctorId)
        .order('appointment_date')
        .order('appointment_time');
    return data.map(AppointmentModel.fromMap).toList();
  }

  // accept / reject / complete / cancel
  static Future<void> updateAppointmentStatus(String id, String status) async {
    await supabase.from('appointments').update({'status': status}).eq('id', id);
  }

  // ---------------- prescriptions ----------------

  static Future<void> addPrescription({
    required String doctorId,
    required String patientId,
    required String medicineName,
    required String dosage,
    required String instructions,
  }) async {
    await supabase.from('prescriptions').insert({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'instructions': instructions,
    });
  }

  static Future<List<PrescriptionModel>> getMyPrescriptions() async {
    final data = await supabase
        .from('prescriptions')
        .select('*, doctors(profiles(full_name)), profiles(full_name)')
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(PrescriptionModel.fromMap).toList();
  }

  static Future<List<PrescriptionModel>> getPrescriptionsForPatient(
      String doctorId, String patientId) async {
    final data = await supabase
        .from('prescriptions')
        .select('*, doctors(profiles(full_name)), profiles(full_name)')
        .eq('doctor_id', doctorId)
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return data.map(PrescriptionModel.fromMap).toList();
  }

  // a5er qeyas se7y lel patient (el doctor yshofo bas law 3ando appointment m3ah)
  static Future<HealthMetricModel?> getPatientLatestMetric(String patientId) async {
    final data = await supabase
        .from('health_metrics')
        .select()
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(1);
    return data.isEmpty ? null : HealthMetricModel.fromMap(data.first);
  }
}
