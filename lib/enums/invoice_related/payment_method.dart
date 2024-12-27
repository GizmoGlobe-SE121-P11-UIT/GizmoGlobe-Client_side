enum PaymentMethodEnum {
  online('Online Bank Transfer'),
  cod('Cash on Delivery'),;

  final String description;

  const PaymentMethodEnum(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension PaymentMethodExtension on PaymentMethodEnum {
  static PaymentMethodEnum fromName(String name) {
    return PaymentMethodEnum.values.firstWhere((e) => e.getName() == name);
  }
}