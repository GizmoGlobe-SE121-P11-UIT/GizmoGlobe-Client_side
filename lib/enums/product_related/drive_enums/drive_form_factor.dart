enum DriveFormFactor {
  unknown('Unknown'),
  m2_2280('M.2 2280'),
  m2_2230('M.2 2230'),
  m2_2242('M.2 2242'),
  inch3_5('3.5"'),
  inch2_5('2.5"');

  final String description;

  const DriveFormFactor(this.description);

  String getName() {
    return name;
  }

  static List<DriveFormFactor> getValues() {
    return DriveFormFactor.values.where((e) => e != DriveFormFactor.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension DriveFormFactorExtension on DriveFormFactor {
  static DriveFormFactor fromName(String name) {
    return DriveFormFactor.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => DriveFormFactor.unknown
    );
  }
}