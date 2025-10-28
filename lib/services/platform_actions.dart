// Expose platform-specific implementations via conditional imports
// Web uses `platform_actions_web.dart`; others use `platform_actions_stub.dart`.
import 'platform_actions_stub.dart'
    if (dart.library.html) 'platform_actions_web.dart' as impl;

void reloadPage() => impl.reloadPage();

void setHashUrl(String path) => impl.setHashUrl(path);
