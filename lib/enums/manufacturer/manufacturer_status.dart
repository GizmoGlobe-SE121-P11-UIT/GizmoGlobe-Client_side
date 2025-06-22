enum ManufacturerStatus {
  active,
  inactive;

  String getName() {
    switch (this) {
      case ManufacturerStatus.active:
        return 'Active'; // Hoạt động
      case ManufacturerStatus.inactive:
        return 'Inactive'; // Không hoạt động
    }
  }
} 