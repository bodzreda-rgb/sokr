import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// ======================================================
// page wa7da generic lel admin: add / edit / delete le ay table
// badal ma n3ml page le kol table, bn3rf el fields f config (admin_tables.dart)
// ======================================================

// anwa3 el fields elly el form y2dar y3rdha
enum FieldType { text, multiline, integer, decimal, boolean, choice, weekday, reference, date, time, image }

// field wa7ed f el form
class AdminField {
  final String key; // esm el column f Supabase
  final String label;
  final FieldType type;
  final bool required;
  final List<String> options; // lel choice
  final String? refTable; // lel reference (foreign key)
  final String refLabel; // el column elly byt3rd men el table el tany

  const AdminField(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.options = const [],
    this.refTable,
    this.refLabel = 'name',
  });
}

// el config beta3 table wa7ed
class AdminTable {
  final String table;
  final String title;
  final IconData icon;
  final String titleKey; // el column elly byt3rd ka 3enwan f el list
  final List<String> subtitleKeys; // columns tanya btt3rd ta7t el 3enwan
  final List<AdminField> fields;
  final String orderBy;
  final bool canAdd;
  final bool canDelete;

  const AdminTable({
    required this.table,
    required this.title,
    required this.icon,
    required this.titleKey,
    this.subtitleKeys = const [],
    required this.fields,
    this.orderBy = 'created_at',
    this.canAdd = true,
    this.canDelete = true,
  });
}

const weekdayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// ======================== list page ========================
class AdminCrudPage extends StatefulWidget {
  final AdminTable config;
  const AdminCrudPage({super.key, required this.config});

  @override
  State<AdminCrudPage> createState() => _AdminCrudPageState();
}

class _AdminCrudPageState extends State<AdminCrudPage> {
  late Future<List<Map<String, dynamic>>> _future;
  // le kol reference field: map men id -> esm (masalan doctor_id -> "Dr. Sarah")
  final Map<String, Map<String, String>> _refs = {};
  String _query = '';

  AdminTable get c => widget.config;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb kol el rows + asamy el references
  Future<List<Map<String, dynamic>>> _load() async {
    for (final f in c.fields.where((f) => f.type == FieldType.reference)) {
      final rows = await supabase.from(f.refTable!).select('id, ${f.refLabel}');
      _refs[f.key] = {for (final r in rows) r['id'] as String: (r[f.refLabel] ?? '').toString()};
    }
    final data = await supabase.from(c.table).select().order(c.orderBy, ascending: c.orderBy != 'created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  void _reload() => setState(() => _future = _load());

  // bn7wl el value le text yt3rd (law reference bn3rd el esm badal el id)
  String _display(String key, dynamic value) {
    if (value == null) return '';
    if (_refs.containsKey(key)) return _refs[key]![value] ?? '';
    final field = c.fields.where((f) => f.key == key).firstOrNull;
    if (field?.type == FieldType.weekday) return weekdayNames[(value as num).toInt() % 7];
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminFormPage(config: c, row: row, refs: _refs)),
    );
    if (saved == true) _reload();
  }

  // hena el admin bymsa7 row
  Future<void> _delete(Map<String, dynamic> row) async {
    final name = _display(c.titleKey, row[c.titleKey]);
    if (!await confirmDialog(context, 'Delete', 'Delete "$name"? This cannot be undone.')) return;
    try {
      await supabase.from(c.table).delete().eq('id', row['id']);
      if (mounted) showSnack(context, 'Deleted');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      floatingActionButton: c.canAdd
          ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add))
          : null,
      body: AsyncView<List<Map<String, dynamic>>>(
        future: _future,
        onRetry: _reload,
        builder: (rows) {
          final q = _query.toLowerCase();
          final list = rows
              .where((r) => q.isEmpty || _display(c.titleKey, r[c.titleKey]).toLowerCase().contains(q))
              .toList();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                AppSearchBar(hint: 'Search ${c.title.toLowerCase()}...', onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 8),
                Text('${list.length} items', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (list.isEmpty) const EmptyView(message: 'Nothing here yet'),
                for (final r in list) ...[
                  AppCard(
                    onTap: () => _openForm(r),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        IconTile(icon: c.icon, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_display(c.titleKey, r[c.titleKey]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                c.subtitleKeys.map((k) => _display(k, r[k])).where((t) => t.isNotEmpty).join(' • '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                        if (c.canDelete)
                          IconButton(
                            onPressed: () => _delete(r),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ======================== add / edit form ========================
class AdminFormPage extends StatefulWidget {
  final AdminTable config;
  final Map<String, dynamic>? row; // null = add, mawgood = edit
  final Map<String, Map<String, String>> refs;

  const AdminFormPage({super.key, required this.config, this.row, required this.refs});

  @override
  State<AdminFormPage> createState() => _AdminFormPageState();
}

class _AdminFormPageState extends State<AdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  // controllers lel text fields, w map lel values el tanya (bool / dropdown)
  final Map<String, TextEditingController> _text = {};
  final Map<String, dynamic> _values = {};
  bool _saving = false;

  bool get _isEdit => widget.row != null;

  static const _textTypes = {
    FieldType.text, FieldType.multiline, FieldType.integer, FieldType.decimal, FieldType.date, FieldType.time,
    FieldType.image,
  };

  @override
  void initState() {
    super.initState();
    for (final f in widget.config.fields) {
      final v = widget.row?[f.key];
      if (_textTypes.contains(f.type)) {
        var text = v?.toString() ?? '';
        if (f.type == FieldType.time && text.length >= 5) text = text.substring(0, 5); // 10:30:00 -> 10:30
        _text[f.key] = TextEditingController(text: text);
      } else if (f.type == FieldType.boolean) {
        _values[f.key] = v ?? true;
      } else {
        _values[f.key] = v;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  // hena bn7wl el form le map w n-save f Supabase (insert aw update)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{};
    for (final f in widget.config.fields) {
      if (_textTypes.contains(f.type)) {
        final t = _text[f.key]!.text.trim();
        data[f.key] = t.isEmpty
            ? null
            : switch (f.type) {
                FieldType.integer => int.parse(t),
                FieldType.decimal => double.parse(t),
                _ => t,
              };
      } else {
        data[f.key] = _values[f.key];
      }
    }
    setState(() => _saving = true);
    try {
      final table = supabase.from(widget.config.table);
      if (_isEdit) {
        await table.update(data).eq('id', widget.row!['id']);
      } else {
        await table.insert(data);
      }
      if (!mounted) return;
      showSnack(context, _isEdit ? 'Saved' : 'Added');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validate(AdminField f, String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return f.required ? 'Required' : null;
    if (f.type == FieldType.integer && int.tryParse(t) == null) return 'Enter a whole number';
    if (f.type == FieldType.decimal && double.tryParse(t) == null) return 'Enter a number';
    if (f.type == FieldType.date && DateTime.tryParse(t) == null) return 'Format: YYYY-MM-DD';
    if (f.type == FieldType.time && !RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) return 'Format: HH:MM (e.g. 09:30)';
    return null;
  }

  // hena el admin by5tar sora men el gehaz w nrf3ha 3la Supabase Storage
  Future<void> _uploadImage(AdminField f) async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      setState(() => _saving = true);
      final url = await StorageService.uploadImage(await file.readAsBytes(), file.name, widget.config.table);
      setState(() => _text[f.key]!.text = url);
      if (mounted) showSnack(context, 'Photo uploaded');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // da widget wa7ed le kol field 3la 7asab el no3
  Widget _buildField(AdminField f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.type) {
      case FieldType.image:
        final url = _text[f.key]!.text;
        return Row(
          children: [
            NetworkImageBox(url: url.isEmpty ? null : url, fallbackIcon: Icons.image_outlined, height: 72, width: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _uploadImage(f),
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: Text(url.isEmpty ? 'Upload photo' : 'Change'),
                      ),
                      if (url.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _text[f.key]!.clear()),
                          child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case FieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _values[f.key] == true,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case FieldType.choice:
      case FieldType.weekday:
      case FieldType.reference:
        // el options: (value, label)
        final List<(Object, String)> options = switch (f.type) {
          FieldType.weekday => [for (var i = 0; i < 7; i++) (i, weekdayNames[i])],
          FieldType.reference => [for (final e in widget.refs[f.key]!.entries) (e.key, e.value)],
          _ => [for (final o in f.options) (o, o)],
        };
        final current = options.any((o) => o.$1 == _values[f.key]) ? _values[f.key] : null;
        return DropdownButtonFormField<Object?>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            // lw el field msh required, el admin y2dar y5tar "None"
            if (!f.required) const DropdownMenuItem<Object?>(value: null, child: Text('- None -')),
            for (final o in options) DropdownMenuItem<Object?>(value: o.$1, child: Text(o.$2, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => (f.required && v == null) ? 'Required' : null,
        );
      case FieldType.date:
        return TextFormField(
          controller: _text[f.key],
          readOnly: true,
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_rounded)),
          validator: (v) => _validate(f, v),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(_text[f.key]!.text) ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) _text[f.key]!.text = dbDate(picked);
          },
        );
      default:
        return TextFormField(
          controller: _text[f.key],
          maxLines: f.type == FieldType.multiline ? 3 : 1,
          keyboardType: (f.type == FieldType.integer || f.type == FieldType.decimal)
              ? const TextInputType.numberWithOptions(decimal: true, signed: true)
              : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: f.type == FieldType.time ? 'HH:MM' : null),
          validator: (v) => _validate(f, v),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_isEdit ? 'Edit' : 'Add'} ${widget.config.title}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final f in widget.config.fields) ...[
              _buildField(f),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
