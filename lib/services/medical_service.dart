import 'dart:typed_data';

import '../core/supabase_config.dart';
import '../models/medical_models.dart';
import 'supabase_service.dart';

// kol el queries beta3t el medical records w el health metrics w el favorites
class MedicalService {
  // ---------------- medical records ----------------

  // el user byshof el records beta3to bas (RLS)
  static Future<List<MedicalRecordModel>> getRecords() async {
    final data = await supabase
        .from('medical_records')
        .select()
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(MedicalRecordModel.fromMap).toList();
  }

  // hena bn-upload el medical record: el file f Storage w el data f el table
  static Future<void> addRecord({
    required String title,
    required String type,
    required String description,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    String? path;
    if (fileBytes != null && fileName != null) {
      // el folder lazem ykon = user id 3shan el storage policy
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      path = '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await supabase.storage
          .from(SupabaseConfig.medicalBucket)
          .uploadBinary(path, fileBytes);
    }
    await supabase.from('medical_records').insert({
      'patient_id': currentUserId,
      'title': title,
      'record_type': type,
      'description': description,
      'file_url': path,
    });
  }

  // el bucket private, fa bn3ml signed URL temporary 3shan nfta7 el file
  static Future<String> getFileUrl(String path) async {
    return supabase.storage
        .from(SupabaseConfig.medicalBucket)
        .createSignedUrl(path, 60 * 10);
  }

  static Future<void> deleteRecord(MedicalRecordModel record) async {
    if (record.filePath != null) {
      await supabase.storage
          .from(SupabaseConfig.medicalBucket)
          .remove([record.filePath!]);
    }
    await supabase.from('medical_records').delete().eq('id', record.id);
  }

  // ---------------- health metrics ----------------

  static Future<List<HealthMetricModel>> getMetrics({int limit = 14}) async {
    final data = await supabase
        .from('health_metrics')
        .select()
        .eq('patient_id', currentUserId)
        .order('recorded_at', ascending: false)
        .limit(limit);
    return data.map(HealthMetricModel.fromMap).toList();
  }

  static Future<HealthMetricModel?> getLatestMetric() async {
    final list = await getMetrics(limit: 1);
    return list.isEmpty ? null : list.first;
  }

  // hena bn-save qeyas se7y gedid
  static Future<void> addMetric(Map<String, dynamic> values) async {
    await supabase
        .from('health_metrics')
        .insert({...values, 'patient_id': currentUserId});
  }

  // ---------------- favorites ----------------

  static Future<bool> isFavorite(String type, String itemId) async {
    final data = await supabase
        .from('favorites')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('item_type', type)
        .eq('item_id', itemId)
        .limit(1);
    return data.isNotEmpty;
  }

  // law mawgood bnshelo, law msh mawgood bn-add-o
  static Future<bool> toggleFavorite(String type, String itemId) async {
    if (await isFavorite(type, itemId)) {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', currentUserId)
          .eq('item_type', type)
          .eq('item_id', itemId);
      return false;
    }
    await supabase.from('favorites').insert({
      'user_id': currentUserId,
      'item_type': type,
      'item_id': itemId,
    });
    return true;
  }

  // btrg3 list men (type, id, name) 3shan n3rdha f el favorites page
  static Future<List<({String type, String id, String name})>> getFavorites() async {
    final favs = await supabase
        .from('favorites')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);

    final result = <({String type, String id, String name})>[];
    // kol type leh table mo5tlef
    const tables = {
      'doctor': 'doctors',
      'pharmacy': 'pharmacies',
      'gym': 'gyms',
      'restaurant': 'restaurants',
    };
    for (final entry in tables.entries) {
      final ids = favs
          .where((f) => f['item_type'] == entry.key)
          .map((f) => f['item_id'] as String)
          .toList();
      if (ids.isEmpty) continue;
      final rows = await supabase
          .from(entry.value)
          .select(entry.key == 'doctor' ? 'id, profiles(full_name)' : 'id, name')
          .inFilter('id', ids);
      for (final row in rows) {
        final name = entry.key == 'doctor'
            ? ((row['profiles'] as Map?)?['full_name'] ?? 'Doctor') as String
            : (row['name'] ?? '') as String;
        result.add((type: entry.key, id: row['id'] as String, name: name));
      }
    }
    return result;
  }
}
