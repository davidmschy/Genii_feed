import 'package:flutter_twitter_clone/helper/utility.dart'; // For cprint
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Handles location permission.
  /// Returns true if permission is granted, false otherwise.
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      cprint('Location services are disabled. Please enable the services');
      // Optionally, could show a dialog to user to enable services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        cprint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      cprint('Location permissions are permanently denied, we cannot request permissions.');
      // Optionally, guide user to app settings.
      return false;
    }

    // When we reach here, permissions are granted
    return true;
  }

  /// Gets current geographic coordinates using geolocator.
  /// Returns Position object or null if fails.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return null;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium); // Medium accuracy for faster response & less battery
      return position;
    } catch (e) {
      cprint('Error getting current position: $e', errorIn: "getCurrentPosition");
      return null;
    }
  }

  /// Gets ZIP code from latitude and longitude using geocoding.
  /// Returns String (ZIP code) or null if fails.
  Future<String?> getZipCodeFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          cprint("Found ZIP Code: ${placemark.postalCode}");
          return placemark.postalCode;
        } else {
          cprint("ZIP Code not found in placemark for $lat, $lng", warningIn: "getZipCodeFromCoordinates");
        }
      } else {
        cprint("No placemarks found for $lat, $lng", warningIn: "getZipCodeFromCoordinates");
      }
    } catch (e) {
      cprint('Error getting ZIP code from coordinates: $e', errorIn: "getZipCodeFromCoordinates");
    }
    return null;
  }
}
