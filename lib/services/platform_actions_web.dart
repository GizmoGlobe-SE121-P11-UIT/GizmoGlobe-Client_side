// Web-only implementations using package:web instead of deprecated dart:html
import 'package:web/web.dart' as web;

void reloadPage() {
  web.window.location.reload();
}

void setHashUrl(String path) {
  web.window.location.href = '#$path';
}
