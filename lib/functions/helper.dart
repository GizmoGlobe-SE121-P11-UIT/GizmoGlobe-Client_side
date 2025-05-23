import 'converter.dart';

class Helper {
  static String getShortVoucherTimeWithEnd(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    if (startTime.isAfter(now)) {
      return "Starts ${Converter.getTimeUntilString(startTime)}";
    } else if (endTime.isAfter(now)) {
      return "Expires ${Converter.getTimeLeftString(endTime)}";
    } else {
      return "Expired";
    }
  }

  static String getShortVoucherTimeWithoutEnd(DateTime startTime) {
    final now = DateTime.now();
    if (startTime.isAfter(now)) {
      return "Starts ${Converter.getTimeUntilString(startTime)}";
    } else {
      return "Ongoing";
    }
  }
}