import 'package:flutter/material.dart';

import '../../models/pharmacy_model.dart';
import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/pharmacy_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/pharmacy_card.dart';
import 'cart_page.dart';
import 'pharmacy_details_page.dart';

// da el Pharmacies screen: nearby + search + open/closed
class PharmaciesPage extends StatefulWidget {
  const PharmaciesPage({super.key});

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage> {
  late Future<List<PharmacyModel>> _future;
  String _query = '';
  bool _openOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb el saydaleyat w bnrtbhom men el a2rab (law el location mawgood)
  Future<List<PharmacyModel>> _load() async {
    final list = await PharmacyService.getPharmacies();
    await LocationService.getPosition();
    return LocationService.sortByDistance(list, (p) => p.latitude, (p) => p.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
        actions: const [CartButton(kind: CartKind.medicine)],
      ),
      body: AsyncView<List<PharmacyModel>>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (all) {
          final q = _query.toLowerCase();
          final list = all
              .where((p) =>
                  (q.isEmpty || p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q)) &&
                  (!_openOnly || p.isOpen))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppSearchBar(hint: 'Search pharmacy...', onChanged: (v) => setState(() => _query = v)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open now only'),
                value: _openOnly,
                onChanged: (v) => setState(() => _openOnly = v),
              ),
              Text(LocationService.distanceKm(0, 0) == null ? 'All Pharmacies' : 'Nearby Pharmacies',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (list.isEmpty) const EmptyView(message: 'No pharmacies found', icon: Icons.local_pharmacy_outlined),
              for (final p in list) ...[
                PharmacyCard(
                  pharmacy: p,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => PharmacyDetailsPage(pharmacy: p))),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

// cart icon b3dad el items (bt-listen 3la el CartService)
class CartButton extends StatelessWidget {
  final CartKind kind;
  const CartButton({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final cart = kind == CartKind.medicine ? CartService.medicines : CartService.food;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => IconButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(kind: kind))),
        icon: Badge(
          isLabelVisible: cart.count > 0,
          label: Text('${cart.count}'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
      ),
    );
  }
}
