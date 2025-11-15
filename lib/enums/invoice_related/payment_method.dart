enum PaymentMethod {
  cod('COD', 'Cash on Delivery', 'Thanh toán khi nhận hàng'),
  sepay('SePay', 'SePay', 'SePay'),
  stripe('Stripe', 'Stripe', 'Stripe');

  final String code;
  final String enDescription;
  final String viDescription;

  const PaymentMethod(this.code, this.enDescription, this.viDescription);

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

extension PaymentMethodExtension on PaymentMethod {
  static PaymentMethod fromName(String name) {
    return PaymentMethod.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => PaymentMethod.stripe,
    );
  }
}
