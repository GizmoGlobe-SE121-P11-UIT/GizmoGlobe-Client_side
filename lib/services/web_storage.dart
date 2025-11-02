// Cross-platform wrapper for browser localStorage.
// Uses package:web on web, and stubbed no-ops elsewhere.
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart'
    as impl;

String? getItem(String key) => impl.getItem(key);

void setItem(String key, String value) => impl.setItem(key, value);

void removeItem(String key) => impl.removeItem(key);
