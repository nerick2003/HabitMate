// Stub for non-web platforms
class WebStorage {
  static String? getString(String key) {
    throw UnsupportedError('WebStorage not available on this platform');
  }

  static Future<void> setString(String key, String value) async {
    throw UnsupportedError('WebStorage not available on this platform');
  }

  static bool containsKey(String key) {
    throw UnsupportedError('WebStorage not available on this platform');
  }

  static Future<void> remove(String key) async {
    throw UnsupportedError('WebStorage not available on this platform');
  }
}

