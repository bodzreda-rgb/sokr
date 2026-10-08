import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medical_models.dart';
import '../../services/medical_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/health_card.dart';

// da el Health Status screen (heart ring + cards + weekly chart)
class HealthStatusPage extends StatefulWidget {
  final bool openAddDialog;
  const HealthStatusPage({super.key, this.openAddDialog = false});

  @override
  State<HealthStatusPage> createState() => _HealthStatusPageState();
}

class _HealthStatusPageState extends State<HealthStatusPage> {
  late Future<List<HealthMetricModel>> _future;
  String _chart = 'Steps';

  @override
  void initState() {
    super.initState();
    _future = MedicalService.getMetrics(limit: 7);
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addReading());
    }
  }

  void _reload() => setState(() => _future = MedicalService.getMetrics(limit: 7));

  Future<void> _addReading() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddMetricSheet(),
    );
    if (saved == true) {
      _reload();
      if (mounted) showSnack(context, 'Reading saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Status'),
        actions: [IconButton(onPressed: _addReading, icon: const Icon(Icons.add_circle_outline_rounded))],
      ),
      body: AsyncView<List<HealthMetricModel>>(
        future: _future,
        onRetry: _reload,
        builder: (metrics) {
          if (metrics.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyView(message: 'No health readings yet', icon: Icons.monitor_heart_outlined),
                ElevatedButton(onPressed: _addReading, child: const Text('  Add your first reading  ')),
              ],
            );
          }
          final latest = metrics.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _heartRing(latest),
              const SizedBox(height: 16),
              // grid responsive lel cards
              LayoutBuilder(builder: (context, c) {
                final w = (c.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                        width: w,
                        child: HealthCard(
                            icon: Icons.favorite_rounded,
                            title: 'Heart Rate',
                            value: '${latest.heartRate ?? '--'}',
                            unit: 'bpm',
                            color: AppColors.error)),
                    SizedBox(
                        width: w,
                        child: HealthCard(
                            icon: Icons.bloodtype_rounded,
                            title: 'Blood Pressure',
                            value: latest.bloodPressure ?? '--',
                            unit: 'mmHg')),
                    SizedBox(
                        width: w,
                        child: HealthCard(
                            icon: Icons.water_drop_rounded,
                            title: 'Blood Sugar',
                            value: '${latest.bloodSugar ?? '--'}',
                            unit: 'mg/dL',
                            color: const Color(0xFF7C8CF8))),
                    SizedBox(
                        width: w,
                        child: HealthCard(
                            icon: Icons.monitor_weight_rounded,
                            title: 'Weight',
                            value: latest.weight?.toStringAsFixed(1) ?? '--',
                            unit: 'kg',
                            color: const Color(0xFFF08A5D))),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _activity(Icons.directions_walk_rounded, 'Steps', '${latest.steps ?? '--'}', '')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _activity(
                          Icons.local_fire_department_rounded, 'Calories', '${latest.caloriesBurned ?? '--'}', 'kcal')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _activity(Icons.bedtime_rounded, 'Sleep', '${latest.sleepHours ?? '--'}', 'h')),
                ],
              ),
              const SectionHeader(title: 'Weekly Activity'),
              CategoryChips(
                items: const ['Steps', 'Calories', 'Sleep', 'Heart Rate'],
                selected: _chart,
                onSelected: (v) => setState(() => _chart = v),
              ),
              const SizedBox(height: 12),
              AppCard(child: SizedBox(height: 220, child: _weeklyChart(metrics.reversed.toList()))),
              const SizedBox(height: 16),
              const DisclaimerCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _heartRing(HealthMetricModel m) {
    final hr = m.heartRate ?? 0;
    // normal range taqreeban 60-100 (general info bas, msh diagnosis)
    final normal = hr >= 60 && hr <= 100;
    return AppCard(
      gradient: const LinearGradient(colors: [Colors.white, AppColors.pink]),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (hr / 140).clamp(0, 1).toDouble(),
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.peach,
                  color: AppColors.primary,
                ),
                const Center(child: Icon(Icons.favorite_rounded, color: AppColors.error, size: 54)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heart Rate', style: TextStyle(color: AppColors.textSecondary)),
                Text('${m.heartRate ?? '--'} bpm', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                if (m.heartRate != null)
                  StatusBadge(
                    text: normal ? 'Normal range' : 'Check with a doctor',
                    color: normal ? AppColors.success : AppColors.warning,
                  ),
                const SizedBox(height: 6),
                Text('Updated ${formatDate(m.recordedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activity(IconData icon, String label, String value, String unit) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              child: Text('$value $unit', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      );

  // hena el bar chart beta3 a5er 7 readings (fl_chart)
  Widget _weeklyChart(List<HealthMetricModel> list) {
    double valueOf(HealthMetricModel m) => switch (_chart) {
          'Calories' => (m.caloriesBurned ?? 0).toDouble(),
          'Sleep' => m.sleepHours ?? 0,
          'Heart Rate' => (m.heartRate ?? 0).toDouble(),
          _ => (m.steps ?? 0).toDouble(),
        };
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final values = list.map(valueOf).toList();
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY == 0) return const EmptyView(message: 'No data for this chart yet');

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= list.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(days[list[i].recordedAt.weekday % 7],
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i],
                width: 14,
                borderRadius: BorderRadius.circular(8),
                gradient: AppColors.primaryGradient,
              ),
            ]),
        ],
      ),
    );
  }
}

// form l-idafet qeyas se7y gedid
class AddMetricSheet extends StatefulWidget {
  const AddMetricSheet({super.key});

  @override
  State<AddMetricSheet> createState() => _AddMetricSheetState();
}

class _AddMetricSheetState extends State<AddMetricSheet> {
  // controller le kol field
  final _c = {
    for (final k in ['heart_rate', 'blood_pressure', 'blood_sugar', 'weight', 'height', 'steps', 'calories_burned', 'sleep_hours'])
      k: TextEditingController(),
  };
  bool _saving = false;

  static const _labels = {
    'heart_rate': 'Heart Rate (bpm)',
    'blood_pressure': 'Blood Pressure (e.g. 120/80)',
    'blood_sugar': 'Blood Sugar (mg/dL)',
    'weight': 'Weight (kg)',
    'height': 'Height (cm)',
    'steps': 'Steps',
    'calories_burned': 'Calories burned (kcal)',
    'sleep_hours': 'Sleep (hours)',
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  // hena bn-save el reading f Supabase (el fields el fadya btb2a null)
  Future<void> _save() async {
    final values = <String, dynamic>{};
    for (final e in _c.entries) {
      final text = e.value.text.trim();
      if (text.isEmpty) continue;
      if (e.key == 'blood_pressure') {
        if (!RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(text)) {
          showSnack(context, 'Blood pressure format: 120/80', error: true);
          return;
        }
        values[e.key] = text;
      } else {
        final n = num.tryParse(text);
        if (n == null || n < 0) {
          showSnack(context, 'Invalid number in ${_labels[e.key]}', error: true);
          return;
        }
        values[e.key] = ['weight', 'height', 'sleep_hours'].contains(e.key) ? n.toDouble() : n.round();
      }
    }
    if (values.isEmpty) {
      showSnack(context, 'Fill at least one field', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await MedicalService.addMetric(values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Health Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final e in _c.entries) ...[
              TextField(
                controller: e.value,
                keyboardType: e.key == 'blood_pressure'
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: _labels[e.key]),
              ),
              const SizedBox(height: 10),
            ],
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
