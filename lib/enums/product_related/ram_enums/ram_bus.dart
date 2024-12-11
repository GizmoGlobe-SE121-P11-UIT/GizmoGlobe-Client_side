enum RAMBus {
  mhz1600('1600 MHz'),
  mhz2133('2133 MHz'),
  mhz2400('2400 MHz'),
  mhz3200('3200 MHz'),
  mhz4800('4800 MHz');

  final String description;

  const RAMBus(this.description);

  @override
  String toString() {
    return description;
  }
}