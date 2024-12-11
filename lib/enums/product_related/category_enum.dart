enum Category {
  ram('RAM'),
  cpu('CPU'),
  psu('PSU'),
  gpu('GPU'),
  drive('Drive'),
  mainboard('Mainboard');

  final String description;

  const Category(this.description);

  @override
  String toString() {
    return description;
  }
}