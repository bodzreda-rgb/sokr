import '../models/food_model.dart';
import '../models/order_model.dart';
import '../models/restaurant_model.dart';
import 'supabase_service.dart';

// kol el queries beta3t el mata3em el healthy w el akl
class FoodService {
  static const _orderSelect =
      '*, profiles(full_name), restaurants(name), food_order_items(*, food_items(name))';

  static OrderModel _toOrder(Map<String, dynamic> map) => OrderModel.fromMap(
        map,
        itemsKey: 'food_order_items',
        productKey: 'food_items',
        storeKey: 'restaurants',
      );

  static Future<List<RestaurantModel>> getRestaurants() async {
    final data = await supabase
        .from('restaurants')
        .select()
        .order('rating', ascending: false);
    return data.map(RestaurantModel.fromMap).toList();
  }

  static Future<RestaurantModel?> getRestaurantById(String id) async {
    final data =
        await supabase.from('restaurants').select().eq('id', id).maybeSingle();
    return data == null ? null : RestaurantModel.fromMap(data);
  }

  static Future<RestaurantModel?> getMyRestaurant() async {
    final data = await supabase
        .from('restaurants')
        .select()
        .eq('owner_id', currentUserId)
        .limit(1);
    return data.isEmpty ? null : RestaurantModel.fromMap(data.first);
  }

  static Future<void> updateRestaurant(String id, Map<String, dynamic> values) async {
    await supabase.from('restaurants').update(values).eq('id', id);
  }

  // el menu beta3 mat3am mo3ayan
  static Future<List<FoodModel>> getMenu(String restaurantId) async {
    final data = await supabase
        .from('food_items')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('name');
    return data.map(FoodModel.fromMap).toList();
  }

  // kol el akl el healthy (lel filter bel category)
  static Future<List<FoodModel>> getAllFood() async {
    final data = await supabase
        .from('food_items')
        .select()
        .eq('is_healthy', true)
        .order('calories');
    return data.map(FoodModel.fromMap).toList();
  }

  static Future<void> addFood(FoodModel food) async {
    await supabase.from('food_items').insert(food.toMap());
  }

  static Future<void> updateFood(String id, Map<String, dynamic> values) async {
    await supabase.from('food_items').update(values).eq('id', id);
  }

  static Future<void> deleteFood(String id) async {
    await supabase.from('food_items').delete().eq('id', id);
  }

  // order simulation (men 8er payment) - el total byt7seb f el database
  static Future<void> placeOrder({
    required String restaurantId,
    required String address,
    required String phone,
    required List<Map<String, dynamic>> items,
  }) async {
    await supabase.rpc('place_food_order', params: {
      'p_restaurant': restaurantId,
      'p_address': address,
      'p_phone': phone,
      'p_items': items,
    });
  }

  static Future<List<OrderModel>> getMyOrders() async {
    final data = await supabase
        .from('food_orders')
        .select(_orderSelect)
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(_toOrder).toList();
  }

  static Future<List<OrderModel>> getRestaurantOrders(String restaurantId) async {
    final data = await supabase
        .from('food_orders')
        .select(_orderSelect)
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return data.map(_toOrder).toList();
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    await supabase.from('food_orders').update({'status': status}).eq('id', id);
  }
}
