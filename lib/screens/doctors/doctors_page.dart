import 'package:flutter/material.dart';

import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/location_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/doctor_card.dart';
import 'book_appointment_page.dart';
import 'doctor_details_page.dart';

// da el "Find Doctors" screen: search + filter + list
class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  late Future<List<DoctorModel>> _future;
  String _query = '';
  String _specialization = 'All';
  String _sort = 'Rating';
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb el doctors men Supabase w bnrtbhom bel location law mawgood
  Future<List<DoctorModel>> _load() async {
    final doctors = await DoctorService.getDoctors();
    await LocationService.getPosition();
    return doctors;
  }

  // hena bn3ml filter 3la el specialization w el search w el sort
  List<DoctorModel> _filter(List<DoctorModel> all) {
    final q = _query.toLowerCase();
    var list = all.where((d) {
      final matchSearch = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q) ||
          d.clinicName.toLowerCase().contains(q);
      final matchSpec = _specialization == 'All' || d.specialization == _specialization;
      final matchAvailable = !_onlyAvailable || d.isAvailable;
      return matchSearch && matchSpec && matchAvailable;
    }).toList();

    switch (_sort) {
      case 'Experience':
        list.sort((a, b) => b.yearsExperience.compareTo(a.yearsExperience));
      case 'Price':
        list.sort((a, b) => a.consultationPrice.compareTo(b.consultationPrice));
      case 'Nearby':
        list = LocationService.sortByDistance(list, (d) => d.latitude, (d) => d.longitude);
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        actions: [
          // menu lel sort
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Rating', child: Text('Sort by Rating')),
              PopupMenuItem(value: 'Experience', child: Text('Sort by Experience')),
              PopupMenuItem(value: 'Price', child: Text('Sort by Price')),
              PopupMenuItem(value: 'Nearby', child: Text('Nearby first')),
            ],
          ),
        ],
      ),
      body: AsyncView<List<DoctorModel>>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (all) {
          // el specializations elly mawgoda fe3lan f el data
          final specs = ['All', ...{for (final d in all) d.specialization}];
          final doctors = _filter(all);
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                AppSearchBar(
                  hint: 'Search doctors, specialists...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 14),
                CategoryChips(
                  items: specs,
                  selected: _specialization,
                  onSelected: (v) => setState(() => _specialization = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available only'),
                  value: _onlyAvailable,
                  onChanged: (v) => setState(() => _onlyAvailable = v),
                ),
                if (doctors.isEmpty)
                  const EmptyView(message: 'No doctors found', icon: Icons.person_search_rounded),
                for (final d in doctors) ...[
                  DoctorCard(
                    doctor: d,
                    onViewProfile: () => _open(DoctorDetailsPage(doctor: d)),
                    onBook: () => _open(BookAppointmentPage(doctor: d)),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
