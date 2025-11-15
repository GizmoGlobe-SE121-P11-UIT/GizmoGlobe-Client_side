import 'package:flutter/widgets.dart';

enum ProcessState {
  idle,
  success,
  failure,
  loading,
}

extension ProcessStateLocalization on ProcessState {
  String englishDescription() {
    switch (this) {
      case ProcessState.idle:
        return 'Idle';
      case ProcessState.success:
        return 'Success';
      case ProcessState.failure:
        return 'Failure';
      case ProcessState.loading:
        return 'Loading';
    }
  }

  String vietnameseDescription() {
    switch (this) {
      case ProcessState.idle:
        return 'Sẵn sàng';
      case ProcessState.success:
        return 'Thành công';
      case ProcessState.failure:
        return 'Thất bại';
      case ProcessState.loading:
        return 'Đang tải';
    }
  }

  String toLocalizedString() {
    try {
      final String lang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (lang.toLowerCase().startsWith('vi')) {
        return vietnameseDescription();
      }
    } catch (_) {}
    return englishDescription();
  }
}
