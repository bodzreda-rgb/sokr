import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/food_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/food_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/food_card.dart';
import '../pharmacy/orders_page.dart';
import 'dashboard_common.dart';

// da el Restaurant Dashboard (lw el role = restaurant)
class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _tab = 0;
  late Future<RestaurantModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = FoodService.getMyRestaurant();
  }

  void _reload() => setState(() => _future = FoodService.getMyRestaurant());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: AsyncView<RestaurantModel?>(
            future: _future,
            onRetry: _reload,
            builder: (r) {
              if (r == null) return const EmptyView(message: 'Restaurant not found');
              return IndexedStack(
                index: _tab,
                children: [
                  _MenuTab(restaurant: r),
                  OrdersList(
                    loader: () => FoodService.getRestaurantOrders(r.id),
                    onStatusChange: FoodService.updateOrderStatus,
                    showCustomer: true,
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Restaurant Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      StoreProfileForm(
                        initial: {
                          'name': r.name,
                          'description': r.description,
                          'address': r.address,
                          'phone': r.phone,
                          'image_url': r.imageUrl,
                          'latitude': r.latitude,
                          'longitude': r.longitude,
                          'is_open': r.isOpen,
                        },
                        onSave: (v) async {
                          await FoodService.updateRestaurant(r.id, v);
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
          NavigationDestination(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.store_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MenuTab extends StatefulWidget {
  final RestaurantModel restaurant;
  const _MenuTab({required this.restaurant});

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  late Future<List<FoodModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FoodService.getMenu(widget.restaurant.id);
  }

  void _reload() => setState(() => _future = FoodService.getMenu(widget.restaurant.id));

  // form wa7ed lel add w el edit beta3 el akl
  Future<void> _openForm([FoodModel? f]) async {
    final values = await showFormSheet(
      context,
      title: f == null ? 'Add Food' : 'Edit Food',
      fields: const {
        'name': 'Name',
        'category': 'Category',
        'description': 'Description',
        'price': 'Price (EGP)',
        'calories': 'Calories',
        'protein': 'Protein (g)',
        'carbs': 'Carbs (g)',
        'fats': 'Fats (g)',
        'image_url': 'Image URL (optional)',
      },
      initial: f == null
          ? const {}
          : {
              'name': f.name,
              'category': f.category,
              'description': f.description,
              'price': f.price.toStringAsFixed(2),
              'calories': '${f.calories}',
              'protein': '${f.protein}',
              'carbs': '${f.carbs}',
              'fats': '${f.fats}',
              'image_url': f.imageUrl ?? '',
            },
      numeric: const {'price', 'calories', 'protein', 'carbs', 'fats'},
      optional: const {'description', 'image_url'},
      dropdowns: const {'category': FoodModel.categories},
    );
    if (values == null || !mounted) return;
    int n(String k) => int.parse(values[k]!.split('.').first);
    final food = FoodModel(
      restaurantId: widget.restaurant.id,
      name: values['name']!,
      category: values['category']!,
      description: values['description']!,
      price: double.parse(values['price']!),
      calories: n('calories'),
      protein: n('protein'),
      carbs: n('carbs'),
      fats: n('fats'),
      imageUrl: values['image_url']!.isEmpty ? null : values['image_url'],
    );
    final ok = await runAction(
      context,
      () => f == null ? FoodService.addFood(food) : FoodService.updateFood(f.id, food.toMap()),
      f == null ? 'Food added' : 'Food updated',
    );
    if (ok) _reload();
  }

  Future<void> _delete(FoodModel f) async {
    if (!await confirmDialog(context, 'Delete food', 'Delete ${f.name}?')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => FoodService.deleteFood(f.id), 'Food deleted');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: AsyncView<List<FoodModel>>(
        future: _future,
        onRetry: _reload,
        builder: (menu) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            DashboardHeader(subtitle: widget.restaurant.name),
            const SizedBox(height: 18),
            StatsGrid(cards: [
              StatCard(icon: Icons.ramen_dining_rounded, label: 'Menu items', value: '${menu.length}'),
              StatCard(
                icon: widget.restaurant.isOpen ? Icons.storefront_rounded : Icons.store_mall_directory_outlined,
                label: 'Status',
                value: widget.restaurant.isOpen ? 'Open' : 'Closed',
                color: widget.restaurant.isOpen ? AppColors.success : AppColors.error,
              ),
            ]),
            const SectionHeader(title: 'Food Menu'),
            if (menu.isEmpty) const EmptyView(message: 'No food yet. Tap + to add.'),
            for (final f in menu) ...[
              FoodCard(
                food: f,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () => _openForm(f), icon: const Icon(Icons.edit_outlined, color: AppColors.primary)),
                    IconButton(onPressed: () => _delete(f), icon: const Icon(Icons.delete_outline, color: AppColors.error)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
