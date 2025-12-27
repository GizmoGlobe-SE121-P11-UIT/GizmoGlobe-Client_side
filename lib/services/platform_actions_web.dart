// Web-only implementations using package:web instead of deprecated dart:html
import 'package:web/web.dart' as web;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void reloadPage() {
  // Force a hard reload to reset the entire app (not just auth instance)
  // This clears all state, cache, and reinitializes the entire Flutter app
  // Use location.reload() to force an immediate page reload
  // This will stop all further JavaScript/Dart execution
  web.window.location.reload();
}

void setUrlStrategyWeb() {
  setUrlStrategy(const HashUrlStrategy());
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

// Force-update the hash fragment without navigation or history push
void setHashFragment(String path) {
  web.window.location.hash = '#$path';
}

void clearHash() {
  // Clear the URL hash to avoid conflicts with OAuth providers that may use the fragment
  web.window.location.hash = '';
}

void normalizeInitialUrlForHashStrategy() {
  final loc = web.window.location;
  final path = loc.pathname;
  final hash = loc.hash;
  if (path != '/' && (hash.isEmpty || !hash.startsWith('#/'))) {
    final query = loc.search;
    final newUrl = '${loc.origin}/#$path$query';
    web.window.history.replaceState(null, '', newUrl);
  }
}
