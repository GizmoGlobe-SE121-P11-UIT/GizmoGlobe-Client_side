// Web-only implementations using package:web instead of deprecated dart:html
import 'package:web/web.dart' as web;

void reloadPage() {
  web.window.location.reload();
}

void setHashUrl(String path) {
  web.window.location.href = '#$path';
}

String getHashPath() {
  final hash = web.window.location.hash;
  return hash.startsWith('#') ? hash.substring(1) : hash;
}

void replaceHashUrl(String path) {
  web.window.history.replaceState(null, '', '#$path');
}

void pushHashUrl(String path) {
  web.window.history.pushState(null, '', '#$path');
}

void normalizeInitialUrlForHashStrategy() {
  final loc = web.window.location;
  final path = loc.pathname;
  final hash = loc.hash;
  if (path != '/' && (hash.isEmpty || !hash.startsWith('#/'))) {
    final query = loc.search;
    final newUrl = '${loc.origin}/#${path}${query}';
    web.window.history.replaceState(null, '', newUrl);
  }
}
