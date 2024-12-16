enum CPUFamily {
  corei3Ultra3('Core i3 - Ultra 3'),
  corei5Ultra5('Core i5 - Ultra 5'),
  corei7Ultra7('Core i7 - Ultra 7'),
  xeon('Xeon'),
  ryzen3('Ryzen 3'),
  ryzen5('Ryzen 5'),
  ryzen7('Ryzen 7'),
  threadripper('Threadripper');

  final String description;

  const CPUFamily(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension CPUFamilyExtension on CPUFamily {
  static CPUFamily fromName(String name) {
    return CPUFamily.values.firstWhere((e) => e.getName() == name);
  }
}