enum GPUBus {
  bit128('128-bit'),
  bit256('256-bit'),
  bit384('384-bit'),
  bit512('512-bit');

  final String description;

  const GPUBus(this.description);

  @override
  String toString() {
    return description;
  }
}