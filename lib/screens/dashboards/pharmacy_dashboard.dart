import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medicine_model.dart';
import '../../models/order_model.dart';
import '../../models/pharmacy_model.dart';
import '../../services/pharmacy_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/medicine_card.dart';
import '../pharmacy/orders_page.dart';
import 'dashboard_common.dart';

// da el Pharmacy Dashboard (lw el role = pharmacist)
class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  int _tab = 0;
  late Future<PharmacyModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = PharmacyService.getMyPharmacy();
  }

  void _reload() => setState(() => _future = PharmacyService.getMyPharmacy());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: AsyncView<PharmacyModel?>(
            future: _future,
            onRetry: _reload,
            builder: (pharmacy) {
              if (pharmacy == null) return const EmptyView(message: 'Pharmacy not found');
              return IndexedStack(
                index: _tab,
                children: [
                  _OverviewTab(pharmacy: pharmacy),
                  _InventoryTab(pharmacy: pharmacy),
                  // el orders beta3t el saydaleya di bas (RLS)
                  OrdersList(
                    loader: () => PharmacyService.getPharmacyOrders(pharmacy.id),
                    onStatusChange: PharmacyService.updateOrderStatus,
                    showCustomer: true,
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Pharmacy Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      StoreProfileForm(
                        initial: {
                          'name': pharmacy.name,
                          'description': pharmacy.description,
                          'address': pharmacy.address,
                          'phone': pharmacy.phone,
                          'image_url': pharmacy.imageUrl,
                          'latitude': pharmacy.latitude,
                          'longitude': pharmacy.longitude,
                          'is_open': pharmacy.isOpen,
                        },
                        onSave: (v) async {
                          await PharmacyService.updatePharmacy(pharmacy.id, v);
                          _reload();
                        },
                      ),
                    ],
                  ),
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
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Medicines'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.store_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------- overview: statistics ----------------
class _OverviewTab extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _OverviewTab({required this.pharmacy});

  Future<(List<MedicineModel>, List<OrderModel>)> _load() async {
    final meds = await PharmacyService.getMedicines(pharmacy.id);
    final orders = await PharmacyService.getPharmacyOrders(pharmacy.id);
    return (meds, orders);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<(List<MedicineModel>, List<OrderModel>)>(
      future: _load(),
      builder: (data) {
        final (meds, orders) = data;
        final lowStock = meds.where((m) => m.stockQuantity < 10).toList();
        final revenue = orders.where((o) => o.status == 'completed').fold<double>(0, (s, o) => s + o.totalPrice);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            DashboardHeader(subtitle: pharmacy.name),
            const SizedBox(height: 18),
            StatsGrid(cards: [
              StatCard(icon: Icons.medication_rounded, label: 'Medicines', value: '${meds.length}'),
              StatCard(icon: Icons.pending_actions_rounded, label: 'Pending orders',
                  value: '${orders.where((o) => o.status == 'pending').length}', color: AppColors.warning),
              StatCard(icon: Icons.receipt_long_rounded, label: 'All orders', value: '${orders.length}', color: const Color(0xFF7C8CF8)),
              StatCard(icon: Icons.payments_rounded, label: 'Revenue', value: money(revenue), color: AppColors.success),
            ]),
            const SectionHeader(title: 'Low Stock (< 10)'),
            if (lowStock.isEmpty) const Text('All medicines are well stocked', style: TextStyle(color: AppColors.textSecondary)),
            for (final m in lowStock)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconTile(icon: Icons.warning_amber_rounded, color: AppColors.warning, size: 40),
                title: Text(m.name),
                trailing: Text('${m.stockQuantity} left', style: const TextStyle(color: AppColors.error)),
              ),
          ],
        );
      },
    );
  }
}

// ---------------- inventory: add / edit / delete / stock ----------------
class _InventoryTab extends StatefulWidget {
  final PharmacyModel pharmacy;
  const _InventoryTab({required this.pharmacy});

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  late Future<List<MedicineModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = PharmacyService.getMedicines(widget.pharmacy.id);
  }

  void _reload() => setState(() => _future = PharmacyService.getMedicines(widget.pharmacy.id));

  // form wa7ed lel add w el edit
  Future<void> _openForm([MedicineModel? m]) async {
    final values = await showFormSheet(
      context,
      title: m == null ? 'Add Medicine' : 'Edit Medicine',
      fields: const {
        'name': 'Name',
        'category': 'Category',
        'description': 'Description',
        'price': 'Price (EGP)',
        'stock_quantity': 'Stock quantity',
        'prescription_required': 'Prescription required',
        'image_url': 'Image URL (optional)',
      },
      initial: m == null
          ? const {'prescription_required': 'No'}
          : {
              'name': m.name,
              'category': m.category,
              'description': m.description,
              'price': m.price.toStringAsFixed(2),
              'stock_quantity': '${m.stockQuantity}',
              'prescription_required': m.prescriptionRequired ? 'Yes' : 'No',
              'image_url': m.imageUrl ?? '',
            },
      numeric: const {'price', 'stock_quantity'},
      optional: const {'description', 'image_url'},
      dropdowns: const {'prescription_required': ['No', 'Yes']},
    );
    if (values == null || !mounted) return;
    final medicine = MedicineModel(
      pharmacyId: widget.pharmacy.id,
      name: values['name']!,
      category: values['category']!,
      description: values['description']!,
      price: double.parse(values['price']!),
      stockQuantity: int.parse(values['stock_quantity']!.split('.').first),
      prescriptionRequired: values['prescription_required'] == 'Yes',
      imageUrl: values['image_url']!.isEmpty ? null : values['image_url'],
    );
    final ok = await runAction(
      context,
      () => m == null
          ? PharmacyService.addMedicine(medicine)
          : PharmacyService.updateMedicine(m.id, medicine.toMap()),
      m == null ? 'Medicine added' : 'Medicine updated',
    );
    if (ok) _reload();
  }

  // update stock b sor3a (+10 / -1)
  Future<void> _changeStock(MedicineModel m, int delta) async {
    final newStock = (m.stockQuantity + delta).clamp(0, 100000);
    final ok = await runAction(
        context, () => PharmacyService.updateMedicine(m.id, {'stock_quantity': newStock}), 'Stock updated');
    if (ok) _reload();
  }

  Future<void> _delete(MedicineModel m) async {
    if (!await confirmDialog(context, 'Delete medicine', 'Delete ${m.name}?')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => PharmacyService.deleteMedicine(m.id), 'Medicine deleted');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: AsyncView<List<MedicineModel>>(
        future: _future,
        onRetry: _reload,
        builder: (all) {
          final list = all.where((m) => m.name.toLowerCase().contains(_query.toLowerCase())).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              const Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              AppSearchBar(hint: 'Search medicines...', onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
              if (list.isEmpty) const EmptyView(message: 'No medicines yet. Tap + to add.'),
              for (final m in list) ...[
                MedicineCard(
                  medicine: m,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openForm(m);
                      if (v == 'add10') _changeStock(m, 10);
                      if (v == 'minus1') _changeStock(m, -1);
                      if (v == 'delete') _delete(m);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'add10', child: Text('Stock +10')),
                      PopupMenuItem(value: 'minus1', child: Text('Stock -1')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
