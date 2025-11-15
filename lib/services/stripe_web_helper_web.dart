// Web-specific implementation
import 'dart:html' as html;

class StripeWebHelper {
  static String? getCurrentUrl() {
    return html.window.location.href;
  }

  static String? getBaseUrl() {
    final currentUrl = html.window.location.href;
    return currentUrl.split('#').first;
  }

  static Map<String, String> getUrlQueryParameters() {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters;
  }

  static String? getHashFragment() {
    return html.window.location.hash;
  }

  static void setSessionStorage(String key, String value) {
    html.window.sessionStorage[key] = value;
  }

  static String? getSessionStorage(String key) {
    return html.window.sessionStorage[key];
  }

  static void removeSessionStorage(String key) {
    html.window.sessionStorage.remove(key);
  }

  static void redirectTo(String url) {
    html.window.location.href = url;
  }
}
