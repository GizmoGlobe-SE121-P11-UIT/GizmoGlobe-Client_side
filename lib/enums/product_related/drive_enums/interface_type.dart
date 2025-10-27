enum InterfaceType {
  unknown('Unknown'),
  sata('SATA'),
  pcie('PCIe');

  final String description;

  const InterfaceType(this.description);

  String getName() {
    return name;
  }

  static List<InterfaceType> getValues() {
    return InterfaceType.values.where((e) => e != InterfaceType.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension InterfaceTypeExtension on InterfaceType {
  static InterfaceType fromName(String name) {
    return InterfaceType.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => InterfaceType.unknown,
    );
  }
}
