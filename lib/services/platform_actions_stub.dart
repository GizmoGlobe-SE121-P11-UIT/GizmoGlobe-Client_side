// Fallback implementation for non-web platforms.
void reloadPage() {}

void setHashUrl(String path) {}

String getHashPath() => '';

void replaceHashUrl(String path) {}

void pushHashUrl(String path) {}

void clearHash() {}

void normalizeInitialUrlForHashStrategy() {}

void setUrlStrategyWeb() {
  // No-op on non-web platforms
}

void setHashFragment(String path) {}
