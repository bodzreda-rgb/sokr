import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_models.dart';
import 'supabase_service.dart';

// kol el queries beta3t el doctors w el appointments w el prescriptions
class DoctorService {
  static const _patientAppointmentSelect = '*, doctors(full_name, specialization)';
  static const _prescriptionSelect = '*, doctors(full_name), profiles(full_name)';

  // hena bngeb kol el doctors men Supabase
  static Future<List<DoctorModel>> getDoctors() async {
    final data = await supabase
        .from('doctors')
        .select()
        .order('rating', ascending: false);
    return data.map(DoctorModel.fromMap).toList();
  }

  static Future<DoctorModel?> getDoctorById(String id) async {
    final data = await supabase
        .from('doctors')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : DoctorModel.fromMap(data);
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

  // el patient by-cancel el 7agz bta3o
  static Future<void> updateAppointmentStatus(String id, String status) async {
    await supabase.from('appointments').update({'status': status}).eq('id', id);
  }

  // el patient byshof el roshetat beta3to bas (el admin howa elly byd5lha)
  static Future<List<PrescriptionModel>> getMyPrescriptions() async {
    final data = await supabase
        .from('prescriptions')
        .select(_prescriptionSelect)
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(PrescriptionModel.fromMap).toList();
  }
}
