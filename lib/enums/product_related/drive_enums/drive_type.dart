enum DriveType {
  hdd('HDD'),
  sataSSD('SATA SSD'),
  m2NGFF('M2 NGFF'),
  m2NVME('M2 NVME');

  final String description;

  const DriveType(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension DriveTypeExtension on DriveType {
  static DriveType fromName(String name) {
    return DriveType.values.firstWhere((e) => e.getName() == name);
  }
}