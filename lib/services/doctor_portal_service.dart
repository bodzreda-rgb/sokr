import '../models/appointment_model.dart';
import '../models/diet_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_models.dart';
import 'supabase_service.dart';

// kol el queries elly el DOCTOR bystkhdmha (el RLS by5aly kol doctor yshof data beta3to bas)
class DoctorPortalService {
  static const _dietSelect = '*, doctors(full_name), diet_plan_items(*, food_items(*))';

  // el doctor row elly marboot bel account el 7ali
  static Future<DoctorModel?> getMyDoctor() async {
    final data = await supabase
        .from('doctors')
        .select()
        .eq('profile_id', currentUserId)
        .maybeSingle();
    return data == null ? null : DoctorModel.fromMap(data);
  }

  static Future<void> updateMyDoctor(String id, Map<String, dynamic> values) async {
    await supabase.from('doctors').update(values).eq('id', id);
  }

  // ---------------- appointments ----------------

  // el 7ogozat elly 3and el doctor (m3 esm w phone el patient)
  static Future<List<AppointmentModel>> getAppointments(String doctorId) async {
    final data = await supabase
        .from('appointments')
        .select('*, profiles(full_name, phone)')
        .eq('doctor_id', doctorId)
        .order('appointment_date')
        .order('appointment_time');
    return data.map(AppointmentModel.fromMap).toList();
  }

  // accept (confirmed) / reject (rejected) / complete (completed)
  static Future<void> setAppointmentStatus(String id, String status) async {
    await supabase.from('appointments').update({'status': status}).eq('id', id);
  }

  // ---------------- schedule ----------------

  static Future<void> addAvailability({
    required String doctorId,
    required int day,
    required String start,
    required String end,
  }) async {
    await supabase.from('doctor_availability').insert({
      'doctor_id': doctorId,
      'day_of_week': day,
      'start_time': start,
      'end_time': end,
    });
  }

  static Future<void> deleteAvailability(String id) async {
    await supabase.from('doctor_availability').delete().eq('id', id);
  }

  // ---------------- patient details ----------------

  static Future<HealthMetricModel?> getPatientLatestMetric(String patientId) async {
    final data = await supabase
        .from('health_metrics')
        .select()
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(1);
    return data.isEmpty ? null : HealthMetricModel.fromMap(data.first);
  }

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

  // ---------------- diet plans ----------------

  static Future<List<DietPlanModel>> getPatientDietPlans(String patientId) async {
    final data = await supabase
        .from('diet_plans')
        .select(_dietSelect)
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return data.map(DietPlanModel.fromMap).toList();
  }

  // hena el doctor bey3ml diet plan: el plan el awel, ba3den el akl elly feh
  static Future<void> createDietPlan({
    required String doctorId,
    required String patientId,
    required String title,
    required String notes,
    required List<({String foodId, String meal})> items,
  }) async {
    final plan = await supabase
        .from('diet_plans')
        .insert({'doctor_id': doctorId, 'patient_id': patientId, 'title': title, 'notes': notes})
        .select('id')
        .single();
    if (items.isEmpty) return;
    await supabase.from('diet_plan_items').insert([
      for (final i in items) {'plan_id': plan['id'], 'food_item_id': i.foodId, 'meal': i.meal},
    ]);
  }

  static Future<void> deleteDietPlan(String id) async {
    await supabase.from('diet_plans').delete().eq('id', id);
  }

  // el patient byshof el diet plans beta3to
  static Future<List<DietPlanModel>> getMyDietPlans() async {
    final data = await supabase
        .from('diet_plans')
        .select(_dietSelect)
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(DietPlanModel.fromMap).toList();
  }
}
