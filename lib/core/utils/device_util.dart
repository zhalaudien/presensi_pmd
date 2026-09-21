import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtil {
  static String? _cachedDeviceInfo;

  static Future<String> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;
        final release = androidInfo.version.release;
        _cachedDeviceInfo = '$manufacturer $model (Android $release)';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceInfo = '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _cachedDeviceInfo = 'Linux (${linuxInfo.prettyName})';
      } else {
        _cachedDeviceInfo = 'Mobile Device (${Platform.operatingSystem})';
      }
    } catch (_) {
      _cachedDeviceInfo = 'Mobile Device';
    }

    return _cachedDeviceInfo!;
  }
}
