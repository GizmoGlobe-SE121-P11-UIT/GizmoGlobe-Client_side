enum GPUBus {
  bit128('128-bit'),
  bit256('256-bit'),
  bit384('384-bit'),
  bit512('512-bit');

  final String description;

  const GPUBus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension GPUBusExtension on GPUBus {
  static GPUBus fromName(String name) {
    return GPUBus.values.firstWhere((e) => e.getName() == name);
  }
}