enum VoucherDisplayType {
  everyone('Everyone'),
  redeemable('Redeemable'),
  adminOnly('Admin Only'),;

  final String description;

  const VoucherDisplayType(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension VoucherDisplayTypeExtension on VoucherDisplayType {
  static VoucherDisplayType fromName(String name) {
    return VoucherDisplayType.values.firstWhere((e) => e.getName() == name);
  }
}