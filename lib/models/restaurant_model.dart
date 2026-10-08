import 'model_helpers.dart';

// da el model beta3 el mat3am el healthy
class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final double rating;
  final String? imageUrl;
  final bool isOpen;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.phone,
    required this.rating,
    this.imageUrl,
    required this.isOpen,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) => RestaurantModel(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        address: (map['address'] ?? '') as String,
        latitude: toDoubleOrNull(map['latitude']),
        longitude: toDoubleOrNull(map['longitude']),
        phone: map['phone'] as String?,
        rating: toDouble(map['rating']),
        imageUrl: map['image_url'] as String?,
        isOpen: (map['is_open'] ?? true) as bool,
      );
}
