enum VoucherTimeStatus {
  upcoming('Upcoming'),
  ongoing('Ongoing'),
  expired('Expired'),;

  final String description;

  const VoucherTimeStatus(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension VoucherStatusExtension on VoucherTimeStatus {
  static VoucherTimeStatus fromName(String name) {
    return VoucherTimeStatus.values.firstWhere((e) => e.getName() == name);
  }
}