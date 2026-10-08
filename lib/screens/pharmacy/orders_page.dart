import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/food_service.dart';
import '../../services/pharmacy_service.dart';
import '../../widgets/common_widgets.dart';

// el user byshof el orders beta3to (adwya + akl) f tabs
class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Medicines'), Tab(text: 'Food')],
          ),
        ),
        body: TabBarView(
          children: [
            OrdersList(loader: PharmacyService.getMyOrders),
            OrdersList(loader: FoodService.getMyOrders),
          ],
        ),
      ),
    );
  }
}

// list orders reusable (lel patient w lel dashboards)
// law onStatusChange mawgooda, bn3rd dropdown l-ta8yeer el status
class OrdersList extends StatefulWidget {
  final Future<List<OrderModel>> Function() loader;
  final Future<void> Function(String orderId, String status)? onStatusChange;
  final bool showCustomer;

  const OrdersList({super.key, required this.loader, this.onStatusChange, this.showCustomer = false});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  late Future<List<OrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() => setState(() => _future = widget.loader());

  Future<void> _changeStatus(OrderModel o, String status) async {
    try {
      await widget.onStatusChange!(o.id, status);
      if (mounted) showSnack(context, 'Order status updated');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not update order', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<OrderModel>>(
      future: _future,
      onRetry: _reload,
      builder: (orders) {
        if (orders.isEmpty) return const EmptyView(message: 'No orders yet', icon: Icons.receipt_long_outlined);
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final o = orders[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.showCustomer ? o.patientName : o.storeName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        StatusBadge.forStatus(o.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formatDate(o.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final item in o.items)
                      Text('${item.quantity} x ${item.name}  •  ${money(item.price * item.quantity)}',
                          style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    InfoLine(icon: Icons.location_on_outlined, text: o.deliveryAddress),
                    if (o.phone != null) InfoLine(icon: Icons.phone_outlined, text: o.phone!),
                    if (o.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(o.notes!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text('Total: ${money(o.totalPrice)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const Spacer(),
                        if (widget.onStatusChange != null)
                          DropdownButton<String>(
                            value: o.status,
                            underline: const SizedBox(),
                            items: OrderModel.statuses
                                .map((s) => DropdownMenuItem(value: s, child: Text(prettyStatus(s))))
                                .toList(),
                            onChanged: (s) {
                              if (s != null && s != o.status) _changeStatus(o, s);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
