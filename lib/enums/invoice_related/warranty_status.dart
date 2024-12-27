enum WarrantyStatus {
  pending("Pending"),
  processing("Processing"),
  completed("Completed"),
  denied("Denied");

  final String description;

  const WarrantyStatus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension WarrantyStatusExtension on WarrantyStatus {
  static WarrantyStatus fromName(String name) {
    return WarrantyStatus.values.firstWhere((e) => e.getName() == name);
  }
}