import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestPermissions() async {
    final locationPermission = await Permission.location.request();
    return locationPermission.isGranted;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<String> getAddressFromLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> parts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) parts.add(place.subAdministrativeArea!);
        
        if (parts.isEmpty && place.administrativeArea != null) parts.add(place.administrativeArea!);
        
        return parts.join(', ');
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
