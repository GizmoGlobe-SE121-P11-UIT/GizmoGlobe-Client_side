enum MainboardCompatibility {
  amd('AMD'),
  intel('Intel');

  final String description;

  const MainboardCompatibility(this.description);

  @override
  String toString() {
    return description;
  }
}