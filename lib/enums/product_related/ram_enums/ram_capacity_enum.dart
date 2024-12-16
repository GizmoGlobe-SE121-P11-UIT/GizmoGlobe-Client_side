enum RAMCapacity {
  gb8('8 GB'),
  gb16('16 GB'),
  gb32('32 GB'),
  gb64('64 GB'),
  gb128('128 GB');

  final String description;

  const RAMCapacity(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension RAMCapacityExtension on RAMCapacity {
  static RAMCapacity fromName(String name) {
    return RAMCapacity.values.firstWhere((e) => e.getName() == name);
  }
}