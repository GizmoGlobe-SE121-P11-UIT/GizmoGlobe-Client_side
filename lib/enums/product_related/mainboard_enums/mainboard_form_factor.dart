enum MainboardFormFactor {
  atx('ATX'),
  microATX('Micro-ATX'),
  miniITX('Mini-ITX');

  final String description;

  const MainboardFormFactor(this.description);

  @override
  String toString() {
    return description;
  }
}