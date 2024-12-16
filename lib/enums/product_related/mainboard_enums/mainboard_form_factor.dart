enum MainboardFormFactor {
  atx('ATX'),
  microATX('Micro-ATX'),
  miniITX('Mini-ITX');

  final String description;

  const MainboardFormFactor(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension MainboardFormFactorExtension on MainboardFormFactor {
  static MainboardFormFactor fromName(String name) {
    return MainboardFormFactor.values.firstWhere((e) => e.getName() == name);
  }
}