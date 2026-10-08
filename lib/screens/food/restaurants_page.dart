import 'package:flutter/material.dart';

import '../../models/food_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/food_service.dart';
import '../../services/location_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/food_card.dart';
import '../../widgets/restaurant_card.dart';
import '../pharmacy/cart_page.dart';
import '../pharmacy/pharmacies_page.dart';
import 'food_details_page.dart';
import 'restaurant_details_page.dart';

// da el Healthy Food screen: mata3em + akl b categories
class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late Future<(List<RestaurantModel>, List<FoodModel>)> _future;
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb el mata3em w el akl el healthy f nafs el wa2t
  Future<(List<RestaurantModel>, List<FoodModel>)> _load() async {
    final results = await Future.wait([FoodService.getRestaurants(), FoodService.getAllFood()]);
    await LocationService.getPosition();
    final restaurants = LocationService.sortByDistance(
        results[0] as List<RestaurantModel>, (r) => r.latitude, (r) => r.longitude);
    return (restaurants, results[1] as List<FoodModel>);
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthy Food'),
        actions: const [CartButton(kind: CartKind.food)],
      ),
      body: AsyncView<(List<RestaurantModel>, List<FoodModel>)>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (data) {
          final (restaurants, foods) = data;
          final q = _query.toLowerCase();
          final restaurantById = {for (final r in restaurants) r.id: r};

          // law category m5tara bn3rd el akl, 8er keda el mata3em
          final filteredFood = foods
              .where((f) =>
                  (_category == 'All' || f.category == _category) &&
                  (q.isEmpty || f.name.toLowerCase().contains(q)))
              .toList();
          final filteredRestaurants =
              restaurants.where((r) => q.isEmpty || r.name.toLowerCase().contains(q)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppSearchBar(hint: 'Search restaurants or food...', onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
              CategoryChips(
                items: const ['All', ...FoodModel.categories],
                selected: _category,
                onSelected: (v) => setState(() => _category = v),
              ),
              if (_category == 'All') ...[
                const SectionHeader(title: 'Healthy Restaurants'),
                if (filteredRestaurants.isEmpty) const EmptyView(message: 'No restaurants found'),
                for (final r in filteredRestaurants) ...[
                  RestaurantCard(restaurant: r, onTap: () => _open(RestaurantDetailsPage(restaurant: r))),
                  const SizedBox(height: 12),
                ],
              ],
              SectionHeader(title: _category == 'All' ? 'Popular Dishes' : _category),
              if (filteredFood.isEmpty) const EmptyView(message: 'No food found', icon: Icons.ramen_dining_outlined),
              for (final f in (_category == 'All' && q.isEmpty ? filteredFood.take(6) : filteredFood)) ...[
                FoodCard(
                  food: f,
                  onTap: () => _open(FoodDetailsPage(food: f, restaurant: restaurantById[f.restaurantId])),
                  onOrder: () => _open(FoodDetailsPage(food: f, restaurant: restaurantById[f.restaurantId])),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
