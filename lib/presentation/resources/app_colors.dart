import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);

  // Màu pie chart.
  static List<Color> pieChartCategoryColors = [
    const Color(0xFFcf3f1f).withOpacity(0.5),
    const Color(0xFF23cc1f),
    const Color(0xFF2981d9),
    const Color(0xFFe3b82b),
    const Color(0xFFe68429),
    const Color(0xFFcf3f1f),
    const Color(0xFFbf137a),
    const Color(0xFF621bbf),
    const Color(0xff2fcc78)
  ];
  static Color pieChartExtendedCategoryColor = Colors.grey;
  static Color boxBackgroundColor = Colors.grey.shade900;
  // Màu bar chart.
  static Color incomeBarColor = const Color(0xff53fdd7);
  static Color expenseBarColor = const Color(0xffff5182);
  static Color backgroundColor = Colors.grey.shade100;
  static Color foregroundColor = Colors.black;

  static Color expenseColor = Colors.red.shade600;
  static Color incomeColor = const Color(0xFF1bf176);

}