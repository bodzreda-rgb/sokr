import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_portal_service.dart';
import '../../services/doctor_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_crud_page.dart' show weekdayNames;
import '../profile/profile_page.dart';
import 'patient_details_page.dart';

// ======================================================
// da el Doctor Portal (lw el role = doctor)
// el doctor: y-accept / reject el 7ogozat, y3dl el schedule,
// yshof el patients w y3mlhom diet plan
// ======================================================
class DoctorPortal extends StatefulWidget {
  const DoctorPortal({super.key});

  @override
  State<DoctorPortal> createState() => _DoctorPortalState();
}

class _DoctorPortalState extends State<DoctorPortal> {
  int _tab = 0;
  late Future<DoctorModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorPortalService.getMyDoctor();
  }

  void _reload() => setState(() => _future = DoctorPortalService.getMyDoctor());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: AsyncView<DoctorModel?>(
            future: _future,
            onRetry: _reload,
            builder: (doctor) {
              if (doctor == null) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyView(
                      message: 'Your account is not linked to a doctor profile yet.\nAsk the admin to link it.',
                      icon: Icons.link_off_rounded,
                    ),
                    Padding(padding: EdgeInsets.all(20), child: LogoutOption()),
                  ],
                );
              }
              return IndexedStack(
                index: _tab,
                children: [
                  _AppointmentsTab(doctor: doctor),
                  _ScheduleTab(doctor: doctor),
                  _PatientsTab(doctor: doctor),
                  _ProfileTab(doctor: doctor, onSaved: _reload),
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
          NavigationDestination(icon: Icon(Icons.event_note_rounded), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.schedule_rounded), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------- tab 1: el 7ogozat (accept / reject) ----------------
class _AppointmentsTab extends StatefulWidget {
  final DoctorModel doctor;
  const _AppointmentsTab({required this.doctor});

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  late Future<List<AppointmentModel>> _future;
  String _filter = 'Pending';

  @override
  void initState() {
    super.initState();
    _future = DoctorPortalService.getAppointments(widget.doctor.id);
  }

  void _reload() => setState(() => _future = DoctorPortalService.getAppointments(widget.doctor.id));

  // hena el doctor by-accept aw by-reject
  Future<void> _setStatus(AppointmentModel a, String status) async {
    try {
      await DoctorPortalService.setAppointmentStatus(a.id, status);
      if (mounted) showSnack(context, 'Appointment ${prettyStatus(status)}');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<AppointmentModel>>(
      future: _future,
      onRetry: _reload,
      builder: (all) {
        final list = all.where((a) => switch (_filter) {
              'Pending' => a.status == 'pending',
              'Accepted' => a.status == 'confirmed',
              _ => !a.isActive,
            }).toList();
        final pending = all.where((a) => a.status == 'pending').length;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  const AppLogo(iconOnly: true, height: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.doctor.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        Text('$pending pending requests', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CategoryChips(
                items: const ['Pending', 'Accepted', 'History'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty) const EmptyView(message: 'No appointments here', icon: Icons.event_busy_rounded),
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailsPage(
                          doctorId: widget.doctor.id,
                          patientId: a.patientId,
                          patientName: a.patientName,
                          patientPhone: a.patientPhone,
                        ),
                      ),
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
                        if (a.isActive) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (a.status == 'pending') ...[
                                TextButton(
                                  onPressed: () => _setStatus(a, 'rejected'),
                                  child: const Text('Deny', style: TextStyle(color: AppColors.error)),
                                ),
                                const SizedBox(width: 6),
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
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- tab 2: el schedule ----------------
class _ScheduleTab extends StatefulWidget {
  final DoctorModel doctor;
  const _ScheduleTab({required this.doctor});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  late Future<List<AvailabilityModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorService.getAvailability(widget.doctor.id);
  }

  void _reload() => setState(() => _future = DoctorService.getAvailability(widget.doctor.id));

  // hena el doctor bey-add ma3ad (youm + men + le)
  Future<void> _add() async {
    var day = 0;
    var start = const TimeOfDay(hour: 10, minute: 0);
    var end = const TimeOfDay(hour: 14, minute: 0);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add working hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: day,
                items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(weekdayNames[i]))],
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
    if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
      showSnack(context, 'End time must be after start time', error: true);
      return;
    }
    String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    try {
      await DoctorPortalService.addAvailability(
          doctorId: widget.doctor.id, day: day, start: fmt(start), end: fmt(end));
      if (mounted) showSnack(context, 'Working hours added');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _delete(AvailabilityModel s) async {
    try {
      await DoctorPortalService.deleteAvailability(s.id);
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
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
            const Text('My Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Patients can only book inside these hours.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (list.isEmpty) const EmptyView(message: 'No working hours yet. Tap + to add.', icon: Icons.schedule_rounded),
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
                        onPressed: () => _delete(s),
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

// ---------------- tab 3: el patients ----------------
class _PatientsTab extends StatefulWidget {
  final DoctorModel doctor;
  const _PatientsTab({required this.doctor});

  @override
  State<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<_PatientsTab> {
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorPortalService.getAppointments(widget.doctor.id);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<AppointmentModel>>(
      future: _future,
      onRetry: () => setState(() => _future = DoctorPortalService.getAppointments(widget.doctor.id)),
      builder: (all) {
        // kol patient mara wa7da bas
        final patients = <String, AppointmentModel>{};
        for (final a in all) {
          patients.putIfAbsent(a.patientId, () => a);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text('My Patients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Open a patient to see readings, write a prescription or make a diet plan.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (patients.isEmpty) const EmptyView(message: 'No patients yet', icon: Icons.people_outline),
            for (final a in patients.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsPage(
                        doctorId: widget.doctor.id,
                        patientId: a.patientId,
                        patientName: a.patientName,
                        patientPhone: a.patientPhone,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(name: a.patientName, radius: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (a.patientPhone != null)
                              Text(a.patientPhone!, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------- tab 4: profile ----------------
class _ProfileTab extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onSaved;
  const _ProfileTab({required this.doctor, required this.onSaved});

  // el doctor y3dl el data beta3to (bio, se3r el kashf, el 3eyada...)
  Future<void> _edit(BuildContext context) async {
    final bio = TextEditingController(text: doctor.bio);
    final price = TextEditingController(text: doctor.consultationPrice.toStringAsFixed(0));
    final clinic = TextEditingController(text: doctor.clinicName);
    final address = TextEditingController(text: doctor.clinicAddress);
    final phone = TextEditingController(text: doctor.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
              const SizedBox(height: 8),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Consultation price (EGP)')),
              const SizedBox(height: 8),
              TextField(controller: clinic, decoration: const InputDecoration(labelText: 'Clinic name')),
              const SizedBox(height: 8),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Clinic address')),
              const SizedBox(height: 8),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      try {
        await DoctorPortalService.updateMyDoctor(doctor.id, {
          'bio': bio.text.trim(),
          'consultation_price': double.tryParse(price.text.trim()) ?? doctor.consultationPrice,
          'clinic_name': clinic.text.trim(),
          'clinic_address': address.text.trim(),
          'phone': phone.text.trim(),
        });
        if (context.mounted) showSnack(context, 'Profile updated');
        onSaved();
      } catch (e) {
        if (context.mounted) showSnack(context, friendlyError(e), error: true);
      }
    }
    for (final c in [bio, price, clinic, address, phone]) {
      c.dispose();
    }
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
              InitialsAvatar(name: doctor.name, imageUrl: doctor.avatarUrl, radius: 40),
              const SizedBox(height: 10),
              Text(doctor.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(doctor.specialization, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('${money(doctor.consultationPrice)} • ${doctor.clinicName}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // el doctor y2fl / yfta7 el 7agz
        SwitchListTile(
          title: const Text('Accepting new bookings'),
          value: doctor.isAvailable,
          onChanged: (v) async {
            try {
              await DoctorPortalService.updateMyDoctor(doctor.id, {'is_available': v});
              onSaved();
            } catch (e) {
              if (context.mounted) showSnack(context, friendlyError(e), error: true);
            }
          },
        ),
        ProfileOption(icon: Icons.edit_rounded, title: 'Edit Profile', onTap: () => _edit(context)),
        const LogoutOption(),
      ],
    );
  }
}
