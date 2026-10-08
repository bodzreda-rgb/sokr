import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/diet_model.dart';
import '../../models/food_model.dart';
import '../../models/medical_models.dart';
import '../../services/doctor_portal_service.dart';
import '../../services/food_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../food/diet_plan_page.dart';

// el doctor byshof el patient: a5er qeyasat + diet plans + roshetta
class PatientDetailsPage extends StatefulWidget {
  final String doctorId;
  final String patientId;
  final String patientName;
  final String? patientPhone;

  const PatientDetailsPage({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Future<(HealthMetricModel?, List<DietPlanModel>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(HealthMetricModel?, List<DietPlanModel>)> _load() async {
    final metric = await DoctorPortalService.getPatientLatestMetric(widget.patientId);
    final plans = await DoctorPortalService.getPatientDietPlans(widget.patientId);
    return (metric, plans);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _newDiet() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DietPlanEditorPage(doctorId: widget.doctorId, patientId: widget.patientId),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _deleteDiet(DietPlanModel p) async {
    if (!await confirmDialog(context, 'Delete diet plan', 'Delete "${p.title}"?')) return;
    try {
      await DoctorPortalService.deleteDietPlan(p.id);
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  // el doctor yekteb roshetta
  Future<void> _addPrescription() async {
    final name = TextEditingController();
    final dosage = TextEditingController();
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Medicine name')),
            const SizedBox(height: 8),
            TextField(controller: dosage, decoration: const InputDecoration(labelText: 'Dosage')),
            const SizedBox(height: 8),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Instructions')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && dosage.text.trim().isNotEmpty) {
      try {
        await DoctorPortalService.addPrescription(
          doctorId: widget.doctorId,
          patientId: widget.patientId,
          medicineName: name.text.trim(),
          dosage: dosage.text.trim(),
          instructions: notes.text.trim(),
        );
        if (mounted) showSnack(context, 'Prescription added');
      } catch (e) {
        if (mounted) showSnack(context, friendlyError(e), error: true);
      }
    }
    for (final c in [name, dosage, notes]) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      body: AsyncView<(HealthMetricModel?, List<DietPlanModel>)>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final (m, plans) = data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppCard(
                child: Row(
                  children: [
                    InitialsAvatar(name: widget.patientName, radius: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          if (widget.patientPhone != null) Text(widget.patientPhone!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Latest Health Reading'),
              if (m == null)
                const Text('No readings yet', style: TextStyle(color: AppColors.textSecondary))
              else
                AppCard(
                  child: Column(
                    children: [
                      InfoLine(icon: Icons.favorite_rounded, text: 'Heart rate: ${m.heartRate ?? '--'} bpm'),
                      InfoLine(icon: Icons.bloodtype_rounded, text: 'Blood pressure: ${m.bloodPressure ?? '--'}'),
                      InfoLine(icon: Icons.water_drop_rounded, text: 'Blood sugar: ${m.bloodSugar ?? '--'} mg/dL'),
                      InfoLine(icon: Icons.monitor_weight_rounded, text: 'Weight: ${m.weight ?? '--'} kg'),
                      InfoLine(icon: Icons.calendar_today_rounded, text: 'Recorded: ${formatDate(m.recordedAt)}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _newDiet,
                      icon: const Icon(Icons.restaurant_menu_rounded),
                      label: const Text('New Diet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addPrescription,
                      icon: const Icon(Icons.medication_rounded),
                      label: const Text('Prescription'),
                    ),
                  ),
                ],
              ),
              const SectionHeader(title: 'Diet Plans'),
              if (plans.isEmpty) const Text('No diet plans yet', style: TextStyle(color: AppColors.textSecondary)),
              for (final p in plans) ...[
                DietPlanCard(plan: p, onDelete: () => _deleteDiet(p)),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ======================================================
// el doctor bey3ml diet plan: y5tar akl men el mata3em elly f el app
// ======================================================
class DietPlanEditorPage extends StatefulWidget {
  final String doctorId;
  final String patientId;
  const DietPlanEditorPage({super.key, required this.doctorId, required this.patientId});

  @override
  State<DietPlanEditorPage> createState() => _DietPlanEditorPageState();
}

class _DietPlanEditorPageState extends State<DietPlanEditorPage> {
  final _title = TextEditingController(text: 'Weekly diet plan');
  final _notes = TextEditingController();
  late final Future<List<FoodModel>> _foods = FoodService.getAllFood();
  final List<({FoodModel food, String meal})> _items = [];
  String _meal = 'Breakfast';
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _items.isEmpty) {
      showSnack(context, 'Add a title and at least one food', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await DoctorPortalService.createDietPlan(
        doctorId: widget.doctorId,
        patientId: widget.patientId,
        title: _title.text.trim(),
        notes: _notes.text.trim(),
        items: [for (final i in _items) (foodId: i.food.id, meal: i.meal)],
      );
      if (!mounted) return;
      showSnack(context, 'Diet plan saved');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(0, (s, i) => s + i.food.calories);
    return Scaffold(
      appBar: AppBar(title: const Text('New Diet Plan')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Save plan (${_items.length} foods • $total kcal)'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes for the patient')),
          // el akl elly et5tar
          if (_items.isNotEmpty) ...[
            const SectionHeader(title: 'Selected'),
            for (final i in _items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: StatusBadge(text: i.meal, color: AppColors.primary),
                title: Text(i.food.name),
                subtitle: Text('${i.food.calories} kcal'),
                trailing: IconButton(
                  onPressed: () => setState(() => _items.remove(i)),
                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
                ),
              ),
          ],
          const SectionHeader(title: 'Add food'),
          CategoryChips(items: DietPlanModel.meals, selected: _meal, onSelected: (v) => setState(() => _meal = v)),
          const SizedBox(height: 10),
          AppSearchBar(hint: 'Search food...', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 10),
          AsyncView<List<FoodModel>>(
            future: _foods,
            builder: (foods) {
              final list = foods.where((f) => f.name.toLowerCase().contains(_query.toLowerCase())).toList();
              return Column(
                children: [
                  for (final f in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.name),
                      subtitle: Text('${f.category} • ${f.calories} kcal • ${f.protein}g P'),
                      trailing: IconButton.filled(
                        tooltip: 'Add to $_meal',
                        onPressed: () => setState(() => _items.add((food: f, meal: _meal))),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
