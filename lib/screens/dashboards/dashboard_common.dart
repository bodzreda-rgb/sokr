import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../profile/profile_page.dart';

// header beta3 kol dashboard (salam + esm + logout)
class DashboardHeader extends StatelessWidget {
  final String subtitle;
  const DashboardHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService.instance.profile,
      builder: (context, user, _) => Row(
        children: [
          InitialsAvatar(name: user?.fullName ?? '', radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?.firstName ?? ''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// card soghayar lel statistics
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, color: color, size: 38),
          const SizedBox(height: 10),
          FittedBox(child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// grid responsive lel stat cards (2 aw 4 f el saf 3la 7asab el 3ard)
class StatsGrid extends StatelessWidget {
  final List<StatCard> cards;
  const StatsGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth > 600 ? 4 : 2;
      final w = (c.maxWidth - 12 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final card in cards) SizedBox(width: w, child: card)],
      );
    });
  }
}

// el form beta3 "store profile" (pharmacy / gym / restaurant) - reusable
class StoreProfileForm extends StatefulWidget {
  final Map<String, dynamic> initial;
  final bool showOpenSwitch;
  final Future<void> Function(Map<String, dynamic> values) onSave;

  const StoreProfileForm({super.key, required this.initial, required this.onSave, this.showOpenSwitch = true});

  @override
  State<StoreProfileForm> createState() => _StoreProfileFormState();
}

class _StoreProfileFormState extends State<StoreProfileForm> {
  static const _fields = {
    'name': 'Name',
    'description': 'Description',
    'address': 'Address',
    'phone': 'Phone',
    'image_url': 'Image URL (optional)',
    'latitude': 'Latitude (optional)',
    'longitude': 'Longitude (optional)',
  };
  late final Map<String, TextEditingController> _c = {
    for (final k in _fields.keys) k: TextEditingController(text: widget.initial[k]?.toString() ?? ''),
  };
  late bool _isOpen = (widget.initial['is_open'] ?? true) as bool;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_c['name']!.text.trim().isEmpty) {
      showSnack(context, 'Name is required', error: true);
      return;
    }
    final values = <String, dynamic>{
      for (final k in ['name', 'description', 'address', 'phone', 'image_url'])
        k: _c[k]!.text.trim().isEmpty ? null : _c[k]!.text.trim(),
      'latitude': double.tryParse(_c['latitude']!.text.trim()),
      'longitude': double.tryParse(_c['longitude']!.text.trim()),
      if (widget.showOpenSwitch) 'is_open': _isOpen,
    };
    setState(() => _saving = true);
    try {
      await widget.onSave(values);
      if (mounted) showSnack(context, 'Saved');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in _fields.entries) ...[
          TextField(
            controller: _c[e.key],
            maxLines: e.key == 'description' ? 3 : 1,
            keyboardType: (e.key == 'latitude' || e.key == 'longitude')
                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : TextInputType.text,
            decoration: InputDecoration(labelText: e.value),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.showOpenSwitch)
          SwitchListTile(
            title: const Text('Open now (availability)'),
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Profile'),
        ),
        const SizedBox(height: 16),
        const LogoutOption(),
      ],
    );
  }
}

// bottom sheet basit feh text fields (lel add / edit forms f el dashboards)
// btrg3 map b el values aw null law el user 3ml cancel
Future<Map<String, String>?> showFormSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> fields, // key -> label
  Map<String, String> initial = const {},
  Set<String> numeric = const {},
  Set<String> optional = const {},
  Map<String, List<String>> dropdowns = const {},
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FormSheet(
      title: title,
      fields: fields,
      initial: initial,
      numeric: numeric,
      optional: optional,
      dropdowns: dropdowns,
    ),
  );
}

class _FormSheet extends StatefulWidget {
  final String title;
  final Map<String, String> fields;
  final Map<String, String> initial;
  final Set<String> numeric;
  final Set<String> optional;
  final Map<String, List<String>> dropdowns;

  const _FormSheet({
    required this.title,
    required this.fields,
    required this.initial,
    required this.numeric,
    required this.optional,
    required this.dropdowns,
  });

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c = {
    for (final k in widget.fields.keys) k: TextEditingController(text: widget.initial[k] ?? ''),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(String key, String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return widget.optional.contains(key) ? null : 'Required';
    if (widget.numeric.contains(key) && (num.tryParse(text) == null || num.parse(text) < 0)) {
      return 'Enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final e in widget.fields.entries) ...[
                if (widget.dropdowns.containsKey(e.key))
                  DropdownButtonFormField<String>(
                    initialValue: widget.dropdowns[e.key]!.contains(_c[e.key]!.text)
                        ? _c[e.key]!.text
                        : widget.dropdowns[e.key]!.first,
                    decoration: InputDecoration(labelText: e.value),
                    items: widget.dropdowns[e.key]!
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => _c[e.key]!.text = v ?? '',
                  )
                else
                  TextFormField(
                    controller: _c[e.key],
                    maxLines: e.key == 'description' ? 3 : 1,
                    keyboardType: widget.numeric.contains(e.key)
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(labelText: e.value),
                    validator: (v) => _validate(e.key, v),
                  ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final values = {for (final e in _c.entries) e.key: e.value.text.trim()};
                  // el dropdown law el user mlmsosh, nst5dm awel option
                  for (final d in widget.dropdowns.entries) {
                    if (values[d.key]!.isEmpty) values[d.key] = d.value.first;
                  }
                  Navigator.pop(context, values);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// helper bysh8al ay action w y3rd success / error
Future<bool> runAction(BuildContext context, Future<void> Function() action, String successMessage) async {
  try {
    await action();
    if (context.mounted) showSnack(context, successMessage);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, friendlyError(e), error: true);
    return false;
  }
}
