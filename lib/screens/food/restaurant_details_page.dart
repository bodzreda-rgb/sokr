import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/food_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/food_service.dart';
import '../../services/medical_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/food_card.dart';
import '../pharmacy/cart_page.dart';
import '../pharmacy/pharmacies_page.dart';
import 'food_details_page.dart';

// da el Restaurant Details screen: info + food menu
class RestaurantDetailsPage extends StatefulWidget {
  final RestaurantModel restaurant;
  const RestaurantDetailsPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late Future<List<FoodModel>> _future;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _future = FoodService.getMenu(widget.restaurant.id);
    MedicalService.isFavorite('restaurant', widget.restaurant.id).then((v) {
      if (mounted) setState(() => _isFavorite = v);
    }).catchError((_) {});
  }

  Future<void> _toggleFavorite() async {
    try {
      final v = await MedicalService.toggleFavorite('restaurant', widget.restaurant.id);
      if (mounted) setState(() => _isFavorite = v);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not update favorites', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.error),
          ),
          const CartButton(kind: CartKind.food),
        ],
      ),
      body: AsyncView<List<FoodModel>>(
        future: _future,
        onRetry: () => setState(() => _future = FoodService.getMenu(r.id)),
        builder: (menu) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AppCard(
              gradient: const LinearGradient(colors: [Colors.white, AppColors.peach]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(icon: Icons.restaurant_rounded, color: Color(0xFFF08A5D), size: 52),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                      StatusBadge(
                          text: r.isOpen ? 'Open' : 'Closed',
                          color: r.isOpen ? AppColors.success : AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InfoLine(icon: Icons.location_on_rounded, text: r.address),
                  if (r.phone != null) InfoLine(icon: Icons.phone_rounded, text: r.phone!),
                  const SizedBox(height: 4),
                  RatingText(rating: r.rating),
                ],
              ),
            ),
            const SectionHeader(title: 'Food Menu'),
            if (menu.isEmpty) const EmptyView(message: 'No food items yet'),
            for (final f in menu) ...[
              FoodCard(
                food: f,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => FoodDetailsPage(food: f, restaurant: r))),
                onOrder: () => addFoodToCart(context, f, r),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
