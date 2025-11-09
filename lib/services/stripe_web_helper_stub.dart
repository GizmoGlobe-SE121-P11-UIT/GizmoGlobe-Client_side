// Stub file for non-web platforms
class StripeWebHelper {
  static String? getCurrentUrl() => null;
  static String? getBaseUrl() => null;
  static void setSessionStorage(String key, String value) {}
  static String? getSessionStorage(String key) => null;
  static void removeSessionStorage(String key) {}
  static void redirectTo(String url) {}
  static Map<String, String> getUrlQueryParameters() => {};
  static String? getHashFragment() => null;
}
