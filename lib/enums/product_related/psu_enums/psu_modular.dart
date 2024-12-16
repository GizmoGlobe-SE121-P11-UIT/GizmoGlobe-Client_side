enum PSUModular {
  nonModular('Non-Modular'),
  semiModular('Semi-Modular'),
  fullModular('Full-Modular');

  final String description;

  const PSUModular(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension PSUModularExtension on PSUModular {
  static PSUModular fromName(String name) {
    return PSUModular.values.firstWhere((e) => e.getName() == name);
  }
}