import 'package:flutter/foundation.dart';

/// Global modal overlay tracker for web dialogs.
class ModalOverlayService {
  ModalOverlayService._();

  static final ValueNotifier<bool> isModalOpen = ValueNotifier<bool>(false);

  static T runWithModalFlag<T>(T Function() action) {
    isModalOpen.value = true;
    try {
      return action();
    } finally {
      // Do not reset here; callers should reset when dialog completes
    }
  }

  static void setOpen(bool open) {
    isModalOpen.value = open;
  }
}
