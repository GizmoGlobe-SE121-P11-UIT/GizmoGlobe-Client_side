// Platform-specific local guest service
// This file uses conditional imports to handle web vs mobile platforms

import 'local_guest_service.dart'
    if (dart.library.io) 'local_guest_service_mobile.dart';

// Re-export the service for consistent usage
export 'local_guest_service.dart'
    if (dart.library.io) 'local_guest_service_mobile.dart';
