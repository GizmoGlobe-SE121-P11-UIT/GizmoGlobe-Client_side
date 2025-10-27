enum MainboardFormFactor {
  unknown('Unknown'),
  atx('ATX'),
  microATX('Micro-ATX'),
  miniITX('Mini-ITX');

  final String description;

  const MainboardFormFactor(this.description);

  String getName() {
    return name;
  }

  static List<MainboardFormFactor> getValues() {
    return MainboardFormFactor.values.where((e) => e != MainboardFormFactor.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension MainboardFormFactorExtension on MainboardFormFactor {
  static MainboardFormFactor fromName(String name) {
    return MainboardFormFactor.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => MainboardFormFactor.unknown,
    );
  }
}