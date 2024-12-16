enum CategoryEnum {
  ram('RAM'),
  cpu('CPU'),
  psu('PSU'),
  gpu('GPU'),
  drive('Drive'),
  mainboard('Mainboard');

  final String description;

  const CategoryEnum(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension CategoryEnumExtension on CategoryEnum {
  static CategoryEnum fromName(String name) {
    return CategoryEnum.values.firstWhere((e) => e.getName() == name);
  }
}