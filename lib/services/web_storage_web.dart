// Web implementation backed by package:web localStorage
import 'package:web/web.dart' as web;

String? getItem(String key) {
  return web.window.localStorage.getItem(key);
}

void setItem(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

void removeItem(String key) {
  web.window.localStorage.removeItem(key);
}
