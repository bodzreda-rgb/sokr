import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/food_service.dart';
import '../../services/pharmacy_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// no3 el cart: adwya aw akl (nafs el screen lel etnen 3shan mnkararsh el code)
enum CartKind { medicine, food }

// da el Cart screen + Checkout
class CartPage extends StatefulWidget {
  final CartKind kind;
  const CartPage({super.key, required this.kind});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  CartService get _cart => widget.kind == CartKind.medicine ? CartService.medicines : CartService.food;

  @override
  void initState() {
    super.initState();
    _phoneController.text = AuthService.instance.profile.value?.phone ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // hena bn-save el order f Supabase (RPC by7seb el total w y2ales el stock)
  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.kind == CartKind.medicine) {
        await PharmacyService.placeOrder(
          pharmacyId: _cart.storeId!,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          items: _cart.toOrderItems(),
        );
      } else {
        await FoodService.placeOrder(
          restaurantId: _cart.storeId!,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          items: _cart.toOrderItems(),
        );
      }
      _cart.clear();
      if (!mounted) return;
      showSnack(context, 'Order placed successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind == CartKind.medicine ? 'Medicine Cart' : 'Food Cart'),
        actions: [
          IconButton(
            tooltip: 'Empty cart',
            onPressed: () => _cart.clear(),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) {
          if (_cart.items.isEmpty) {
            return const EmptyView(message: 'Your cart is empty', icon: Icons.shopping_bag_outlined);
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('From: ${_cart.storeName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                // el items
                for (final item in _cart.items) ...[
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(money(item.price), style: const TextStyle(color: AppColors.textSecondary)),
                              if (item.prescriptionRequired)
                                const Text('Prescription required',
                                    style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                            onPressed: () => _cart.changeQuantity(item, -1),
                            icon: const Icon(Icons.remove_circle_outline)),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        IconButton(
                            onPressed: () => _cart.changeQuantity(item, 1),
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_cart.needsPrescription)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'Prescription required: some items need a doctor prescription. '
                      'Upload it in Medical Records, the pharmacist will verify it before delivery.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                const SectionHeader(title: 'Checkout'),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                      hintText: 'Delivery Address', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Enter your address' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => (v == null || v.trim().length < 6) ? 'Enter your phone' : null,
                ),
                const SizedBox(height: 16),
                // order summary
                AppCard(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      for (final item in _cart.items)
                        Row(
                          children: [
                            Expanded(child: Text('${item.quantity} x ${item.name}')),
                            Text(money(item.total)),
                          ],
                        ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                          Text(money(_cart.total),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Cash on delivery (no online payment)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _confirmOrder,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Order'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
