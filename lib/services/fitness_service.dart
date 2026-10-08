import '../models/exercise_model.dart';
import '../models/gym_model.dart';
import 'supabase_service.dart';

// kol el queries beta3t el tamareen w el gyms
class FitnessService {
  // hena bngeb kol el tamareen
  static Future<List<ExerciseModel>> getExercises() async {
    final data = await supabase.from('exercises').select().order('name');
    return data.map(ExerciseModel.fromMap).toList();
  }

  static Future<List<GymModel>> getGyms() async {
    final data =
        await supabase.from('gyms').select().order('rating', ascending: false);
    return data.map(GymModel.fromMap).toList();
  }

  // el tamareen elly mawgoda f gym mo3ayan (men el link table gym_exercises)
  static Future<List<ExerciseModel>> getGymExercises(String gymId) async {
    final data = await supabase
        .from('gym_exercises')
        .select('exercises(*)')
        .eq('gym_id', gymId);
    return data
        .where((row) => row['exercises'] != null)
        .map((row) => ExerciseModel.fromMap(row['exercises'] as Map<String, dynamic>))
        .toList();
  }

  // ---------------- gym plans + subscriptions ----------------

  // bakat el eshterak beta3t gym mo3ayan
  static Future<List<GymPlanModel>> getGymPlans(String gymId) async {
    final data = await supabase
        .from('gym_plans')
        .select()
        .eq('gym_id', gymId)
        .order('duration_months');
    return data.map(GymPlanModel.fromMap).toList();
  }

  // hena el patient by-subscribe (el RPC by7seb el se3r w el tarekh)
  static Future<void> subscribe(String planId) async {
    await supabase.rpc('subscribe_gym', params: {'p_plan': planId});
  }

  static Future<List<GymSubscriptionModel>> getMySubscriptions() async {
    final data = await supabase
        .from('gym_subscriptions')
        .select('*, gyms(name)')
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(GymSubscriptionModel.fromMap).toList();
  }

  static Future<void> cancelSubscription(String id) async {
    await supabase.from('gym_subscriptions').update({'status': 'cancelled'}).eq('id', id);
  }
}
