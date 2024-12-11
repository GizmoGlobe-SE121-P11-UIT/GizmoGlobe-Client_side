enum GPUCapacity {
  gb4('4 GB'),
  gb6('6 GB'),
  gb8('8 GB'),
  gb12('12 GB'),
  gb16('16 GB'),
  gb24('24 GB');

  final String description;

  const GPUCapacity(this.description);

  @override
  String toString() {
    return description;
  }
}