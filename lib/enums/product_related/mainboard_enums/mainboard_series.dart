enum MainboardSeries {
  h('H'),
  b('B'),
  z('Z'),
  x('X');

  final String description;

  const MainboardSeries(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension MainboardSeriesExtension on MainboardSeries {
  static MainboardSeries fromName(String name) {
    return MainboardSeries.values.firstWhere((e) => e.getName() == name);
  }
}