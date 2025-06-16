enum SalesStatus {
  pending('Pending', 'Chờ xử lý'),
  preparing('Preparing', 'Đang chuẩn bị'),
  shipping('Shipping', 'Đang giao hàng'),
  shipped('Shipped', 'Đã giao hàng'),
  completed('Completed', 'Hoàn thành'),
  cancelled('Cancelled', 'Đã hủy');

  final String enDescription;
  final String viDescription;

  const SalesStatus(this.enDescription, this.viDescription);

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

extension SalesStatusExtension on SalesStatus {
  static SalesStatus fromName(String name) {
    return SalesStatus.values.firstWhere((e) => e.getName() == name);
  }
}
