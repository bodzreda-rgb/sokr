import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/gym_model.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/fitness_service.dart';
import '../../services/food_service.dart';
import '../../services/medical_service.dart';
import '../../services/pharmacy_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../doctors/doctor_details_page.dart';
import '../exercises/gyms_page.dart';
import '../food/restaurant_details_page.dart';
import '../pharmacy/pharmacy_details_page.dart';

// ======================== Edit Profile ========================
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: AuthService.instance.profile.value?.fullName);
  late final _phoneController = TextEditingController(text: AuthService.instance.profile.value?.phone);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // hena bn3dl el profile f Supabase
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(fullName: _nameController.text, phone: _phoneController.text);
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 24),
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

// ======================== Favorites ========================
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<({String type, String id, String name})>> _future;

  @override
  void initState() {
    super.initState();
    _future = MedicalService.getFavorites();
  }

  static const _icons = {
    'doctor': Icons.medical_services_rounded,
    'pharmacy': Icons.local_pharmacy_rounded,
    'gym': Icons.fitness_center_rounded,
    'restaurant': Icons.restaurant_rounded,
  };

  // bnfta7 el item el sa7 3la 7asab el type bta3o
  Future<void> _open(String type, String id) async {
    try {
      Widget? page;
      if (type == 'doctor') {
        final d = await DoctorService.getDoctorById(id);
        if (d != null) page = DoctorDetailsPage(doctor: d);
      } else if (type == 'pharmacy') {
        final list = await PharmacyService.getPharmacies();
        final p = list.where((p) => p.id == id).firstOrNull;
        if (p != null) page = PharmacyDetailsPage(pharmacy: p);
      } else if (type == 'restaurant') {
        final r = await FoodService.getRestaurantById(id);
        if (r != null) page = RestaurantDetailsPage(restaurant: r);
      } else if (type == 'gym') {
        final gyms = await FitnessService.getGyms();
        final g = gyms.where((g) => g.id == id).firstOrNull;
        if (g != null) page = GymDetailsPage(gym: g);
      }
      if (page != null && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
        setState(() => _future = MedicalService.getFavorites());
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: AsyncView<List<({String type, String id, String name})>>(
        future: _future,
        onRetry: () => setState(() => _future = MedicalService.getFavorites()),
        builder: (list) {
          if (list.isEmpty) {
            return const EmptyView(
                message: 'No favorites yet.\nTap the heart icon on a doctor, gym or restaurant.',
                icon: Icons.favorite_border_rounded);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final f = list[i];
              return AppCard(
                onTap: () => _open(f.type, f.id),
                child: Row(
                  children: [
                    IconTile(icon: _icons[f.type] ?? Icons.favorite_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(prettyStatus(f.type), style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
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

// ======================== Notifications ========================
// el notifications btt7seb men el data el 7a2e2eya (status el appointments w el orders)
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<List<(IconData, String, String)>> _load() async {
    final results = await Future.wait([
      DoctorService.getMyAppointments(),
      PharmacyService.getMyOrders(),
      FoodService.getMyOrders(),
    ]);
    final items = <(IconData, String, String)>[];
    for (final a in results[0] as List<AppointmentModel>) {
      items.add((
        Icons.event_note_rounded,
        'Appointment with ${a.doctorName} is ${prettyStatus(a.status)}',
        '${formatDate(a.date)} • ${formatTime(a.time)}',
      ));
    }
    for (final o in [...results[1] as List<OrderModel>, ...results[2] as List<OrderModel>]) {
      items.add((
        Icons.local_shipping_rounded,
        'Order from ${o.storeName} is ${prettyStatus(o.status)}',
        '${formatDate(o.createdAt)} • ${money(o.totalPrice)}',
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncView<List<(IconData, String, String)>>(
        future: _load(),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyView(message: 'No notifications', icon: Icons.notifications_none_rounded);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => AppCard(
              child: Row(
                children: [
                  IconTile(icon: items[i].$1, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(items[i].$3, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ======================== Settings ========================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.profile.value?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            onTap: () async {
              try {
                await AuthService.instance.resetPassword(email);
                if (context.mounted) showSnack(context, 'Password reset link sent to $email');
              } catch (e) {
                if (context.mounted) showSnack(context, friendlyError(e), error: true);
              }
            },
            child: const Row(
              children: [
                IconTile(icon: Icons.lock_reset_rounded, size: 40),
                SizedBox(width: 14),
                Expanded(child: Text('Change password (email link)', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Row(
              children: [
                AppLogo(iconOnly: true, height: 40),
                SizedBox(width: 14),
                Expanded(child: Text('SOKR - سكر v1.0.0\nGraduation Project')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const DisclaimerCard(),
        ],
      ),
    );
  }
}

// ======================== Gym Subscriptions ========================
// el patient byshof eshterakato f el gyms w y2dar y-cancel
class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  late Future<List<GymSubscriptionModel>> _future = FitnessService.getMySubscriptions();

  void _reload() => setState(() => _future = FitnessService.getMySubscriptions());

  Future<void> _cancel(GymSubscriptionModel s) async {
    if (!await confirmDialog(context, 'Cancel subscription', 'Cancel ${s.planName} at ${s.gymName}?')) return;
    try {
      await FitnessService.cancelSubscription(s.id);
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Subscriptions')),
      body: AsyncView<List<GymSubscriptionModel>>(
        future: _future,
        onRetry: _reload,
        builder: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              message: 'No subscriptions yet.\nOpen a gym from Exercises > Gyms to subscribe.',
              icon: Icons.card_membership_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = list[i];
              final status = s.status == 'active' && !s.isActive ? 'expired' : s.status;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconTile(icon: Icons.fitness_center_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.gymName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${s.planName} • ${money(s.price)}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        StatusBadge(
                          text: prettyStatus(status),
                          color: status == 'active' ? AppColors.success : AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InfoLine(
                      icon: Icons.date_range_rounded,
                      text: '${formatDate(s.startDate)}  →  ${formatDate(s.endDate)}',
                    ),
                    if (status == 'active')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _cancel(s),
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
