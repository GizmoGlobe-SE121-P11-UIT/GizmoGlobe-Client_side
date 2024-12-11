enum MainboardSeries {
  h('H'),
  b('B'),
  z('Z'),
  x('X');

  final String description;

  const MainboardSeries(this.description);

  @override
  String toString() {
    return description;
  }
}