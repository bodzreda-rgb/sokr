import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medicine_model.dart';
import '../../models/pharmacy_model.dart';
import '../../services/cart_service.dart';
import '../../services/pharmacy_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/medicine_card.dart';
import 'cart_page.dart';
import 'pharmacies_page.dart';

// da el Pharmacy Details screen: info + list el adwya
class PharmacyDetailsPage extends StatefulWidget {
  final PharmacyModel pharmacy;
  const PharmacyDetailsPage({super.key, required this.pharmacy});

  @override
  State<PharmacyDetailsPage> createState() => _PharmacyDetailsPageState();
}

class _PharmacyDetailsPageState extends State<PharmacyDetailsPage> {
  late Future<List<MedicineModel>> _future;
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _future = PharmacyService.getMedicines(widget.pharmacy.id);
  }

  // hena bn-add el dawa lel cart
  void _addToCart(MedicineModel m) {
    if (!widget.pharmacy.isOpen) {
      showSnack(context, 'This pharmacy is closed now', error: true);
      return;
    }
    final added = CartService.medicines.add(
      widget.pharmacy.id,
      widget.pharmacy.name,
      CartItem(
        id: m.id,
        name: m.name,
        price: m.price,
        maxQuantity: m.stockQuantity,
        prescriptionRequired: m.prescriptionRequired,
      ),
    );
    if (!added) {
      showSnack(context, 'Your cart has items from another pharmacy. Empty it first.', error: true);
      return;
    }
    showSnack(
      context,
      m.prescriptionRequired
          ? 'Added. Prescription required - you can upload it in Medical Records.'
          : '${m.name} added to cart',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pharmacy;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: const [CartButton(kind: CartKind.medicine)],
      ),
      body: AsyncView<List<MedicineModel>>(
        future: _future,
        onRetry: () => setState(() => _future = PharmacyService.getMedicines(p.id)),
        builder: (all) {
          final categories = ['All', ...{for (final m in all) m.category}];
          final q = _query.toLowerCase();
          final list = all
              .where((m) =>
                  (q.isEmpty || m.name.toLowerCase().contains(q)) &&
                  (_category == 'All' || m.category == _category))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppCard(
                gradient: const LinearGradient(colors: [Colors.white, AppColors.peach]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconTile(icon: Icons.local_pharmacy_rounded, size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.description.isEmpty ? p.name : p.description,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        StatusBadge(
                            text: p.isOpen ? 'Open' : 'Closed',
                            color: p.isOpen ? AppColors.success : AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InfoLine(icon: Icons.location_on_rounded, text: p.address),
                    if (p.phone != null) ...[
                      const SizedBox(height: 6),
                      InfoLine(icon: Icons.phone_rounded, text: p.phone!),
                    ],
                    const SizedBox(height: 6),
                    RatingText(rating: p.rating),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSearchBar(hint: 'Search medicines...', onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
              CategoryChips(items: categories, selected: _category, onSelected: (v) => setState(() => _category = v)),
              const SizedBox(height: 12),
              if (list.isEmpty) const EmptyView(message: 'No medicines found', icon: Icons.medication_outlined),
              for (final m in list) ...[
                MedicineCard(medicine: m, onAdd: () => _addToCart(m)),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
