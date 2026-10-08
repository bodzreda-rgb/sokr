import 'model_helpers.dart';

// da el model beta3 el akla
class FoodModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String category;
  final String? imageUrl;
  final bool isHealthy;

  const FoodModel({
    this.id = '',
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.category,
    this.imageUrl,
    this.isHealthy = true,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map) => FoodModel(
        id: map['id'] as String,
        restaurantId: map['restaurant_id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        price: toDouble(map['price']),
        calories: toInt(map['calories']),
        protein: toInt(map['protein']),
        carbs: toInt(map['carbs']),
        fats: toInt(map['fats']),
        category: (map['category'] ?? 'Healthy') as String,
        imageUrl: map['image_url'] as String?,
        isHealthy: (map['is_healthy'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'category': category,
        'image_url': imageUrl,
        'is_healthy': isHealthy,
      };

  static const categories = [
    'Healthy',
    'Low Calories',
    'High Protein',
    'Low Carb',
    'Vegetarian',
    'Salads',
    'Breakfast',
  ];
}
