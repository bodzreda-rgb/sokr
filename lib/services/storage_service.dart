import 'dart:typed_data';

import 'supabase_service.dart';

// hena el admin byrf3 sowar (adwya, doctors, gyms, akl...) 3la bucket public
class StorageService {
  static const bucket = 'app-images';

  // btrg3 el public URL beta3 el sora 3shan nt5zno f el table
  static Future<String> uploadImage(Uint8List bytes, String fileName, String folder) async {
    final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await supabase.storage.from(bucket).uploadBinary(path, bytes);
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
