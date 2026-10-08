import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/doctor_model.dart';
import '../models/gym_model.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_model.dart';
import '../screens/doctors/doctor_details_page.dart';
import '../screens/exercises/gyms_page.dart';
import '../screens/pharmacy/pharmacy_details_page.dart';
import '../services/doctor_service.dart';
import '../services/fitness_service.dart';
import '../services/location_service.dart';
import '../services/pharmacy_service.dart';
import 'common_widgets.dart';

// slide wa7da f el carousel
class _Slide {
  final String tag; // "Top Doctor" / "Near You" / "Pharmacy Offer"
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final Color color;
  final Widget Function() page; // el page elly btfta7 lama ndos

  const _Slide(this.tag, this.title, this.subtitle, this.imageUrl, this.icon, this.color, this.page);
}

// ======================================================
// da el carousel beta3 el home (mesa7et e3lanat):
// a7san el doctors + el gyms el 2orayeba + adwya men el saydaleyat
// beylef lw7do kol 4 sawany
// ======================================================
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  late final Future<List<_Slide>> _future = _load();
  Timer? _timer;
  int _page = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // hena bngeb el data elly hat-et3rd f el e3lanat
  Future<List<_Slide>> _load() async {
    final results = await Future.wait([
      DoctorService.getDoctors(),
      FitnessService.getGyms(),
      PharmacyService.getPharmacies(),
    ]);
    await LocationService.getPosition();
    final doctors = (results[0] as List<DoctorModel>).take(3);
    final gyms = LocationService.sortByDistance(
        results[1] as List<GymModel>, (g) => g.latitude, (g) => g.longitude).take(3);
    final pharmacies = (results[2] as List<PharmacyModel>).where((p) => p.isOpen).toList();

    // dawa wa7ed men kol saydaleya maftou7a
    final medSlides = <_Slide>[];
    for (final p in pharmacies.take(2)) {
      final meds = await PharmacyService.getMedicines(p.id);
      final MedicineModel? m = meds.where((m) => m.stockQuantity > 0).firstOrNull;
      if (m == null) continue;
      medSlides.add(_Slide('Pharmacy', m.name, '${money(m.price)} at ${p.name}', m.imageUrl,
          Icons.medication_rounded, const Color(0xFF7C8CF8), () => PharmacyDetailsPage(pharmacy: p)));
    }

    final doctorSlides = <_Slide>[
      for (final d in doctors)
        _Slide('Top Doctor', d.name, '${d.specialization} • ★ ${d.rating.toStringAsFixed(1)}', d.avatarUrl,
            Icons.medical_services_rounded, AppColors.primary, () => DoctorDetailsPage(doctor: d)),
    ];
    final gymSlides = <_Slide>[
      for (final g in gyms)
        _Slide(
            'Gym Near You',
            g.name,
            LocationService.distanceText(g.latitude, g.longitude) ?? g.address,
            g.imageUrl,
            Icons.fitness_center_rounded,
            const Color(0xFFF08A5D),
            () => GymDetailsPage(gym: g)),
    ];
    // nkhalet el anwa3 m3 ba3d: doctor, gym, dawa, doctor, gym, ...
    final slides = <_Slide>[];
    for (var i = 0; i < 3; i++) {
      for (final list in [doctorSlides, gymSlides, medSlides]) {
        if (i < list.length) slides.add(list[i]);
      }
    }
    _startAutoPlay(slides.length);
    return slides;
  }

  void _startAutoPlay(int count) {
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Slide>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 170, child: LoadingView());
        }
        final slides = snap.data ?? [];
        if (slides.isEmpty) return const SizedBox.shrink(); // law fe error mnzhrsh 7aga
        return Column(
          children: [
            SizedBox(
              height: 170,
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _SlideCard(slide: slides[i]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // el no2at elly ta7t el carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _Slide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => slide.page())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [slide.color, slide.color.withValues(alpha: 0.65)],
          ),
          boxShadow: softShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(slide.tag,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Text(slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(slide.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  const SizedBox(height: 10),
                  const Text('View  →',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            NetworkImageBox(
              url: slide.imageUrl,
              fallbackIcon: slide.icon,
              height: 110,
              width: 100,
              radius: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
