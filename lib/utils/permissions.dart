import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request photo/gallery permission (storage for Android)
  static Future<bool> requestGalleryPermission() async {
    if (await Permission.photos.isGranted ||
        await Permission.photos.request().isGranted) {
      return true;
    } else if (await Permission.storage.isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // Request all necessary permissions at once
  static Future<void> requestAllPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.locationWhenInUse,
    ].request();
    // Request notification permission for Android 13+
    await Permission.notification.request();
  }
}
