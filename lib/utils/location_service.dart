import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latitudeKey = 'last_latitude';
  static const String _longitudeKey = 'last_longitude';
  static const String _timestampKey = 'last_location_timestamp';

  static Future<void> initializeLocation() async {
    try {
      // Get the last known location first
      Position? lastKnownPosition = await Geolocator.getLastKnownPosition();

      // If we have a recent last known position (less than 5 minutes old), use it
      if (lastKnownPosition != null) {
        final prefs = await SharedPreferences.getInstance();
        final lastTimestamp = prefs.getInt(_timestampKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - lastTimestamp < 5 * 60 * 1000) {
          // 5 minutes
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Save the position
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latitudeKey, position.latitude);
      await prefs.setDouble(_longitudeKey, position.longitude);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // If getting current position fails, try to use last known position
      Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_latitudeKey, lastKnownPosition.latitude);
        await prefs.setDouble(_longitudeKey, lastKnownPosition.longitude);
        await prefs.setInt(
          _timestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
  }

  static Future<Position?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (latitude != null && longitude != null) {
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt(_timestampKey) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    return null;
  }
}
