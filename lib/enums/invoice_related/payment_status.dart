enum PaymentStatus {
  paid('Paid'),
  unpaid('Unpaid');

  final String description;

  const PaymentStatus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromName(String name) {
    return PaymentStatus.values.firstWhere((e) => e.getName() == name);
  }
}