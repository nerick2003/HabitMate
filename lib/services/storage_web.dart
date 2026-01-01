import 'dart:html' as html;

class WebStorage {
  static String? getString(String key) {
    return html.window.localStorage[key];
  }

  static Future<void> setString(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  static bool containsKey(String key) {
    return html.window.localStorage.containsKey(key);
  }

  static Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
  }
}

