import 'model_helpers.dart';

// model wa7ed lel orders (medicine orders w food orders nafs el shakl)
class OrderModel {
  final String id;
  final String storeName; // esm el saydaleya aw el mat3am
  final String patientName;
  final double totalPrice;
  final String status;
  final String deliveryAddress;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItem> items;

  const OrderModel({
    required this.id,
    required this.storeName,
    required this.patientName,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  // itemsKey = 'medicine_order_items' aw 'food_order_items'
  // productKey = 'medicines' aw 'food_items'
  // storeKey = 'pharmacies' aw 'restaurants'
  factory OrderModel.fromMap(
    Map<String, dynamic> map, {
    required String itemsKey,
    required String productKey,
    required String storeKey,
  }) {
    final store = asMap(map[storeKey]);
    final patient = asMap(map['profiles']);
    final rawItems = (map[itemsKey] as List?) ?? [];
    return OrderModel(
      id: map['id'] as String,
      storeName: (store['name'] ?? '') as String,
      patientName: (patient['full_name'] ?? '') as String,
      totalPrice: toDouble(map['total_price']),
      status: (map['status'] ?? 'pending') as String,
      deliveryAddress: (map['delivery_address'] ?? '') as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: toDate(map['created_at']),
      items: rawItems.map((e) {
        final item = asMap(e);
        final product = asMap(item[productKey]);
        return OrderItem(
          name: (product['name'] ?? 'Item') as String,
          quantity: toInt(item['quantity']),
          price: toDouble(item['price']),
        );
      }).toList(),
    );
  }

  static const statuses = [
    'pending',
    'preparing',
    'out_for_delivery',
    'completed',
    'cancelled',
  ];
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
