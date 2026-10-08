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

  static Future<GymModel?> getMyGym() async {
    final data = await supabase
        .from('gyms')
        .select()
        .eq('owner_id', currentUserId)
        .limit(1);
    return data.isEmpty ? null : GymModel.fromMap(data.first);
  }

  static Future<void> updateGym(String id, Map<String, dynamic> values) async {
    await supabase.from('gyms').update(values).eq('id', id);
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

  // el gym owner bey-add tamreen gedid w ye-rbto bel gym bta3o
  static Future<void> addGymExercise(String gymId, ExerciseModel exercise) async {
    final inserted = await supabase
        .from('exercises')
        .insert({...exercise.toMap(), 'created_by': currentUserId})
        .select('id')
        .single();
    await supabase.from('gym_exercises').insert({
      'gym_id': gymId,
      'exercise_id': inserted['id'],
    });
  }

  static Future<void> updateExercise(String id, Map<String, dynamic> values) async {
    await supabase.from('exercises').update(values).eq('id', id);
  }

  // law el tamreen bta3o yt3mlo delete, law tamreen 3am bnshelo men el gym bas
  static Future<void> removeGymExercise(String gymId, ExerciseModel exercise) async {
    if (exercise.createdBy == currentUserId) {
      await supabase.from('exercises').delete().eq('id', exercise.id);
    } else {
      await supabase
          .from('gym_exercises')
          .delete()
          .eq('gym_id', gymId)
          .eq('exercise_id', exercise.id);
    }
  }
}
