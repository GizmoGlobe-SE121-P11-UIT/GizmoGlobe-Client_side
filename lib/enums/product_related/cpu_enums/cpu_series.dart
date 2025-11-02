enum CPUSeries {
  unknown('Unknown'),
  corei3Ultra3('Core i3 - Ultra 3'),
  corei5Ultra5('Core i5 - Ultra 5'),
  corei7Ultra7('Core i7 - Ultra 7'),
  xeon('Xeon'),
  ryzen3('Ryzen 3'),
  ryzen5('Ryzen 5'),
  ryzen7('Ryzen 7'),
  threadripper('Threadripper');

  final String description;

  const CPUSeries(this.description);

  String getName() {
    return name;
  }

  static List<CPUSeries> getValues() {
    return CPUSeries.values.where((e) => e != CPUSeries.unknown).toList();;
  }

  @override
  String toString() {
    return description;
  }
}

extension CPUSeriesExtension on CPUSeries {
  static CPUSeries fromName(String name) {
    return CPUSeries.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => CPUSeries.unknown,
    );
  }
}