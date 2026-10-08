import 'package:geolocator/geolocator.dart';

// service basit lel location: law el user rafad el permission bnrg3 null bas (mafish crash)
class LocationService {
  static Position? _position;
  static bool _asked = false;

  // hena bngeb makan el user mara wa7da w n7fzo
  static Future<Position?> getPosition() async {
    if (_position != null || _asked) return _position;
    _asked = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      _position = null;
    }
    return _position;
  }

  // el masafa bel kilometer ben el user w makan mo3ayan
  static double? distanceKm(double? lat, double? lng) {
    final p = _position;
    if (p == null || lat == null || lng == null) return null;
    return Geolocator.distanceBetween(p.latitude, p.longitude, lat, lng) / 1000;
  }

  static String? distanceText(double? lat, double? lng) {
    final km = distanceKm(lat, lng);
    if (km == null) return null;
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  // bnrtb el list men el a2rab lel ab3ad (law el location mawgood)
  static List<T> sortByDistance<T>(
      List<T> items, double? Function(T) lat, double? Function(T) lng) {
    if (_position == null) return items;
    final sorted = [...items];
    sorted.sort((a, b) {
      final da = distanceKm(lat(a), lng(a)) ?? double.infinity;
      final db = distanceKm(lat(b), lng(b)) ?? double.infinity;
      return da.compareTo(db);
    });
    return sorted;
  }
}
