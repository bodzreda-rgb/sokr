import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/medical_models.dart';
import '../../services/doctor_service.dart';
import '../../widgets/common_widgets.dart';
import '../medical/medical_records_page.dart';
import '../profile/profile_page.dart';
import 'dashboard_common.dart';

// da el Doctor Dashboard (lw el role = doctor)
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _tab = 0;
  late Future<DoctorModel?> _doctorFuture;

  @override
  void initState() {
    super.initState();
    _doctorFuture = DoctorService.getMyDoctorProfile();
  }

  void _reloadDoctor() => setState(() => _doctorFuture = DoctorService.getMyDoctorProfile());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: AsyncView<DoctorModel?>(
            future: _doctorFuture,
            onRetry: _reloadDoctor,
            builder: (doctor) {
              if (doctor == null) return const EmptyView(message: 'Doctor profile not found');
              return IndexedStack(
                index: _tab,
                children: [
                  _AppointmentsTab(doctor: doctor),
                  _AvailabilityTab(doctor: doctor),
                  _DoctorProfileTab(doctor: doctor, onSaved: _reloadDoctor),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.schedule_rounded), label: 'Availability'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------- tab 1: appointments + stats ----------------
class _AppointmentsTab extends StatefulWidget {
  final DoctorModel doctor;
  const _AppointmentsTab({required this.doctor});

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorService.getDoctorAppointments(widget.doctor.id);
  }

  void _reload() => setState(() => _future = DoctorService.getDoctorAppointments(widget.doctor.id));

  // accept / reject / complete
  Future<void> _setStatus(AppointmentModel a, String status) async {
    final ok = await runAction(
        context, () => DoctorService.updateAppointmentStatus(a.id, status), 'Appointment ${prettyStatus(status)}');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<AppointmentModel>>(
      future: _future,
      onRetry: _reload,
      builder: (all) {
        final today = DateTime.now();
        final todays = all.where((a) => DateUtils.isSameDay(a.date, today) && a.isActive).toList();
        final pending = all.where((a) => a.status == 'pending').toList();
        final patients = {for (final a in all) a.patientId};
        final upcoming = all
            .where((a) => a.status == 'confirmed' && !a.date.isBefore(DateTime(today.year, today.month, today.day)))
            .toList();

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              DashboardHeader(subtitle: widget.doctor.specialization),
              const SizedBox(height: 18),
              StatsGrid(cards: [
                StatCard(icon: Icons.today_rounded, label: "Today's", value: '${todays.length}'),
                StatCard(icon: Icons.hourglass_top_rounded, label: 'Pending', value: '${pending.length}', color: AppColors.warning),
                StatCard(icon: Icons.people_alt_rounded, label: 'Patients', value: '${patients.length}', color: const Color(0xFF7C8CF8)),
                StatCard(icon: Icons.task_alt_rounded, label: 'Completed',
                    value: '${all.where((a) => a.status == 'completed').length}', color: AppColors.success),
              ]),
              const SectionHeader(title: 'Pending Requests'),
              if (pending.isEmpty) const Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)),
              for (final a in pending) _tile(a),
              const SectionHeader(title: "Today's Appointments"),
              if (todays.isEmpty) const Text('No appointments today', style: TextStyle(color: AppColors.textSecondary)),
              for (final a in todays) _tile(a),
              const SectionHeader(title: 'Upcoming (Confirmed)'),
              if (upcoming.isEmpty) const Text('Nothing upcoming', style: TextStyle(color: AppColors.textSecondary)),
              for (final a in upcoming) _tile(a),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(AppointmentModel a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientDetailsPage(doctor: widget.doctor, appointment: a)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(name: a.patientName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${formatDate(a.date)} • ${formatTime(a.time)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
                StatusBadge.forStatus(a.status),
              ],
            ),
            if (a.notes != null) ...[
              const SizedBox(height: 6),
              Text(a.notes!, style: const TextStyle(fontSize: 13)),
            ],
            if (a.status == 'pending' || a.status == 'confirmed') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (a.status == 'pending') ...[
                    TextButton(
                      onPressed: () => _setStatus(a, 'rejected'),
                      child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38)),
                      onPressed: () => _setStatus(a, 'confirmed'),
                      child: const Text('Accept'),
                    ),
                  ] else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38)),
                      onPressed: () => _setStatus(a, 'completed'),
                      child: const Text('Mark Completed'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- patient details + add prescription ----------------
class PatientDetailsPage extends StatefulWidget {
  final DoctorModel doctor;
  final AppointmentModel appointment;
  const PatientDetailsPage({super.key, required this.doctor, required this.appointment});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Future<(HealthMetricModel?, List<PrescriptionModel>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb a5er qeyasat el patient w el roshetat elly katabtaha
  Future<(HealthMetricModel?, List<PrescriptionModel>)> _load() async {
    final pid = widget.appointment.patientId;
    final metric = await DoctorService.getPatientLatestMetric(pid);
    final prescriptions = await DoctorService.getPrescriptionsForPatient(widget.doctor.id, pid);
    return (metric, prescriptions);
  }

  // el doctor bykteb roshetta lel patient (RLS by-check en 3ando appointment m3ah)
  Future<void> _addPrescription() async {
    final values = await showFormSheet(
      context,
      title: 'Add Prescription',
      fields: const {'medicine_name': 'Medicine name', 'dosage': 'Dosage', 'instructions': 'Instructions'},
      optional: const {'instructions'},
    );
    if (values == null || !mounted) return;
    final ok = await runAction(
      context,
      () => DoctorService.addPrescription(
        doctorId: widget.doctor.id,
        patientId: widget.appointment.patientId,
        medicineName: values['medicine_name']!,
        dosage: values['dosage']!,
        instructions: values['instructions'] ?? '',
      ),
      'Prescription added',
    );
    if (ok) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPrescription,
        icon: const Icon(Icons.add),
        label: const Text('Prescription'),
      ),
      body: AsyncView<(HealthMetricModel?, List<PrescriptionModel>)>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (data) {
          final (m, prescriptions) = data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              AppCard(
                child: Row(
                  children: [
                    InitialsAvatar(name: a.patientName, radius: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          if (a.patientPhone != null) Text(a.patientPhone!),
                          Text('${formatDate(a.date)} • ${formatTime(a.time)}',
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Latest Health Reading'),
              if (m == null)
                const Text('No readings shared yet', style: TextStyle(color: AppColors.textSecondary))
              else
                AppCard(
                  child: Column(
                    children: [
                      InfoLine(icon: Icons.favorite_rounded, text: 'Heart rate: ${m.heartRate ?? '--'} bpm'),
                      InfoLine(icon: Icons.bloodtype_rounded, text: 'Blood pressure: ${m.bloodPressure ?? '--'}'),
                      InfoLine(icon: Icons.water_drop_rounded, text: 'Blood sugar: ${m.bloodSugar ?? '--'} mg/dL'),
                      InfoLine(icon: Icons.monitor_weight_rounded, text: 'Weight: ${m.weight ?? '--'} kg'),
                    ],
                  ),
                ),
              const SectionHeader(title: 'Prescriptions'),
              if (prescriptions.isEmpty)
                const Text('No prescriptions yet', style: TextStyle(color: AppColors.textSecondary)),
              for (final p in prescriptions) ...[
                PrescriptionTile(p: p, subtitle: formatDate(p.createdAt)),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------- tab 2: availability ----------------
class _AvailabilityTab extends StatefulWidget {
  final DoctorModel doctor;
  const _AvailabilityTab({required this.doctor});

  @override
  State<_AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<_AvailabilityTab> {
  late Future<List<AvailabilityModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorService.getAvailability(widget.doctor.id);
  }

  void _reload() => setState(() => _future = DoctorService.getAvailability(widget.doctor.id));

  // hena el doctor bey-add ma3ad gedid (youm + men + le)
  Future<void> _add() async {
    int day = 0;
    TimeOfDay start = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 14, minute: 0);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add availability'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: day,
                items: [
                  for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(AvailabilityModel.dayNames[i])),
                ],
                onChanged: (v) => setLocal(() => day = v ?? 0),
              ),
              ListTile(
                title: const Text('From'),
                trailing: Text(start.format(context)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: start);
                  if (t != null) setLocal(() => start = t);
                },
              ),
              ListTile(
                title: const Text('To'),
                trailing: Text(end.format(context)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: end);
                  if (t != null) setLocal(() => end = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
      showSnack(context, 'End time must be after start time', error: true);
      return;
    }
    final saved = await runAction(
      context,
      () => DoctorService.addAvailability(doctorId: widget.doctor.id, dayOfWeek: day, start: fmt(start), end: fmt(end)),
      'Availability added',
    );
    if (saved) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: AsyncView<List<AvailabilityModel>>(
        future: _future,
        onRetry: _reload,
        builder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text('My Availability', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (list.isEmpty) const EmptyView(message: 'No availability yet. Tap + to add.', icon: Icons.schedule_rounded),
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.schedule_rounded, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${s.dayName}\n${formatTime(s.startTime)} - ${formatTime(s.endTime)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ok = await runAction(
                              context, () => DoctorService.deleteAvailability(s.id), 'Availability removed');
                          if (ok) _reload();
                        },
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- tab 3: doctor profile ----------------
class _DoctorProfileTab extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onSaved;
  const _DoctorProfileTab({required this.doctor, required this.onSaved});

  // hena el doctor by3dl el data beta3to
  Future<void> _edit(BuildContext context) async {
    final values = await showFormSheet(
      context,
      title: 'Update Profile',
      fields: const {
        'specialization': 'Specialization',
        'bio': 'Bio',
        'years_experience': 'Years of experience',
        'consultation_price': 'Consultation price (EGP)',
        'clinic_name': 'Clinic name',
        'clinic_address': 'Clinic address',
      },
      initial: {
        'specialization': doctor.specialization,
        'bio': doctor.bio,
        'years_experience': '${doctor.yearsExperience}',
        'consultation_price': doctor.consultationPrice.toStringAsFixed(0),
        'clinic_name': doctor.clinicName,
        'clinic_address': doctor.clinicAddress,
      },
      numeric: const {'years_experience', 'consultation_price'},
      optional: const {'bio', 'clinic_name', 'clinic_address'},
      dropdowns: const {'specialization': DoctorModel.specializations},
    );
    if (values == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => DoctorService.updateDoctor(doctor.id, {
        'specialization': values['specialization'],
        'bio': values['bio'],
        'years_experience': int.parse(values['years_experience']!.split('.').first),
        'consultation_price': double.parse(values['consultation_price']!),
        'clinic_name': values['clinic_name'],
        'clinic_address': values['clinic_address'],
      }),
      'Profile updated',
    );
    if (ok) onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AppCard(
          gradient: const LinearGradient(colors: [Colors.white, AppColors.peach]),
          child: Column(
            children: [
              InitialsAvatar(name: doctor.name, radius: 40),
              const SizedBox(height: 10),
              Text(doctor.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(doctor.specialization, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('${doctor.yearsExperience} years • ${money(doctor.consultationPrice)}'),
              Text(doctor.clinicName),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Available for booking'),
          value: doctor.isAvailable,
          onChanged: (v) async {
            final ok = await runAction(
                context, () => DoctorService.updateDoctor(doctor.id, {'is_available': v}), 'Availability updated');
            if (ok) onSaved();
          },
        ),
        const SizedBox(height: 8),
        ProfileOption(icon: Icons.edit_rounded, title: 'Update Profile', onTap: () => _edit(context)),
        const LogoutOption(),
      ],
    );
  }
}
