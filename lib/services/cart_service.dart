import 'package:flutter/foundation.dart';

// item wa7ed gowa el cart (dawa aw akla)
class CartItem {
  final String id;
  final String name;
  final double price;
  final int maxQuantity; // el stock (lel adwya)
  final bool prescriptionRequired;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.maxQuantity = 99,
    this.prescriptionRequired = false,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

// da el cart: by7fz el items f el memory le7d ma el user y3ml order
// el cart leh store wa7ed bas (saydaleya wa7da aw mat3am wa7ed)
class CartService extends ChangeNotifier {
  CartService._();

  // cart lel adwya w cart lel akl
  static final medicines = CartService._();
  static final food = CartService._();

  String? storeId;
  String storeName = '';
  final List<CartItem> items = [];

  int get count => items.fold(0, (sum, i) => sum + i.quantity);
  double get total => items.fold(0, (sum, i) => sum + i.total);
  bool get needsPrescription => items.any((i) => i.prescriptionRequired);

  // btrg3 false law el item men store tany (lazem el user yfaddy el cart el awel)
  bool add(String fromStoreId, String fromStoreName, CartItem item) {
    if (storeId != null && storeId != fromStoreId && items.isNotEmpty) {
      return false;
    }
    storeId = fromStoreId;
    storeName = fromStoreName;
    final existing = items.where((i) => i.id == item.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity < existing.maxQuantity) existing.quantity++;
    } else {
      items.add(item);
    }
    notifyListeners();
    return true;
  }

  void changeQuantity(CartItem item, int delta) {
    item.quantity = (item.quantity + delta).clamp(0, item.maxQuantity);
    if (item.quantity == 0) items.remove(item);
    notifyListeners();
  }

  void clear() {
    items.clear();
    storeId = null;
    storeName = '';
    notifyListeners();
  }

  // el shakl elly el RPC f Supabase mstanyo: [{"id": "...", "qty": 2}]
  List<Map<String, dynamic>> toOrderItems() =>
      items.map((i) => {'id': i.id, 'qty': i.quantity}).toList();
}
