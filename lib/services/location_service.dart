import 'package:geolocator/geolocator.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  const LocationResult({this.latitude, this.longitude, this.errorMessage});

  bool get hasCoordinates => latitude != null && longitude != null;
}

class LocationService {
  static const _tag = 'LocationService';

  /// Attempts to get the current location with a timeout.
  /// Returns coordinates if successful, or an error message if not.
  /// Never throws — always returns a LocationResult.
  static Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        DebugLogger.warning(_tag, 'getCurrentLocation',
            'Location services disabled');
        return const LocationResult(
          errorMessage: 'Los servicios de ubicación están desactivados',
        );
      }

      // 2. Check/request permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          DebugLogger.warning(_tag, 'getCurrentLocation',
              'Location permission denied');
          return const LocationResult(
            errorMessage: 'Permiso de ubicación denegado',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        DebugLogger.warning(_tag, 'getCurrentLocation',
            'Location permission denied forever');
        return const LocationResult(
          errorMessage: 'Permiso de ubicación denegado permanentemente. Actívelo en Ajustes.',
        );
      }

      // 3. Get position with low accuracy (sufficient for farm location, saves battery)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      DebugLogger.info(_tag, 'getCurrentLocation',
          'Location obtained: ${position.latitude}, ${position.longitude}');

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      DebugLogger.error(_tag, 'getCurrentLocation',
          'Error getting location: $e');
      return LocationResult(
        errorMessage: 'No se pudo obtener la ubicación',
      );
    }
  }
}
