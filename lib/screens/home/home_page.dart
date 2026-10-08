import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/medical_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/health_card.dart';
import '../doctors/appointments_page.dart';
import '../health_info/health_info_page.dart';
import '../medical/health_status_page.dart';
import '../medical/medical_records_page.dart';
import '../pharmacy/pharmacies_page.dart';
import '../profile/profile_extras.dart';

// da el Home screen (shabah el "Dashboard" f el reference image)
class HomePage extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const HomePage({super.key, required this.onSwitchTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HealthMetricModel?> _metricFuture;
  late Future<AppointmentModel?> _appointmentFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // hena bngeb a5er qeyas se7y w a2rab appointment men Supabase
  void _load() {
    _metricFuture = MedicalService.getLatestMetric();
    _appointmentFuture = DoctorService.getUpcomingAppointment();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_metricFuture, _appointmentFuture]);
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _refresh());

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildHealthOverview(),
                const SectionHeader(title: 'Upcoming Appointment'),
                _buildUpcomingAppointment(),
                const SectionHeader(title: 'Quick Actions'),
                _buildQuickActions(),
                SectionHeader(
                  title: 'Health Tips',
                  action: 'View All',
                  onAction: () => _open(const HealthInfoPage()),
                ),
                _buildTips(),
                const SizedBox(height: 16),
                const DisclaimerCard(),
              ],
            ),
          ),
        ),
      ),
      // quick action button: yfta7 menu soghayara
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickSheet,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  // ---------------- header: greeting + notification + avatar ----------------
  Widget _buildHeader() {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService.instance.profile,
      builder: (context, user, _) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting,', style: const TextStyle(color: AppColors.textSecondary)),
                Text(user?.firstName ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _open(const NotificationsPage()),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onSwitchTab(4),
            child: InitialsAvatar(name: user?.fullName ?? '', imageUrl: user?.avatarUrl, radius: 22),
          ),
        ],
      ),
    );
  }

  // ---------------- health overview cards ----------------
  Widget _buildHealthOverview() {
    return FutureBuilder<HealthMetricModel?>(
      future: _metricFuture,
      builder: (context, snapshot) {
        final m = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        String v(Object? value) => loading ? '...' : (value?.toString() ?? '--');
        void openStatus() => _open(const HealthStatusPage());

        return Column(
          children: [
            // card kbeer lel heart rate zay el sora
            AppCard(
              onTap: openStatus,
              gradient: const LinearGradient(colors: [Colors.white, AppColors.pink]),
              child: Row(
                children: [
                  const IconTile(icon: Icons.favorite_rounded, color: AppColors.error, size: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Health Overview',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Heart Rate', style: TextStyle(color: AppColors.textSecondary)),
                        Text('${v(m?.heartRate)} bpm',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  if (snapshot.hasError)
                    const Icon(Icons.error_outline, color: AppColors.error)
                  else
                    const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 3 cards soghayara b LayoutBuilder 3shan ykono responsive
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 24) / 3;
              return Row(
                children: [
                  SizedBox(
                    width: w,
                    child: HealthCard(
                        icon: Icons.bloodtype_rounded,
                        title: 'Blood Pressure',
                        value: v(m?.bloodPressure),
                        unit: 'mmHg',
                        onTap: openStatus),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: w,
                    child: HealthCard(
                        icon: Icons.water_drop_rounded,
                        title: 'Blood Sugar',
                        value: v(m?.bloodSugar),
                        unit: 'mg/dL',
                        color: const Color(0xFF7C8CF8),
                        onTap: openStatus),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: w,
                    child: HealthCard(
                        icon: Icons.monitor_weight_rounded,
                        title: 'Weight',
                        value: v(m?.weight?.toStringAsFixed(0)),
                        unit: 'kg',
                        color: const Color(0xFFF08A5D),
                        onTap: openStatus),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  // ---------------- upcoming appointment ----------------
  Widget _buildUpcomingAppointment() {
    return FutureBuilder<AppointmentModel?>(
      future: _appointmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppCard(child: LinearProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppCard(child: Text(friendlyError(snapshot.error!)));
        }
        final a = snapshot.data;
        if (a == null) {
          return AppCard(
            onTap: () => widget.onSwitchTab(1),
            child: const Row(
              children: [
                IconTile(icon: Icons.event_available_rounded),
                SizedBox(width: 14),
                Expanded(child: Text('No upcoming appointments.\nTap to find a doctor.')),
              ],
            ),
          );
        }
        return AppCard(
          onTap: () => _open(const AppointmentsPage()),
          child: Row(
            children: [
              InitialsAvatar(name: a.doctorName, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.doctorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(a.specialization,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    InfoLine(
                      icon: Icons.calendar_today_rounded,
                      text: '${formatDate(a.date)}  •  ${formatTime(a.time)}',
                    ),
                  ],
                ),
              ),
              StatusBadge.forStatus(a.status),
            ],
          ),
        );
      },
    );
  }

  // ---------------- quick actions ----------------
  Widget _buildQuickActions() {
    final actions = [
      (Icons.medical_services_rounded, 'Find Doctors', AppColors.primary, () => widget.onSwitchTab(1)),
      (Icons.local_pharmacy_rounded, 'Pharmacies', const Color(0xFF7C8CF8), () => _open(const PharmaciesPage())),
      (Icons.fitness_center_rounded, 'Exercises', const Color(0xFFF08A5D), () => widget.onSwitchTab(2)),
      (Icons.restaurant_rounded, 'Healthy Food', AppColors.success, () => widget.onSwitchTab(3)),
      (Icons.folder_shared_rounded, 'Records', AppColors.warning, () => _open(const MedicalRecordsPage())),
      (Icons.monitor_heart_rounded, 'Health Status', AppColors.error, () => _open(const HealthStatusPage())),
      (Icons.event_note_rounded, 'Appointments', AppColors.primary, () => _open(const AppointmentsPage())),
      (Icons.menu_book_rounded, 'Health Info', const Color(0xFF7C8CF8), () => _open(const HealthInfoPage())),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (final a in actions)
          AppCard(
            onTap: a.$4,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTile(icon: a.$1, color: a.$3, size: 42),
                const SizedBox(height: 8),
                Text(a.$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------- health tips (static articles) ----------------
  Widget _buildTips() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: healthTopics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final t = healthTopics[i];
          return SizedBox(
            width: 220,
            child: AppCard(
              gradient: LinearGradient(colors: [Colors.white, t.color.withValues(alpha: 0.12)]),
              onTap: () => _open(HealthTopicPage(topic: t)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(icon: t.icon, color: t.color, size: 38),
                  const Spacer(),
                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(t.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // el bottom sheet beta3 el floating button
  void _showQuickSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget item(IconData icon, String text, VoidCallback onTap) => ListTile(
              leading: IconTile(icon: icon, size: 40),
              title: Text(text),
              onTap: () {
                Navigator.pop(sheetContext);
                onTap();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(Icons.event_available_rounded, 'Book Appointment', () => widget.onSwitchTab(1)),
              item(Icons.monitor_heart_rounded, 'Add Health Reading', () => _open(const HealthStatusPage(openAddDialog: true))),
              item(Icons.upload_file_rounded, 'Add Medical Record', () => _open(const MedicalRecordsPage())),
              item(Icons.local_pharmacy_rounded, 'Order Medicines', () => _open(const PharmaciesPage())),
            ],
          ),
        );
      },
    );
  }
}

