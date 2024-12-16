enum GPUCapacity {
  gb4('4 GB'),
  gb6('6 GB'),
  gb8('8 GB'),
  gb12('12 GB'),
  gb16('16 GB'),
  gb24('24 GB');

  final String description;

  const GPUCapacity(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension GPUCapacityExtension on GPUCapacity {
  static GPUCapacity fromName(String name) {
    return GPUCapacity.values.firstWhere((e) => e.getName() == name);
  }
}