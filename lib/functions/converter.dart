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
}