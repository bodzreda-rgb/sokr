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
}
