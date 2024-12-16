enum RAMBus {
  mhz1600('1600 MHz'),
  mhz2133('2133 MHz'),
  mhz2400('2400 MHz'),
  mhz3200('3200 MHz'),
  mhz4800('4800 MHz');

  final String description;

  const RAMBus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension RAMBusExtension on RAMBus {
  static RAMBus fromName(String name) {
    return RAMBus.values.firstWhere((e) => e.getName() == name);
  }
}