enum RAMType {
  ddr3('DDR3'),
  ddr4('DDR4'),
  ddr5('DDR5');

  final String description;

  const RAMType(this.description);

  @override
  String toString() {
    return description;
  }
}