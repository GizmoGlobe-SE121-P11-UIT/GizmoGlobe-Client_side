enum PSUModular {
  unknown('Unknown'),
  nonModular('Non-Modular'),
  semiModular('Semi-Modular'),
  fullModular('Full-Modular');

  final String description;

  const PSUModular(this.description);

  String getName() {
    return name;
  }

  static List<PSUModular> getValues() {
    return PSUModular.values.where((e) => e != PSUModular.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension PSUModularExtension on PSUModular {
  static PSUModular fromName(String name) {
    return PSUModular.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => PSUModular.unknown,
    );
  }
}