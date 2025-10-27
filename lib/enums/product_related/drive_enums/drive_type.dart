enum DriveType {
  unknown('Unknown'),
  hdd('HDD'),
  sataSSD('SATA SSD'),
  m2NGFF('M2 NGFF'),
  m2NVME('M2 NVME');

  final String description;

  const DriveType(this.description);

  String getName() {
    return name;
  }

  static List<DriveType> getValues() {
    return DriveType.values.where((e) => e != DriveType.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }

  factory DriveType.fromJson(Map<String, dynamic> json) {
    String name = json['driveType'] ?? 'Unknown';
    return DriveTypeExtension.fromName(name);
  }
}

extension DriveTypeExtension on DriveType {
  static DriveType fromName(String name) {
    return DriveType.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => DriveType.unknown
    );
  }
}