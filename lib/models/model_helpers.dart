// helpers soghayara 3shan n7wl el JSON elly gay men Supabase bdon crash law feh null
double toDouble(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;
int toInt(dynamic v) => v == null ? 0 : int.tryParse(v.toString().split('.').first) ?? 0;
int? toIntOrNull(dynamic v) => v == null ? null : toInt(v);
double? toDoubleOrNull(dynamic v) => v == null ? null : double.tryParse(v.toString());
DateTime toDate(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
Map<String, dynamic> asMap(dynamic v) => v is Map<String, dynamic> ? v : <String, dynamic>{};
