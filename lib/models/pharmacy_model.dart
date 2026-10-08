import 'model_helpers.dart';

// da el model beta3 el saydaleya
class PharmacyModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? imageUrl;
  final bool isOpen;
  final double rating;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.imageUrl,
    required this.isOpen,
    required this.rating,
  });

  factory PharmacyModel.fromMap(Map<String, dynamic> map) => PharmacyModel(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        address: (map['address'] ?? '') as String,
        latitude: toDoubleOrNull(map['latitude']),
        longitude: toDoubleOrNull(map['longitude']),
        phone: map['phone'] as String?,
        imageUrl: map['image_url'] as String?,
        isOpen: (map['is_open'] ?? true) as bool,
        rating: toDouble(map['rating']),
      );
}
