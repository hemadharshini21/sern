import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Default fallback position: Bangalore City Center (12.9716, 77.5946)
  static Position defaultPosition() {
    return Position(
      latitude: 12.9716,
      longitude: 77.5946,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Request permission + return current position safely.
  /// Instant fallback to default Bangalore GPS coordinates so it NEVER hangs or throws.
  static Future<Position> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 1),
        onTimeout: () => false,
      );
      if (!serviceEnabled) return defaultPosition();

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 1),
        onTimeout: () => LocationPermission.denied,
      );
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return defaultPosition();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => defaultPosition(),
      );
    } catch (_) {
      return defaultPosition();
    }
  }
}
