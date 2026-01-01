// This file is not used on mobile - we use sqflite instead
class WebStorage {
  static String? getString(String key) {
    throw UnsupportedError('WebStorage not available on mobile');
  }

  static Future<void> setString(String key, String value) async {
    throw UnsupportedError('WebStorage not available on mobile');
  }

  static bool containsKey(String key) {
    throw UnsupportedError('WebStorage not available on mobile');
  }

  static Future<void> remove(String key) async {
    throw UnsupportedError('WebStorage not available on mobile');
  }
}

