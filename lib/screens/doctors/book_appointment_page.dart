import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// da el Book Appointment screen: el user y5tar youm w wa2t
class BookAppointmentPage extends StatefulWidget {
  final DoctorModel doctor;
  const BookAppointmentPage({super.key, required this.doctor});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _notesController = TextEditingController();
  List<AvailabilityModel> _availability = [];
  Set<String> _booked = {};
  late DateTime _selectedDate;
  String? _selectedTime; // "10:30"
  bool _loading = true;
  bool _loadingSlots = false;
  bool _saving = false;
  String? _error;

  // el 14 youm el gayeen
  final _days = List.generate(14, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  @override
  void initState() {
    super.initState();
    _selectedDate = _days.first;
    _loadAvailability();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    try {
      _availability = await DoctorService.getAvailability(widget.doctor.id);
      // n5tar awel youm feh mawa3eed
      _selectedDate = _days.firstWhere((d) => _slotsFor(d).isNotEmpty, orElse: () => _days.first);
      await _loadBooked();
    } catch (e) {
      _error = friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  // hena bngeb el awqat el ma7goza f el youm el m5tar
  Future<void> _loadBooked() async {
    setState(() => _loadingSlots = true);
    try {
      _booked = await DoctorService.getBookedSlots(widget.doctor.id, dbDate(_selectedDate));
    } catch (_) {
      _booked = {};
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  // bn2sem el availability le slots kol 30 deqi2a
  List<String> _slotsFor(DateTime day) {
    final dow = day.weekday % 7; // Dart: Monday=1..Sunday=7 -> 0 = Sunday
    final slots = <String>[];
    for (final a in _availability.where((a) => a.dayOfWeek == dow && a.isAvailable)) {
      var minutes = _toMinutes(a.startTime);
      final end = _toMinutes(a.endTime);
      while (minutes + 30 <= end) {
        slots.add('${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}');
        minutes += 30;
      }
    }
    // law el youm el naharda, nshel el awqat elly fatet
    final now = DateTime.now();
    if (DateUtils.isSameDay(day, now)) {
      slots.removeWhere((s) => _toMinutes(s) <= now.hour * 60 + now.minute);
    }
    return slots;
  }

  int _toMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  // hena bn3ml insert lel appointment f Supabase
  Future<void> _confirm() async {
    if (_selectedTime == null) return;
    setState(() => _saving = true);
    try {
      await DoctorService.bookAppointment(
        doctorId: widget.doctor.id,
        date: dbDate(_selectedDate),
        time: '$_selectedTime:00',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Appointment booked! Waiting for doctor confirmation.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
      await _loadBooked();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          InitialsAvatar(name: d.name, imageUrl: d.avatarUrl),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                Text(d.specialization, style: const TextStyle(color: AppColors.textSecondary)),
                                RatingText(rating: d.rating),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Select Date'),
                    _buildDates(),
                    const SectionHeader(title: 'Select Time'),
                    _buildTimes(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Notes for the doctor (optional)'),
                    ),
                    const SizedBox(height: 16),
                    // el summary zay el sora
                    AppCard(
                      color: AppColors.background,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Appointment Summary', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          _summaryRow('Doctor', d.name),
                          _summaryRow('Specialization', d.specialization),
                          _summaryRow('Date & Time',
                              '${formatDate(_selectedDate)}${_selectedTime == null ? '' : ', ${formatTime(_selectedTime!)}'}'),
                          _summaryRow('Fee', money(d.consultationPrice)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_selectedTime == null || _saving) ? null : _confirm,
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Booking'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDates() {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = _days[i];
          final selected = DateUtils.isSameDay(day, _selectedDate);
          final hasSlots = _slotsFor(day).isNotEmpty;
          return GestureDetector(
            onTap: hasSlots
                ? () {
                    setState(() {
                      _selectedDate = day;
                      _selectedTime = null;
                    });
                    _loadBooked();
                  }
                : null,
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: softShadow,
              ),
              child: Opacity(
                opacity: hasSlots ? 1 : 0.35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(names[day.weekday % 7],
                        style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${day.day}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.text)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimes() {
    if (_loadingSlots) return const LoadingView();
    final slots = _slotsFor(_selectedDate);
    if (slots.isEmpty) {
      return const EmptyView(message: 'No available times on this day', icon: Icons.schedule_rounded);
    }
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 20) / 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final s in slots)
            SizedBox(
              width: w,
              child: _timeChip(s),
            ),
        ],
      );
    });
  }

  Widget _timeChip(String s) {
    final booked = _booked.contains(s);
    final selected = _selectedTime == s;
    return GestureDetector(
      onTap: booked ? null : () => setState(() => _selectedTime = s),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : (booked ? const Color(0xFFEDEFEF) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE3F1F0)),
        ),
        child: Text(
          formatTime(s),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (booked ? AppColors.textSecondary : AppColors.text),
            decoration: booked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      );
}
