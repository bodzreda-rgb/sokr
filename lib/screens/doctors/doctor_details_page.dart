import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/medical_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'book_appointment_page.dart';

// da el Doctor Details screen
class DoctorDetailsPage extends StatefulWidget {
  final DoctorModel doctor;
  const DoctorDetailsPage({super.key, required this.doctor});

  @override
  State<DoctorDetailsPage> createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  late final Future<List<AvailabilityModel>> _availability;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _availability = DoctorService.getAvailability(widget.doctor.id);
    MedicalService.isFavorite('doctor', widget.doctor.id).then((v) {
      if (mounted) setState(() => _isFavorite = v);
    }).catchError((_) {});
  }

  // hena bn-add / remove el doctor men el favorites
  Future<void> _toggleFavorite() async {
    try {
      final fav = await MedicalService.toggleFavorite('doctor', widget.doctor.id);
      if (!mounted) return;
      setState(() => _isFavorite = fav);
      showSnack(context, fav ? 'Added to favorites' : 'Removed from favorites');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            gradient: const LinearGradient(colors: [Colors.white, AppColors.peach]),
            child: Column(
              children: [
                InitialsAvatar(name: d.name, imageUrl: d.avatarUrl, radius: 48),
                const SizedBox(height: 12),
                Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(d.specialization, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat(Icons.star_rounded, d.rating.toStringAsFixed(1), 'Rating'),
                    _stat(Icons.work_history_rounded, '${d.yearsExperience}+', 'Years'),
                    _stat(Icons.payments_rounded, money(d.consultationPrice), 'Fee'),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'About'),
          Text(d.bio.isEmpty ? 'No bio yet.' : d.bio,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SectionHeader(title: 'Clinic'),
          AppCard(
            child: Column(
              children: [
                InfoLine(icon: Icons.local_hospital_rounded, text: d.clinicName.isEmpty ? '-' : d.clinicName),
                const SizedBox(height: 8),
                InfoLine(icon: Icons.location_on_rounded, text: d.clinicAddress.isEmpty ? '-' : d.clinicAddress),
                if (d.phone != null) ...[
                  const SizedBox(height: 8),
                  InfoLine(icon: Icons.phone_rounded, text: d.phone!),
                ],
              ],
            ),
          ),
          const SectionHeader(title: 'Available Times'),
          AsyncView<List<AvailabilityModel>>(
            future: _availability,
            builder: (slots) {
              final active = slots.where((s) => s.isAvailable).toList();
              if (active.isEmpty) return const Text('No available times yet.');
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in active)
                    Chip(
                      label: Text(
                          '${s.dayName.substring(0, 3)}  ${formatTime(s.startTime)} - ${formatTime(s.endTime)}'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: d.isAvailable
                ? () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => BookAppointmentPage(doctor: d)))
                : null,
            icon: const Icon(Icons.event_available_rounded),
            label: Text(d.isAvailable ? 'Book Appointment' : 'Not available now'),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}
