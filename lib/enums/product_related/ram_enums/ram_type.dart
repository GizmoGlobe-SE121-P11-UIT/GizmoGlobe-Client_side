enum RAMType {
  unknown('Unknown'),
  ddr3('DDR3'),
  ddr4('DDR4'),
  ddr5('DDR5');

  final String description;

  const RAMType(this.description);

  String getName() {
    return name;
  }

  static List<RAMType> getValues() {
    return RAMType.values.where((e) => e != RAMType.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension RAMTypeExtension on RAMType {
  static RAMType fromName(String name) {
    return RAMType.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => RAMType.unknown,
    );
  }
}