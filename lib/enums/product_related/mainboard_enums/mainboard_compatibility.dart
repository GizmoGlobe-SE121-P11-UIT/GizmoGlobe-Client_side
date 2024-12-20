enum MainboardCompatibility {
  amd('AMD'),
  intel('Intel');

  final String description;

  const MainboardCompatibility(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension MainboardCompatibilityExtension on MainboardCompatibility {
  static MainboardCompatibility fromName(String name) {
    return MainboardCompatibility.values.firstWhere((e) => e.getName() == name);
  }
}