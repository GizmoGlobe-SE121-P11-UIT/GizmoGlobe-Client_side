enum SalesStatus {
  pending('Pending'),
  preparing('Preparing'),
  shipping('Shipping'),
  shipped('Shipped'),
  completed('Completed'),
  cancelled('Cancelled');

  final String description;

  const SalesStatus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension SalesStatusExtension on SalesStatus {
  static SalesStatus fromName(String name) {
    return SalesStatus.values.firstWhere((e) => e.getName() == name);
  }
}