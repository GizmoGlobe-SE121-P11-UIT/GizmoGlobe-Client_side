enum RAMType {
  ddr3('DDR3'),
  ddr4('DDR4'),
  ddr5('DDR5');

  final String description;

  const RAMType(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension RAMTypeExtension on RAMType {
  static RAMType fromName(String name) {
    return RAMType.values.firstWhere((e) => e.getName() == name);
  }
}