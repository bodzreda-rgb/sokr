import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../services/doctor_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// el patient byshof kol el appointments beta3to (w y2dar y-cancel)
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DoctorService.getMyAppointments();
  }

  void _reload() => setState(() => _future = DoctorService.getMyAppointments());

  Future<void> _cancel(AppointmentModel a) async {
    if (!await confirmDialog(context, 'Cancel appointment', 'Cancel your appointment with ${a.doctorName}?')) {
      return;
    }
    try {
      await DoctorService.updateAppointmentStatus(a.id, 'cancelled');
      if (mounted) showSnack(context, 'Appointment cancelled');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: AsyncView<List<AppointmentModel>>(
        future: _future,
        onRetry: _reload,
        builder: (list) {
          if (list.isEmpty) {
            return const EmptyView(message: 'No appointments yet', icon: Icons.event_busy_rounded);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final a = list[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InitialsAvatar(name: a.doctorName, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.doctorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(a.specialization,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        StatusBadge.forStatus(a.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InfoLine(
                        icon: Icons.calendar_today_rounded,
                        text: '${formatDate(a.date)}  •  ${formatTime(a.time)}'),
                    if (a.notes != null) ...[
                      const SizedBox(height: 6),
                      InfoLine(icon: Icons.notes_rounded, text: a.notes!),
                    ],
                    if (a.isActive)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _cancel(a),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
