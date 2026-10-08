import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/food_service.dart';
import '../../services/pharmacy_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../pharmacy/orders_page.dart';
import '../profile/profile_page.dart';
import 'admin_crud_page.dart';
import 'admin_tables.dart';

// da el Admin Dashboard: el admin y2dar y-add / edit / delete kol 7aga f el app
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: const [
              _ManageTab(),
              // el admin y8yr status ay order
              OrdersList(
                loader: PharmacyService.getAllOrders,
                onStatusChange: PharmacyService.updateOrderStatus,
                showCustomer: true,
              ),
              OrdersList(
                loader: FoodService.getAllOrders,
                onStatusChange: FoodService.updateOrderStatus,
                showCustomer: true,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Manage'),
          NavigationDestination(icon: Icon(Icons.local_pharmacy_rounded), label: 'Med Orders'),
          NavigationDestination(icon: Icon(Icons.delivery_dining_rounded), label: 'Food Orders'),
        ],
      ),
    );
  }
}

class _ManageTab extends StatefulWidget {
  const _ManageTab();

  @override
  State<_ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<_ManageTab> {
  late Future<Map<String, int>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  // hena bn3d kol table fe kam row (statistics)
  Future<Map<String, int>> _loadStats() async {
    Future<int> count(String table) => supabase.from(table).count(CountOption.exact);
    final results = await Future.wait([
      count('profiles'),
      count('doctors'),
      count('appointments'),
      count('medicine_orders'),
      count('food_orders'),
    ]);
    return {
      'Users': results[0],
      'Doctors': results[1],
      'Appointments': results[2],
      'Medicine orders': results[3],
      'Food orders': results[4],
    };
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _stats = _loadStats());
        await _stats;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // header: logo + salam
          ValueListenableBuilder<UserModel?>(
            valueListenable: AuthService.instance.profile,
            builder: (context, user, _) => Row(
              children: [
                const AppLogo(iconOnly: true, height: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${user?.firstName ?? ''}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const Text('SOKR Admin Panel', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // statistics
          FutureBuilder<Map<String, int>>(
            future: _stats,
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in snap.data!.entries)
                    Chip(
                      avatar: const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
                      label: Text('${e.key}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              );
            },
          ),
          const SectionHeader(title: 'Manage App Data'),
          // grid feh kol el tables
          LayoutBuilder(builder: (context, c) {
            final perRow = c.maxWidth > 600 ? 4 : 2;
            final w = (c.maxWidth - 12 * (perRow - 1)) / perRow;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in allAdminTables)
                  SizedBox(
                    width: w,
                    child: AppCard(
                      onTap: () async {
                        await Navigator.push(
                            context, MaterialPageRoute(builder: (_) => AdminCrudPage(config: t)));
                        setState(() => _stats = _loadStats());
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(icon: t.icon, size: 42),
                          const SizedBox(height: 10),
                          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Text('Add • Edit • Delete',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 20),
          const LogoutOption(),
        ],
      ),
    );
  }
}
