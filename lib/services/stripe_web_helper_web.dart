// Web-specific implementation
import 'package:web/web.dart' as web;

class StripeWebHelper {
  static String? getCurrentUrl() {
    return web.window.location.href;
  }

  static String? getBaseUrl() {
    final currentUrl = web.window.location.href;
    return currentUrl.split('#').first;
  }

  static Map<String, String> getUrlQueryParameters() {
    final uri = Uri.parse(web.window.location.href);
    return uri.queryParameters;
  }

  static String? getHashFragment() {
    return web.window.location.hash;
  }

  static void setSessionStorage(String key, String value) {
    web.window.sessionStorage.setItem(key, value);
  }

  static String? getSessionStorage(String key) {
    return web.window.sessionStorage.getItem(key);
  }

  static void removeSessionStorage(String key) {
    web.window.sessionStorage.removeItem(key);
  }

  static void redirectTo(String url) {
    web.window.location.href = url;
  }
}
