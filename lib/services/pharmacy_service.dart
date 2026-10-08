import '../models/medicine_model.dart';
import '../models/order_model.dart';
import '../models/pharmacy_model.dart';
import 'supabase_service.dart';

// kol el queries beta3t el saydaleyat w el adwya w el orders
class PharmacyService {
  static const _orderSelect =
      '*, profiles(full_name), pharmacies(name), medicine_order_items(*, medicines(name))';

  static OrderModel _toOrder(Map<String, dynamic> map) => OrderModel.fromMap(
        map,
        itemsKey: 'medicine_order_items',
        productKey: 'medicines',
        storeKey: 'pharmacies',
      );

  // hena bngeb kol el saydaleyat
  static Future<List<PharmacyModel>> getPharmacies() async {
    final data = await supabase
        .from('pharmacies')
        .select()
        .order('rating', ascending: false);
    return data.map(PharmacyModel.fromMap).toList();
  }

  // hena bngeb el adwya beta3t saydaleya mo3ayana
  static Future<List<MedicineModel>> getMedicines(String pharmacyId) async {
    final data = await supabase
        .from('medicines')
        .select()
        .eq('pharmacy_id', pharmacyId)
        .order('name');
    return data.map(MedicineModel.fromMap).toList();
  }

  // hena bn3ml el order: el RPC by7seb el total w y2ales el stock f el database
  static Future<void> placeOrder({
    required String pharmacyId,
    required String address,
    required String phone,
    required List<Map<String, dynamic>> items,
  }) async {
    await supabase.rpc('place_medicine_order', params: {
      'p_pharmacy': pharmacyId,
      'p_address': address,
      'p_phone': phone,
      'p_items': items,
    });
  }

  // hena el user byshof el orders beta3to bas
  static Future<List<OrderModel>> getMyOrders() async {
    final data = await supabase
        .from('medicine_orders')
        .select(_orderSelect)
        .eq('patient_id', currentUserId)
        .order('created_at', ascending: false);
    return data.map(_toOrder).toList();
  }

  // el admin byshof kol el orders
  static Future<List<OrderModel>> getAllOrders() async {
    final data = await supabase
        .from('medicine_orders')
        .select(_orderSelect)
        .order('created_at', ascending: false);
    return data.map(_toOrder).toList();
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    await supabase.from('medicine_orders').update({'status': status}).eq('id', id);
  }
}
