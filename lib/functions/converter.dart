import 'package:cloud_firestore/cloud_firestore.dart';

class Converter {
  static Timestamp toTimestamp(DateTime dateInput) {
    return Timestamp.fromDate(DateTime(dateInput.year, dateInput.month, dateInput.day));
  }

  static DateTime toDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  static BigInt toBigInt(String value) {
    return BigInt.parse(value);
  }

  static String formatNumber(BigInt number) {
    final String str = number.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      result = str[i] + result;
      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }
    return result;
  }

  static String formatDouble(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    } else if ((value * 10) % 1 == 0) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  static String getTimeLeftString(DateTime time) {
    final now = DateTime.now();
    if (time.isBefore(now)) return "Expired";
    final diff = time.difference(now);
    if (diff.inMinutes < 60) {
      return "in ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}";
    } else if (diff.inHours < 24) {
      return "in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}";
    } else {
      return "in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}";
    }
  }

  static String getTimeUntilString(DateTime time) {
    final now = DateTime.now();
    if (time.isBefore(now)) return "Started";
    final diff = time.difference(now);
    if (diff.inMinutes < 60) {
      return "in ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}";
    } else if (diff.inHours < 24) {
      return "in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}";
    } else {
      return "in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}";
    }
  }
}