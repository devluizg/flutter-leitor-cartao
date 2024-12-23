import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> checkAndRequestPermissions() async {
    bool hasCamera = await requestCameraPermission();
    bool hasStorage = await requestStoragePermission();

    return hasCamera && hasStorage;
  }

  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    return await Permission.storage.status.isGranted;
  }
}
