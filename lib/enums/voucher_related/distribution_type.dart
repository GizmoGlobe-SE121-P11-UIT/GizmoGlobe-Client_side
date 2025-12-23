enum DistributionType {
  public('Public'),
  rewards('Rewards'),
  staffIssued('Staff-Issued'),;

  final String description;

  const DistributionType(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension DistributionTypeExtension on DistributionType {
  static DistributionType fromName(String name) {
    return DistributionType.values.firstWhere((e) => e.getName() == name);
  }
}