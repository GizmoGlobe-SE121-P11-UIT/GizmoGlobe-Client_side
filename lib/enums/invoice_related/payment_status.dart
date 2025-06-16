enum PaymentStatus {
  paid('Paid', 'Đã thanh toán'),
  unpaid('Unpaid', 'Chưa thanh toán');

  final String enDescription;
  final String viDescription;

  const PaymentStatus(this.enDescription, this.viDescription);

  String getName() {
    return name;
  }

  String getLocalizedDescription(bool isVietnamese) {
    return isVietnamese ? viDescription : enDescription;
  }

  @override
  String toString() {
    return enDescription;
  }
}

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromName(String name) {
    return PaymentStatus.values.firstWhere((e) => e.getName() == name);
  }
}
