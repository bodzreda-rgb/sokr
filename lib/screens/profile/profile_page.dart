import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../doctors/appointments_page.dart';
import '../food/diet_plan_page.dart';
import '../medical/medical_records_page.dart';
import '../pharmacy/orders_page.dart';
import 'profile_extras.dart';

// da el Profile screen
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ValueListenableBuilder<UserModel?>(
        valueListenable: AuthService.instance.profile,
        builder: (context, user, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AppCard(
              gradient: const LinearGradient(colors: [Colors.white, AppColors.peach]),
              child: Column(
                children: [
                  InitialsAvatar(name: user?.fullName ?? '', imageUrl: user?.avatarUrl, radius: 44),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                  if ((user?.phone ?? '').isNotEmpty)
                    Text(user!.phone!, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ProfileOption(icon: Icons.edit_rounded, title: 'Edit Profile', onTap: () => _open(context, const EditProfilePage())),
            ProfileOption(icon: Icons.folder_shared_rounded, title: 'Medical Records', onTap: () => _open(context, const MedicalRecordsPage())),
            ProfileOption(icon: Icons.event_note_rounded, title: 'Appointments', onTap: () => _open(context, const AppointmentsPage())),
            ProfileOption(icon: Icons.receipt_long_rounded, title: 'Orders', onTap: () => _open(context, const MyOrdersPage())),
            ProfileOption(icon: Icons.restaurant_menu_rounded, title: 'My Diet Plan', onTap: () => _open(context, const MyDietPlanPage())),
            ProfileOption(icon: Icons.card_membership_rounded, title: 'Gym Subscriptions', onTap: () => _open(context, const MySubscriptionsPage())),
            ProfileOption(icon: Icons.favorite_rounded, title: 'Favorites', onTap: () => _open(context, const FavoritesPage())),
            ProfileOption(icon: Icons.notifications_rounded, title: 'Notifications', onTap: () => _open(context, const NotificationsPage())),
            ProfileOption(icon: Icons.settings_rounded, title: 'Settings', onTap: () => _open(context, const SettingsPage())),
            const LogoutOption(),
          ],
        ),
      ),
    );
  }
}

// row wa7ed f el options list
class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  const ProfileOption({super.key, required this.icon, required this.title, required this.onTap, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            IconTile(icon: icon, color: color, size: 40),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// zorar el logout (byst5dmo kol el roles)
class LogoutOption extends StatelessWidget {
  const LogoutOption({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileOption(
      icon: Icons.logout_rounded,
      title: 'Logout',
      color: AppColors.error,
      onTap: () async {
        if (await confirmDialog(context, 'Logout', 'Do you want to logout?')) {
          // el AuthGate hy-listen w yrg3 lel login lw7do
          await AuthService.instance.signOut();
          if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
    );
  }
}
