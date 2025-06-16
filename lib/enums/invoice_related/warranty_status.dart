enum WarrantyStatus {
  pending("Pending", "Chờ xử lý"),
  processing("Processing", "Đang xử lý"),
  completed("Completed", "Hoàn thành"),
  denied("Denied", "Từ chối");

  final String enDescription;
  final String viDescription;

  const WarrantyStatus(this.enDescription, this.viDescription);

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

extension WarrantyStatusExtension on WarrantyStatus {
  static WarrantyStatus fromName(String name) {
    return WarrantyStatus.values.firstWhere((e) => e.getName() == name);
  }
}
